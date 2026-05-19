# Autonomous Driving - Advanced Topics

## End-to-End Learning: UniAD

UniAD (Hu et al., 2023) is a unified end-to-end autonomous driving framework that performs perception, prediction, and planning jointly with a single model.

### Architecture Overview

```
Multi-Camera Images → BEV Encoder → Query-Based Components → Planning
                           ↓
                    ┌──────┴──────┬──────────┬──────────┐
                    │             │          │          │
              Track Queries  Map Queries  Motion  Occupancy
                    │             │       Queries   Queries
                    ↓             ↓          ↓          ↓
              Tracking      HD Mapping  Prediction  Occupancy
                    └─────────┬──────────┴──────────┘
                              ↓
                        Planning Queries
                              ↓
                        Ego Trajectory
```

### BEV Feature Encoder

```python
import torch
import torch.nn as nn

class BEVEncoder(nn.Module):
    def __init__(self, img_backbone='resnet50', bev_h=200, bev_w=200):
        super().__init__()
        self.img_backbone = ResNet50(pretrained=True)
        self.bev_h, self.bev_w = bev_h, bev_w

        # Learned depth distribution
        self.depth_net = nn.Sequential(
            nn.Conv2d(2048, 256, 1),
            nn.ReLU(),
            nn.Conv2d(256, 64, 1)  # 64 depth bins
        )

        # BEV pooling
        self.bev_pool = BEVPooling(grid_size=(bev_h, bev_w))

    def forward(self, images, intrinsics, extrinsics):
        """
        images: [B, N_cam, C, H, W]
        intrinsics: [B, N_cam, 3, 3]
        extrinsics: [B, N_cam, 4, 4]
        Returns: BEV features [B, C_bev, H_bev, W_bev]
        """
        B, N, C, H, W = images.shape

        # Extract image features
        img_feats = []
        for i in range(N):
            feat = self.img_backbone(images[:, i])  # [B, 2048, H', W']
            img_feats.append(feat)
        img_feats = torch.stack(img_feats, dim=1)  # [B, N, 2048, H', W']

        # Predict depth
        depth = []
        for i in range(N):
            d = self.depth_net(img_feats[:, i])  # [B, 64, H', W']
            d = torch.softmax(d, dim=1)  # Depth distribution
            depth.append(d)
        depth = torch.stack(depth, dim=1)  # [B, N, 64, H', W']

        # Lift to 3D and project to BEV
        bev_feats = self.bev_pool(img_feats, depth, intrinsics, extrinsics)

        return bev_feats
```

### Query-Based Tracking

```python
class TrackingModule(nn.Module):
    def __init__(self, num_queries=300, hidden_dim=256):
        super().__init__()
        self.num_queries = num_queries

        # Learnable track queries
        self.query_embed = nn.Embedding(num_queries, hidden_dim)

        # Transformer decoder
        self.decoder = TransformerDecoder(
            num_layers=6,
            hidden_dim=hidden_dim,
            num_heads=8
        )

        # Detection head
        self.class_head = nn.Linear(hidden_dim, 10)  # 10 classes
        self.bbox_head = nn.Linear(hidden_dim, 7)    # [x, y, z, w, h, l, yaw]
        self.track_id_head = nn.Linear(hidden_dim, 256)  # Embedding for tracking

    def forward(self, bev_features, prev_track_queries=None):
        """
        bev_features: [B, C, H, W]
        prev_track_queries: [B, N, C] (from previous frame for temporal consistency)
        Returns: Detected objects with track IDs
        """
        B = bev_features.shape[0]

        # Initialize queries
        if prev_track_queries is not None:
            # Use previous queries for temporal consistency
            queries = prev_track_queries
        else:
            # Use learned queries for first frame
            queries = self.query_embed.weight.unsqueeze(0).repeat(B, 1, 1)

        # Decode queries with cross-attention to BEV features
        decoded = self.decoder(queries, bev_features)  # [B, N, C]

        # Predict detections
        classes = self.class_head(decoded)  # [B, N, 10]
        bboxes = self.bbox_head(decoded)    # [B, N, 7]
        track_embeddings = self.track_id_head(decoded)  # [B, N, 256]

        # Track association using embedding similarity
        if prev_track_queries is not None:
            prev_embeddings = self.track_id_head(prev_track_queries)
            track_ids = self.associate_tracks(track_embeddings, prev_embeddings)
        else:
            track_ids = torch.arange(self.num_queries).unsqueeze(0).repeat(B, 1)

        return {
            'classes': classes,
            'bboxes': bboxes,
            'track_ids': track_ids,
            'queries': decoded  # Pass to next frame
        }

    def associate_tracks(self, curr_emb, prev_emb):
        """Associate current detections to previous tracks via embedding similarity"""
        # Cosine similarity
        curr_norm = curr_emb / curr_emb.norm(dim=-1, keepdim=True)
        prev_norm = prev_emb / prev_emb.norm(dim=-1, keepdim=True)

        similarity = curr_norm @ prev_norm.transpose(-2, -1)  # [B, N, N]

        # Hungarian matching
        track_ids = []
        for b in range(similarity.shape[0]):
            from scipy.optimize import linear_sum_assignment
            row_ind, col_ind = linear_sum_assignment(-similarity[b].cpu().numpy())
            track_ids.append(torch.tensor(col_ind))

        return torch.stack(track_ids)
```

