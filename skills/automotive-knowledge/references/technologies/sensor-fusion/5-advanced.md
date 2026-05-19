# Sensor Fusion - Advanced Topics

## Deep Learning Fusion Architectures

Modern autonomous driving increasingly leverages deep neural networks that fuse sensor modalities at multiple stages of the perception pipeline. This section covers state-of-the-art architectures for learning-based sensor fusion.

### PointPainting: Sequential Fusion

PointPainting (Vora et al., 2020) augments LiDAR point clouds with semantic information from camera images.

**Architecture:**
```
Step 1: Camera Semantic Segmentation
Image → CNN → Semantic Segmentation Map

Step 2: Point Cloud Augmentation
For each LiDAR point (x, y, z):
  1. Project point to image: (u, v) = K * [R|t] * [x, y, z, 1]
  2. Lookup semantic class scores at (u, v)
  3. Append scores to point: (x, y, z, intensity, class1, class2, ..., classN)

Step 3: 3D Object Detection
Augmented Point Cloud → PointPillars/PointNet → 3D Bounding Boxes
```

**Implementation sketch:**
```python
import torch
import torch.nn as nn

class PointPainting(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.semantic_seg = DeepLabV3Plus(num_classes=num_classes)
        self.detector_3d = PointPillars(input_channels=4+num_classes)

    def forward(self, image, lidar_points, calibration):
        # Step 1: Semantic segmentation
        seg_map = self.semantic_seg(image)  # [B, C, H, W]

        # Step 2: Paint points with semantics
        painted_points = []
        for batch_idx in range(image.shape[0]):
            points = lidar_points[batch_idx]  # [N, 4] (x, y, z, intensity)
            K, T = calibration[batch_idx]

            # Project to image
            points_cam = (T @ torch.cat([points[:, :3], torch.ones(points.shape[0], 1)], dim=1).T).T
            points_img = (K @ points_cam[:, :3].T).T
            u = (points_img[:, 0] / points_img[:, 2]).long()
            v = (points_img[:, 1] / points_img[:, 2]).long()

            # Clip to image bounds
            valid = (u >= 0) & (u < image.shape[3]) & (v >= 0) & (v < image.shape[2])
            u, v = u[valid], v[valid]

            # Lookup semantic scores
            semantic_scores = seg_map[batch_idx, :, v, u].T  # [N_valid, C]

            # Augment points
            augmented = torch.cat([points[valid], semantic_scores], dim=1)
            painted_points.append(augmented)

        # Step 3: 3D detection on painted points
        detections = self.detector_3d(painted_points)
        return detections
```

**Key Insights:**
- Camera provides rich semantic context (car, pedestrian, cyclist)
- LiDAR provides precise 3D geometry
- Sequential fusion avoids joint training complexity
- Works with off-the-shelf 3D detectors

### BEVFusion: Unified BEV Representation

BEVFusion (Liu et al., 2022) fuses camera and LiDAR in a unified bird's-eye-view (BEV) representation.

**Architecture:**
```
Camera Branch:
Image → ResNet → BEV Pooling → BEV Features (camera)

LiDAR Branch:
Point Cloud → Voxelization → 3D Convolution → BEV Features (LiDAR)

Fusion:
BEV Features (camera) ⊕ BEV Features (LiDAR) → Fused BEV → Detection Head
```