### Motion Prediction with Learned Modes

```python
class MotionPredictionModule(nn.Module):
    def __init__(self, num_modes=6, future_steps=12):
        super().__init__()
        self.num_modes = num_modes
        self.future_steps = future_steps

        # Mode prediction
        self.mode_net = nn.Sequential(
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, num_modes)
        )

        # Trajectory prediction for each mode
        self.traj_net = nn.GRU(256, 256, num_layers=2)
        self.traj_head = nn.Linear(256, 2)  # (x, y) displacement

    def forward(self, track_features):
        """
        track_features: [B, N_objects, C]
        Returns: Multi-modal future trajectories
        """
        B, N, C = track_features.shape

        # Predict mode probabilities
        mode_probs = torch.softmax(self.mode_net(track_features), dim=-1)  # [B, N, num_modes]

        # Predict trajectory for each mode
        trajectories = []
        for mode in range(self.num_modes):
            # Use mode-specific initial hidden state
            h0 = track_features.permute(1, 0, 2)  # [N, B, C]

            traj = []
            for t in range(self.future_steps):
                output, h0 = self.traj_net(h0.unsqueeze(0), h0)
                displacement = self.traj_head(output.squeeze(0))  # [N, B, 2]
                traj.append(displacement)

            trajectories.append(torch.stack(traj, dim=2))  # [N, B, T, 2]

        trajectories = torch.stack(trajectories, dim=3)  # [N, B, T, num_modes, 2]
        trajectories = trajectories.permute(1, 0, 2, 3, 4)  # [B, N, T, num_modes, 2]

        return {
            'mode_probs': mode_probs,
            'trajectories': trajectories
        }
```

### Planning with Diffusion

Diffusion models generate diverse, multi-modal plans by iteratively denoising random noise.

```python
class DiffusionPlanner(nn.Module):
    def __init__(self, num_diffusion_steps=50, horizon=24):
        super().__init__()
        self.T = num_diffusion_steps
        self.horizon = horizon

        # Noise schedule
        self.betas = torch.linspace(1e-4, 0.02, num_diffusion_steps)
        self.alphas = 1 - self.betas
        self.alpha_bars = torch.cumprod(self.alphas, dim=0)

        # Denoising network (U-Net style)
        self.denoiser = UNet1D(
            in_channels=2,  # (x, y) trajectory
            out_channels=2,
            context_dim=512  # Conditioning on scene features
        )

    def forward(self, scene_features, num_samples=1):
        """
        scene_features: [B, C] - Encoded scene context
        Returns: Planned trajectory [B, num_samples, T, 2]
        """
        B = scene_features.shape[0]

        # Start from pure noise
        traj = torch.randn(B, num_samples, self.horizon, 2)

        # Iterative denoising
        for t in reversed(range(self.T)):
            # Predict noise
            t_tensor = torch.tensor([t]).repeat(B * num_samples)
            traj_flat = traj.reshape(B * num_samples, self.horizon, 2)
            scene_flat = scene_features.unsqueeze(1).repeat(1, num_samples, 1).reshape(B * num_samples, -1)

            noise_pred = self.denoiser(traj_flat, t_tensor, scene_flat)

            # Denoise step
            alpha = self.alphas[t]
            alpha_bar = self.alpha_bars[t]
            alpha_bar_prev = self.alpha_bars[t-1] if t > 0 else torch.tensor(1.0)

            # DDPM sampling
            traj_flat = (1 / alpha.sqrt()) * (
                traj_flat - ((1 - alpha) / (1 - alpha_bar).sqrt()) * noise_pred
            )

            if t > 0:
                noise = torch.randn_like(traj_flat)
                traj_flat = traj_flat + ((1 - alpha_bar_prev) / (1 - alpha_bar) * (1 - alpha)).sqrt() * noise

            traj = traj_flat.reshape(B, num_samples, self.horizon, 2)

        # Post-process to ensure physical constraints
        traj = self.enforce_kinematic_constraints(traj)

        return traj

    def enforce_kinematic_constraints(self, traj):
        """Ensure velocity and acceleration limits"""
        dt = 0.5  # seconds per step
        max_vel = 15.0  # m/s
        max_accel = 4.0  # m/s^2

        # Compute velocity
        vel = torch.diff(traj, dim=2) / dt
        vel_mag = vel.norm(dim=-1)

        # Clip velocity
        scale = torch.clamp(max_vel / vel_mag, max=1.0).unsqueeze(-1)
        vel_clipped = vel * scale

        # Recompute trajectory from clipped velocity
        traj_new = torch.cat([
            traj[:, :, :1],  # Keep first point
            traj[:, :, :1] + torch.cumsum(vel_clipped * dt, dim=2)
        ], dim=2)

        return traj_new
```

## World Models for Autonomous Driving

World models learn to predict future states of the environment, enabling simulation-based planning.

### MILE: Model-based Imitation Learning

```python
class WorldModel(nn.Module):
    def __init__(self, latent_dim=256):
        super().__init__()
        self.latent_dim = latent_dim

        # Image encoder (VAE)
        self.encoder = ImageEncoder(latent_dim=latent_dim)

        # Dynamics model (predicts next latent state)
        self.dynamics = nn.GRU(latent_dim + 3, latent_dim, num_layers=3)
        # +3 for action (steering, throttle, brake)

        # Image decoder
        self.decoder = ImageDecoder(latent_dim=latent_dim)

        # Reward predictor
        self.reward_head = nn.Linear(latent_dim, 1)

    def forward(self, images, actions):
        """
        images: [B, T, C, H, W]
        actions: [B, T, 3]
        Returns: Predicted next images and rewards
        """
        B, T = images.shape[:2]

        # Encode images to latent states
        latents = []
        for t in range(T):
            z, _, _ = self.encoder(images[:, t])
            latents.append(z)
        latents = torch.stack(latents, dim=1)  # [B, T, latent_dim]

        # Predict future latents with dynamics model
        latents_actions = torch.cat([latents, actions], dim=-1)
        latents_pred, _ = self.dynamics(latents_actions.transpose(0, 1))
        latents_pred = latents_pred.transpose(0, 1)

        # Decode to images
        images_pred = []
        for t in range(T):
            img = self.decoder(latents_pred[:, t])
            images_pred.append(img)
        images_pred = torch.stack(images_pred, dim=1)

        # Predict rewards
        rewards = self.reward_head(latents_pred).squeeze(-1)

        return images_pred, rewards

    def plan_with_model(self, current_image, horizon=10, num_samples=100):
        """Model-predictive control using learned world model"""
        z, _, _ = self.encoder(current_image)

        best_action_sequence = None
        best_reward = -float('inf')

        # Sample action sequences
        for _ in range(num_samples):
            actions = torch.randn(1, horizon, 3) * 0.1  # Random actions

            # Rollout with world model
            z_t = z
            total_reward = 0
            for t in range(horizon):
                z_action = torch.cat([z_t, actions[:, t]], dim=-1)
                z_t, _ = self.dynamics(z_action.unsqueeze(0))
                z_t = z_t.squeeze(0)

                reward = self.reward_head(z_t)
                total_reward += reward * (0.99 ** t)  # Discount factor

            if total_reward > best_reward:
                best_reward = total_reward
                best_action_sequence = actions

        return best_action_sequence[:, 0]  # Return first action
```