**BEV Pooling (camera to BEV):**
```python
class BEVPooling(nn.Module):
    def __init__(self, grid_size=(200, 200), grid_range=(-50, 50, -50, 50)):
        super().__init__()
        self.grid_size = grid_size
        self.x_min, self.x_max, self.y_min, self.y_max = grid_range

    def forward(self, image_features, depth, calibration):
        """
        image_features: [B, C, H, W]
        depth: [B, D, H, W] (predicted depth bins)
        calibration: Camera intrinsics + extrinsics
        """
        B, C, H, W = image_features.shape
        D = depth.shape[1]

        # Create 3D frustum in camera frame
        u = torch.arange(W, device=image_features.device)
        v = torch.arange(H, device=image_features.device)
        d = torch.linspace(2.0, 60.0, D, device=image_features.device)

        uu, vv, dd = torch.meshgrid(u, v, d, indexing='ij')
        points_cam = torch.stack([
            (uu - calibration.cx) * dd / calibration.fx,
            (vv - calibration.cy) * dd / calibration.fy,
            dd
        ], dim=-1)  # [W, H, D, 3]

        # Transform to vehicle frame
        points_veh = (calibration.T_cam_to_veh @
                      torch.cat([points_cam, torch.ones(*points_cam.shape[:-1], 1)], dim=-1).T).T

        # Discretize to BEV grid
        x_grid = ((points_veh[..., 0] - self.x_min) /
                  (self.x_max - self.x_min) * self.grid_size[0]).long()
        y_grid = ((points_veh[..., 1] - self.y_min) /
                  (self.y_max - self.y_min) * self.grid_size[1]).long()

        # Pool features to BEV
        bev_features = torch.zeros(B, C, *self.grid_size, device=image_features.device)
        for b in range(B):
            for c in range(C):
                for w in range(W):
                    for h in range(H):
                        for d_idx in range(D):
                            x_idx = x_grid[w, h, d_idx]
                            y_idx = y_grid[w, h, d_idx]
                            if 0 <= x_idx < self.grid_size[0] and 0 <= y_idx < self.grid_size[1]:
                                weight = depth[b, d_idx, h, w]
                                bev_features[b, c, x_idx, y_idx] += (
                                    weight * image_features[b, c, h, w]
                                )

        return bev_features
```

**Fusion Strategy:**
```python
class BEVFusion(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.camera_encoder = ResNet50()
        self.lidar_encoder = VoxelNet()
        self.bev_pooling = BEVPooling()

        self.fusion_layer = nn.Conv2d(256+256, 256, kernel_size=1)
        self.detection_head = CenterHead(num_classes=num_classes)

    def forward(self, images, lidar_points, calibration):
        # Camera branch
        img_features = self.camera_encoder(images)
        depth = self.predict_depth(img_features)
        bev_cam = self.bev_pooling(img_features, depth, calibration)

        # LiDAR branch
        voxels = self.voxelize(lidar_points)
        bev_lidar = self.lidar_encoder(voxels)

        # Fusion
        bev_fused = torch.cat([bev_cam, bev_lidar], dim=1)
        bev_fused = self.fusion_layer(bev_fused)

        # Detection
        detections = self.detection_head(bev_fused)
        return detections
```

**Advantages:**
- Unified representation simplifies multi-task learning
- Camera and LiDAR contribute complementary information
- End-to-end trainable
- Scales to additional modalities (radar in BEV space)

### TransFusion: Transformer-Based Fusion

TransFusion (Bai et al., 2022) uses cross-attention to fuse image features with LiDAR queries.

**Architecture:**
```
LiDAR Branch:
Point Cloud → Sparse 3D CNN → BEV Features → Object Queries

Cross-Attention:
Object Queries attend to Image Features

Detection:
Fused Queries → Detection Head → Bounding Boxes
```

**Cross-Modal Attention:**
```python
class TransFusionLayer(nn.Module):
    def __init__(self, d_model=256, num_heads=8):
        super().__init__()
        self.cross_attention = nn.MultiheadAttention(d_model, num_heads)
        self.ffn = nn.Sequential(
            nn.Linear(d_model, d_model * 4),
            nn.ReLU(),
            nn.Linear(d_model * 4, d_model)
        )
        self.norm1 = nn.LayerNorm(d_model)
        self.norm2 = nn.LayerNorm(d_model)

    def forward(self, queries, image_features, query_pos, img_pos):
        """
        queries: [N_query, B, C] - Object proposals from LiDAR
        image_features: [N_img, B, C] - Image features from CNN
        query_pos: [N_query, B, C] - 3D position encodings
        img_pos: [N_img, B, C] - 2D position encodings
        """
        # Cross-attention: queries attend to image features
        queries2, attention_weights = self.cross_attention(
            query=queries + query_pos,
            key=image_features + img_pos,
            value=image_features
        )
        queries = queries + self.norm1(queries2)

        # FFN
        queries2 = self.ffn(queries)
        queries = queries + self.norm2(queries2)

        return queries, attention_weights
```