## Foundation Models for Driving

### Vision-Language Models for Scene Understanding

```python
class DrivingVLM(nn.Module):
    def __init__(self):
        super().__init__()
        from transformers import CLIPModel, CLIPProcessor

        self.clip = CLIPModel.from_pretrained("openai/clip-vit-large-patch14")
        self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-large-patch14")

        # Adapter for driving-specific features
        self.adapter = nn.Sequential(
            nn.Linear(768, 512),
            nn.ReLU(),
            nn.Linear(512, 256)
        )

        # Control head
        self.control_head = nn.Sequential(
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, 3)  # [steering, throttle, brake]
        )

    def forward(self, image, text_prompt):
        """
        image: Front camera PIL image
        text_prompt: Natural language command
        """
        # Process inputs
        inputs = self.processor(
            text=[text_prompt],
            images=image,
            return_tensors="pt",
            padding=True
        )

        # Get CLIP features
        outputs = self.clip(**inputs)
        img_features = outputs.image_embeds
        text_features = outputs.text_embeds

        # Fuse modalities
        fused = img_features * text_features  # Element-wise product
        adapted = self.adapter(fused)

        # Predict controls
        controls = self.control_head(adapted)

        return controls  # [steering, throttle, brake]

# Example usage
vlm = DrivingVLM()
image = load_front_camera_image()
command = "Turn left at the next intersection"
controls = vlm(image, command)
```

### GPT-Driver: LLM for High-Level Planning

```python
class GPTDriver:
    def __init__(self, model_name='gpt-4'):
        import openai
        self.client = openai.OpenAI()
        self.model = model_name

    def get_maneuver(self, scene_description, goal):
        """
        scene_description: Natural language description of current scene
        goal: High-level navigation goal
        Returns: Structured maneuver command
        """
        prompt = f"""You are an expert autonomous driving planner.

Scene: {scene_description}
Goal: {goal}

Based on the scene, suggest the next maneuver. Respond in JSON format:
{{
  "maneuver": "lane_follow | lane_change_left | lane_change_right | turn_left | turn_right | stop",
  "target_speed_mph": <number>,
  "reasoning": "<brief explanation>"
}}
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )

        import json
        return json.loads(response.choices[0].message.content)

# Example
planner = GPTDriver()
scene = "Three-lane highway, moderate traffic. Right lane has slow truck. Goal lane is leftmost."
goal = "Navigate to exit in 2 miles on the left"

maneuver = planner.get_maneuver(scene, goal)
# Output: {"maneuver": "lane_change_left", "target_speed_mph": 65, "reasoning": "..."}
```

## Next Steps

- **Research**: Continuous learning from fleet data, sim-to-real transfer
- **Standards**: ISO 21448 (SOTIF), ISO 26262 (safety), ISO 21434 (security)
- **Tools**: CARLA, LGSVL, Waymax simulators for testing

## References

- Hu et al., "Planning-oriented Autonomous Driving", CVPR 2023 (UniAD)
- Hu et al., "Model-Based Imitation Learning for Urban Driving", NeurIPS 2022 (MILE)
- Chen et al., "End-to-End Urban Driving by Imitating a Reinforcement Learning Coach", ICCV 2021
- Radford et al., "Learning Transferable Visual Models From Natural Language Supervision", ICML 2021 (CLIP)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Research engineers, ML scientists, advanced AD developers