**Complete TransFusion:**
```python
class TransFusion(nn.Module):
    def __init__(self, num_classes=10, num_queries=200):
        super().__init__()
        self.lidar_backbone = SparseConvNet()
        self.image_backbone = ResNet50()
        self.query_init = nn.Embedding(num_queries, 256)

        self.fusion_layers = nn.ModuleList([
            TransFusionLayer() for _ in range(6)
        ])

        self.detection_head = nn.Linear(256, num_classes + 7)  # cls + box

    def forward(self, lidar_points, images, calibration):
        # LiDAR processing
        bev_features = self.lidar_backbone(lidar_points)
        queries = self.query_init.weight.unsqueeze(1).repeat(1, bev_features.shape[0], 1)

        # Image processing
        img_features = self.image_backbone(images).flatten(2).permute(2, 0, 1)

        # Position encodings
        query_pos = self.get_3d_position_encoding(queries)
        img_pos = self.get_2d_position_encoding(img_features)

        # Iterative refinement with cross-attention
        for layer in self.fusion_layers:
            queries, attn = layer(queries, img_features, query_pos, img_pos)

        # Detection
        outputs = self.detection_head(queries)
        return outputs
```

**Key Benefits:**
- Attention mechanism learns which image regions are relevant for each object
- Handles occlusion and sparse LiDAR gracefully
- State-of-the-art performance on nuScenes benchmark

## Uncertainty-Aware Fusion

Proper uncertainty quantification is critical for safety-critical applications.

### Evidential Deep Learning

Output uncertainty estimates along with predictions:

```python
class EvidentialFusion(nn.Module):
    def __init__(self):
        super().__init__()
        self.backbone = ResNet50()
        # Output evidence parameters for Dirichlet distribution
        self.head = nn.Linear(2048, 4 * num_classes)  # [alpha, beta, gamma, lambda]

    def forward(self, x):
        features = self.backbone(x)
        evidence = self.head(features).reshape(-1, num_classes, 4)

        # Dirichlet parameters
        alpha = evidence[:, :, 0].exp() + 1  # Ensure α > 1
        S = alpha.sum(dim=1, keepdim=True)

        # Predicted probability
        prob = alpha / S

        # Uncertainty (higher when evidence is low)
        uncertainty = num_classes / S

        return prob, uncertainty
```

### Monte Carlo Dropout

Estimate uncertainty by stochastic forward passes:

```python
def predict_with_uncertainty(model, x, num_samples=50):
    model.train()  # Enable dropout
    predictions = []

    with torch.no_grad():
        for _ in range(num_samples):
            pred = model(x)
            predictions.append(pred)

    predictions = torch.stack(predictions)
    mean_pred = predictions.mean(dim=0)
    uncertainty = predictions.std(dim=0)

    return mean_pred, uncertainty
```

## World Models for Sensor Fusion

World models predict future states, enabling proactive decision-making.

### Spatial-Temporal Transformer

```python
class SpatialTemporalTransformer(nn.Module):
    def __init__(self, input_dim=256, num_future_steps=5):
        super().__init__()
        self.spatial_encoder = SpatialAttention()
        self.temporal_encoder = TemporalAttention()
        self.future_decoder = nn.GRU(input_dim, input_dim, num_layers=3)
        self.num_future_steps = num_future_steps

    def forward(self, sensor_history):
        """
        sensor_history: [B, T_hist, N_objects, C]
        Returns: [B, T_future, N_objects, C]
        """
        B, T, N, C = sensor_history.shape

        # Spatial encoding (attend across objects at each time)
        spatial_features = []
        for t in range(T):
            feat = self.spatial_encoder(sensor_history[:, t])  # [B, N, C]
            spatial_features.append(feat)
        spatial_features = torch.stack(spatial_features, dim=1)  # [B, T, N, C]

        # Temporal encoding (attend across time for each object)
        temporal_features = []
        for n in range(N):
            feat = self.temporal_encoder(spatial_features[:, :, n])  # [B, T, C]
            temporal_features.append(feat)
        temporal_features = torch.stack(temporal_features, dim=2)  # [B, T, N, C]

        # Future prediction (autoregressive)
        last_state = temporal_features[:, -1]  # [B, N, C]
        hidden = self.init_hidden(B, N)

        future_predictions = []
        for _ in range(self.num_future_steps):
            output, hidden = self.future_decoder(last_state.reshape(B*N, 1, C), hidden)
            last_state = output.reshape(B, N, C)
            future_predictions.append(last_state)

        future_predictions = torch.stack(future_predictions, dim=1)  # [B, T_future, N, C]
        return future_predictions
```

## Neural Radiance Fields (NeRF) for Sensor Simulation

NeRF enables photorealistic rendering of sensor data for simulation and testing.

### Driving Scene NeRF

```python
class DrivingNeRF(nn.Module):
    def __init__(self):
        super().__init__()
        # Encode 3D position + viewing direction
        self.pos_encoder = PositionalEncoding(input_dim=3, L=10)
        self.dir_encoder = PositionalEncoding(input_dim=3, L=4)

        # MLP for density and color
        self.density_net = nn.Sequential(
            nn.Linear(60, 256), nn.ReLU(),
            nn.Linear(256, 256), nn.ReLU(),
            nn.Linear(256, 1)  # Density σ
        )

        self.color_net = nn.Sequential(
            nn.Linear(256 + 24, 128), nn.ReLU(),
            nn.Linear(128, 3)  # RGB
        )

    def forward(self, points, view_dirs):
        """
        points: [N_rays, N_samples, 3]
        view_dirs: [N_rays, 3]
        """
        # Encode positions
        pos_encoded = self.pos_encoder(points)  # [N_rays, N_samples, 60]

        # Predict density
        density = self.density_net(pos_encoded).squeeze(-1)  # [N_rays, N_samples]

        # Encode view directions
        dir_encoded = self.dir_encoder(view_dirs)  # [N_rays, 24]
        dir_encoded = dir_encoded.unsqueeze(1).expand(-1, points.shape[1], -1)

        # Predict color (conditioned on density features + view)
        color = self.color_net(torch.cat([pos_encoded, dir_encoded], dim=-1))  # [N_rays, N_samples, 3]

        return density, color
```

**Volume Rendering:**
```python
def volume_render(density, color, z_vals):
    """
    density: [N_rays, N_samples]
    color: [N_rays, N_samples, 3]
    z_vals: [N_rays, N_samples] - Depths along rays
    """
    # Compute alpha (opacity)
    dists = z_vals[:, 1:] - z_vals[:, :-1]
    dists = torch.cat([dists, 1e10 * torch.ones_like(dists[:, :1])], dim=1)
    alpha = 1.0 - torch.exp(-density * dists)

    # Compute transmittance
    transmittance = torch.cumprod(
        torch.cat([torch.ones_like(alpha[:, :1]), 1.0 - alpha + 1e-10], dim=1),
        dim=1
    )[:, :-1]

    # Weighted color
    weights = alpha * transmittance
    rgb = (weights.unsqueeze(-1) * color).sum(dim=1)  # [N_rays, 3]

    return rgb
```

## Foundation Models for Driving

Large-scale pre-trained models adapted to driving scenarios.

### Vision-Language Models (VLM) for Scene Understanding

```python
class DrivingVLM(nn.Module):
    def __init__(self, pretrained_clip='openai/clip-vit-base-patch32'):
        super().__init__()
        self.clip = CLIPModel.from_pretrained(pretrained_clip)
        self.adapter = nn.Linear(512, 256)
        self.decision_head = nn.Sequential(
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, 3)  # [throttle, brake, steering]
        )

    def forward(self, image, text_prompt):
        """
        image: Front camera view
        text_prompt: "Navigate to the left lane" or "Stop at red light"
        """
        # CLIP encoding
        img_features = self.clip.get_image_features(image)
        text_features = self.clip.get_text_features(text_prompt)

        # Fuse image and language
        fused = img_features * text_features  # Hadamard product
        adapted = self.adapter(fused)

        # Control prediction
        controls = self.decision_head(adapted)
        return controls
```

## Next Steps

- **Related**: End-to-end autonomous driving (UniAD, MILE)
- **Standards**: ISO 23150 sensor data interfaces
- **Research**: Embodied AI, continuous learning from fleet data

## References

- Vora et al., "PointPainting: Sequential Fusion for 3D Object Detection", CVPR 2020
- Liu et al., "BEVFusion: Multi-Task Multi-Sensor Fusion with Unified Bird's-Eye View Representation", ICRA 2022
- Bai et al., "TransFusion: Robust LiDAR-Camera Fusion for 3D Object Detection with Transformers", CVPR 2022
- Mildenhall et al., "NeRF: Representing Scenes as Neural Radiance Fields for View Synthesis", ECCV 2020

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Research engineers, ML scientists, advanced perception developers
