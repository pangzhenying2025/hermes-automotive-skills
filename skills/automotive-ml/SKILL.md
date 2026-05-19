---
name: automotive-ml
description: >
  Automotive Ml expertise. Covers 6 topics: Anomaly Detection, Driver Behavior Analysis, Energy Optimization, Fleet Analytics, Predictive Maintenance.
tags: [automotive, automotive-ml]
---

# Automotive Ml

## Anomaly Detection

# Anomaly Detection for Automotive Systems

Detect unusual vehicle behavior across battery systems, sensors, and drivetrain components using unsupervised ML techniques.

## Use Cases

1. **Battery Anomalies**: Cell voltage drift, thermal runaway precursors, SOC inconsistencies
2. **Sensor Failures**: LiDAR/radar malfunction, camera degradation, IMU drift
3. **Drivetrain Issues**: Motor vibration anomalies, inverter faults, cooling system failures
4. **Charging Anomalies**: Abnormal charging curves, connector issues, grid irregularities

## Algorithm Selection

### Isolation Forest
**Best for**: High-dimensional sensor data with mixed feature types

**Pros**:
- Handles non-Gaussian distributions
- Efficient for large datasets
- No assumptions about normal behavior shape
- Low memory footprint

**Cons**:
- Sensitive to feature scaling
- May struggle with local anomalies

**Use cases**: Real-time battery monitoring, sensor fault detection

### Autoencoder (Deep Learning)
**Best for**: Complex time-series patterns, image-based anomalies

**Pros**:
- Learns compressed representation
- Excellent for time-series sequences
- Handles multi-modal data
- Can detect subtle pattern deviations

**Cons**:
- Requires significant training data
- Computationally expensive
- Black-box interpretation

**Use cases**: Camera degradation, LiDAR point cloud anomalies, battery degradation patterns

### Local Outlier Factor (LOF)
**Best for**: Local density-based anomalies

**Pros**:
- Detects local outliers in varying density regions
- No global threshold needed
- Good for spatial data

**Cons**:
- Computationally intensive for large datasets
- Requires careful k-neighbor selection

**Use cases**: Geographic anomalies (GPS data), fleet-wide comparison

### One-Class SVM
**Best for**: Small, well-defined normal behavior regions

**Pros**:
- Kernel trick for non-linear boundaries
- Robust to outliers in training set
- Theoretical foundation

**Cons**:
- Difficult hyperparameter tuning
- Slow on large datasets
- Memory intensive

**Use cases**: Safety-critical systems with narrow normal operating ranges

## Feature Engineering

### Battery Systems
```python
features = [
    # Static features
    'cell_voltage_mean', 'cell_voltage_std', 'cell_voltage_range',
    'temperature_mean', 'temperature_std', 'temperature_max',
    'soc_value', 'soh_estimate', 'current_value',

    # Derived features
    'voltage_imbalance_ratio',  # max_voltage / min_voltage
    'thermal_gradient',          # max_temp - min_temp
    'charge_acceptance',         # dSOC / dTime at constant current

    # Time-series features (sliding window)
    'voltage_trend_5min',        # Linear regression slope
    'temperature_volatility',    # Rolling std deviation
    'current_spike_count',       # Threshold crossings

    # Cross-domain features
    'power_efficiency',          # Output power / Input power
    'thermal_power_ratio'        # Temperature rise / Power delivered
]
```

### Sensor Systems
```python
features = [
    # LiDAR
    'point_cloud_density', 'max_range', 'noise_level',
    'ground_plane_fit_error', 'object_count',

    # Camera
    'brightness_mean', 'contrast_std', 'edge_density',
    'motion_blur_score', 'lens_distortion_coefficient',

    # IMU
    'accel_magnitude_mean', 'gyro_drift_rate',
    'vibration_frequency_peak', 'calibration_offset',

    # GPS
    'hdop', 'satellite_count', 'position_jump_distance',
    'velocity_consistency_score'
]
```

## Implementation Example: Isolation Forest for Battery

```python
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
import joblib
from typing import Dict, List, Tuple
import logging

logger = logging.getLogger(__name__)

class BatteryAnomalyDetector:
    """
    Isolation Forest-based anomaly detection for battery systems.

    Detects:
    - Cell voltage imbalances
    - Thermal anomalies
    - Charge/discharge irregularities
    - SOH degradation patterns
    """

    def __init__(
        self,
        contamination: float = 0.01,
        n_estimators: int = 100,
        max_samples: int = 256,
        random_state: int = 42
    ):
        """
        Args:
            contamination: Expected proportion of outliers (0.01 = 1%)
            n_estimators: Number of isolation trees
            max_samples: Samples per tree (higher = more global detection)
            random_state: Reproducibility seed
        """
        self.pipeline = Pipeline([
            ('scaler', StandardScaler()),
            ('detector', IsolationForest(
                contamination=contamination,
                n_estimators=n_estimators,
                max_samples=max_samples,
                random_state=random_state,
                n_jobs=-1
            ))
        ])
        self.feature_names = None
        self.trained = False

    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Create derived features from raw battery telemetry.

        Expected columns:
        - cell_voltages: list of voltages [V]
        - cell_temperatures: list of temps [C]
        - soc: State of charge [0-100]
        - soh: State of health [0-100]
        - current: Pack current [A]
        - timestamp: datetime
        """
        features = pd.DataFrame()

        # Voltage statistics
        voltages = np.array(df['cell_voltages'].tolist())
        features['voltage_mean'] = voltages.mean(axis=1)
        features['voltage_std'] = voltages.std(axis=1)
        features['voltage_min'] = voltages.min(axis=1)
        features['voltage_max'] = voltages.max(axis=1)
        features['voltage_range'] = features['voltage_max'] - features['voltage_min']
        features['voltage_imbalance'] = features['voltage_max'] / (features['voltage_min'] + 1e-6)

        # Temperature statistics
        temps = np.array(df['cell_temperatures'].tolist())
        features['temp_mean'] = temps.mean(axis=1)
        features['temp_std'] = temps.std(axis=1)
        features['temp_max'] = temps.max(axis=1)
        features['thermal_gradient'] = temps.max(axis=1) - temps.min(axis=1)

        # State features
        features['soc'] = df['soc']
        features['soh'] = df['soh']
        features['current'] = df['current']
        features['power'] = df['current'] * features['voltage_mean']

        # Time-series features (requires sorted by timestamp)
        df_sorted = df.sort_values('timestamp')
        features['voltage_trend_5min'] = (
            features['voltage_mean']
            .rolling(window=30, min_periods=5)  # 30 samples @ 10s = 5min
            .apply(lambda x: np.polyfit(range(len(x)), x, 1)[0])
        )

        features['temp_volatility'] = (
            features['temp_mean']
            .rolling(window=12, min_periods=3)
            .std()
        )

        # Efficiency metrics
        features['thermal_power_ratio'] = (
            features['thermal_gradient'] / (abs(features['power']) + 1.0)
        )

        # Handle NaN from rolling windows
        features = features.fillna(method='bfill').fillna(0)

        self.feature_names = features.columns.tolist()
        return features

    def fit(self, df: pd.DataFrame) -> 'BatteryAnomalyDetector':
        """
        Train detector on normal operating data.

        Args:
            df: DataFrame with battery telemetry (normal conditions only)

        Returns:
            self for chaining
        """
        features = self.engineer_features(df)

        logger.info(f"Training on {len(features)} samples with {len(self.feature_names)} features")
        self.pipeline.fit(features)
        self.trained = True

        # Compute baseline statistics
        predictions = self.pipeline.predict(features)
        scores = self.pipeline.decision_function(features)

        logger.info(f"Training complete. Anomaly rate: {(predictions == -1).mean():.2%}")
        logger.info(f"Score range: [{scores.min():.3f}, {scores.max():.3f}]")

        return self

    def predict(
        self,
        df: pd.DataFrame,
        return_scores: bool = False
    ) -> np.ndarray | Tuple[np.ndarray, np.ndarray]:
        """
        Detect anomalies in new data.

        Args:
            df: DataFrame with battery telemetry
            return_scores: If True, return (labels, scores) tuple

        Returns:
            labels: 1 for normal, -1 for anomaly
            scores: (optional) Anomaly scores (lower = more anomalous)
        """
        if not self.trained:
            raise ValueError("Detector must be trained before prediction")

        features = self.engineer_features(df)
        labels = self.pipeline.predict(features)

        if return_scores:
            scores = self.pipeline.decision_function(features)
            return labels, scores

        return labels

    def explain_anomaly(self, df: pd.DataFrame, index: int) -> Dict[str, float]:
        """
        Explain why a specific sample was flagged as anomalous.

        Returns feature contributions sorted by absolute deviation from mean.
        """
        if not self.trained:
            raise ValueError("Detector must be trained before explanation")

        features = self.engineer_features(df)
        sample = features.iloc[index]

        # Get feature means from training (after scaling)
        scaler = self.pipeline.named_steps['scaler']
        feature_means = scaler.mean_
        feature_stds = scaler.scale_

        # Compute z-scores
        z_scores = {}
        for i, feature_name in enumerate(self.feature_names):
            z_score = abs((sample[feature_name] - feature_means[i]) / feature_stds[i])
            z_scores[feature_name] = z_score

        # Sort by deviation magnitude
        sorted_features = sorted(z_scores.items(), key=lambda x: x[1], reverse=True)

        return dict(sorted_features)

    def save(self, path: str):
        """Save trained model to disk."""
        if not self.trained:
            raise ValueError("Cannot save untrained model")

        joblib.dump({
            'pipeline': self.pipeline,
            'feature_names': self.feature_names
        }, path)
        logger.info(f"Model saved to {path}")

    @classmethod
    def load(cls, path: str) -> 'BatteryAnomalyDetector':
        """Load trained model from disk."""
        data = joblib.load(path)
        detector = cls()
        detector.pipeline = data['pipeline']
        detector.feature_names = data['feature_names']
        detector.trained = True
        logger.info(f"Model loaded from {path}")
        return detector


# Example usage
if __name__ == "__main__":
    # Load training data (normal operation only)
    train_df = pd.read_parquet('battery_telemetry_normal.parquet')

    # Train detector
    detector = BatteryAnomalyDetector(contamination=0.01)
    detector.fit(train_df)

    # Save model
    detector.save('battery_anomaly_detector.pkl')

    # Detect anomalies in new data
    test_df = pd.read_parquet('battery_telemetry_recent.parquet')
    labels, scores = detector.predict(test_df, return_scores=True)

    # Analyze anomalies
    anomaly_indices = np.where(labels == -1)[0]
    print(f"Detected {len(anomaly_indices)} anomalies ({len(anomaly_indices)/len(test_df):.2%})")

    for idx in anomaly_indices[:5]:  # Show first 5
        print(f"\nAnomaly at index {idx} (score: {scores[idx]:.3f})")
        explanation = detector.explain_anomaly(test_df, idx)
        print("Top contributing features:")
        for feature, z_score in list(explanation.items())[:5]:
            print(f"  {feature}: z-score = {z_score:.2f}")
```

## Autoencoder for Time-Series Anomalies

```python
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import numpy as np
import pandas as pd
from typing import Tuple

class BatterySequenceDataset(Dataset):
    """Dataset for time-series battery data."""

    def __init__(self, sequences: np.ndarray):
        """
        Args:
            sequences: (N, seq_len, n_features) array
        """
        self.sequences = torch.FloatTensor(sequences)

    def __len__(self):
        return len(self.sequences)

    def __getitem__(self, idx):
        return self.sequences[idx]


class LSTMAutoencoder(nn.Module):
    """
    LSTM-based autoencoder for battery time-series anomaly detection.

    Architecture:
    - Encoder: LSTM -> reduces sequence to latent vector
    - Decoder: LSTM -> reconstructs sequence from latent
    - Loss: MSE between input and reconstruction
    """

    def __init__(
        self,
        n_features: int,
        seq_len: int,
        latent_dim: int = 16,
        hidden_dim: int = 64,
        n_layers: int = 2,
        dropout: float = 0.2
    ):
        super().__init__()

        self.n_features = n_features
        self.seq_len = seq_len
        self.latent_dim = latent_dim

        # Encoder: (batch, seq_len, n_features) -> (batch, latent_dim)
        self.encoder_lstm = nn.LSTM(
            input_size=n_features,
            hidden_size=hidden_dim,
            num_layers=n_layers,
            batch_first=True,
            dropout=dropout if n_layers > 1 else 0
        )
        self.encoder_fc = nn.Linear(hidden_dim, latent_dim)

        # Decoder: (batch, latent_dim) -> (batch, seq_len, n_features)
        self.decoder_fc = nn.Linear(latent_dim, hidden_dim)
        self.decoder_lstm = nn.LSTM(
            input_size=hidden_dim,
            hidden_size=hidden_dim,
            num_layers=n_layers,
            batch_first=True,
            dropout=dropout if n_layers > 1 else 0
        )
        self.output_fc = nn.Linear(hidden_dim, n_features)

    def encode(self, x: torch.Tensor) -> torch.Tensor:
        """Encode sequence to latent vector."""
        # x: (batch, seq_len, n_features)
        _, (hidden, _) = self.encoder_lstm(x)
        # hidden: (n_layers, batch, hidden_dim) -> take last layer
        latent = self.encoder_fc(hidden[-1])  # (batch, latent_dim)
        return latent

    def decode(self, latent: torch.Tensor) -> torch.Tensor:
        """Decode latent vector to sequence."""
        # latent: (batch, latent_dim)
        hidden = self.decoder_fc(latent)  # (batch, hidden_dim)

        # Repeat hidden for each time step
        hidden_seq = hidden.unsqueeze(1).repeat(1, self.seq_len, 1)
        # hidden_seq: (batch, seq_len, hidden_dim)

        decoder_out, _ = self.decoder_lstm(hidden_seq)
        reconstruction = self.output_fc(decoder_out)
        # reconstruction: (batch, seq_len, n_features)

        return reconstruction

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass: encode then decode."""
        latent = self.encode(x)
        reconstruction = self.decode(latent)
        return reconstruction


class AutoencoderAnomalyDetector:
    """Autoencoder-based anomaly detection for time-series data."""

    def __init__(
        self,
        n_features: int,
        seq_len: int,
        latent_dim: int = 16,
        device: str = 'cpu'
    ):
        self.model = LSTMAutoencoder(
            n_features=n_features,
            seq_len=seq_len,
            latent_dim=latent_dim
        ).to(device)

        self.device = device
        self.threshold = None
        self.scaler_mean = None
        self.scaler_std = None

    def train(
        self,
        sequences: np.ndarray,
        epochs: int = 50,
        batch_size: int = 64,
        lr: float = 0.001
    ):
        """
        Train autoencoder on normal sequences.

        Args:
            sequences: (N, seq_len, n_features) array of normal data
            epochs: Training epochs
            batch_size: Batch size
            lr: Learning rate
        """
        # Normalize
        self.scaler_mean = sequences.mean(axis=(0, 1))
        self.scaler_std = sequences.std(axis=(0, 1)) + 1e-6
        sequences_norm = (sequences - self.scaler_mean) / self.scaler_std

        # Create data loader
        dataset = BatterySequenceDataset(sequences_norm)
        loader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

        # Training
        optimizer = optim.Adam(self.model.parameters(), lr=lr)
        criterion = nn.MSELoss()

        self.model.train()
        for epoch in range(epochs):
            total_loss = 0
            for batch in loader:
                batch = batch.to(self.device)

                optimizer.zero_grad()
                reconstruction = self.model(batch)
                loss = criterion(reconstruction, batch)
                loss.backward()
                optimizer.step()

                total_loss += loss.item()

            avg_loss = total_loss / len(loader)
            if (epoch + 1) % 10 == 0:
                print(f"Epoch {epoch+1}/{epochs}, Loss: {avg_loss:.6f}")

        # Compute threshold (95th percentile of training reconstruction errors)
        self.model.eval()
        with torch.no_grad():
            all_errors = []
            for batch in DataLoader(dataset, batch_size=batch_size):
                batch = batch.to(self.device)
                reconstruction = self.model(batch)
                errors = torch.mean((batch - reconstruction) ** 2, dim=(1, 2))
                all_errors.extend(errors.cpu().numpy())

            self.threshold = np.percentile(all_errors, 95)
            print(f"Anomaly threshold set to: {self.threshold:.6f}")

    def predict(self, sequences: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Detect anomalies in sequences.

        Returns:
            labels: 0 for normal, 1 for anomaly
            errors: Reconstruction error per sequence
        """
        # Normalize
        sequences_norm = (sequences - self.scaler_mean) / self.scaler_std

        dataset = BatterySequenceDataset(sequences_norm)
        loader = DataLoader(dataset, batch_size=64)

        self.model.eval()
        all_errors = []
        with torch.no_grad():
            for batch in loader:
                batch = batch.to(self.device)
                reconstruction = self.model(batch)
                errors = torch.mean((batch - reconstruction) ** 2, dim=(1, 2))
                all_errors.extend(errors.cpu().numpy())

        errors = np.array(all_errors)
        labels = (errors > self.threshold).astype(int)

        return labels, errors
```

## Deployment Strategy

### Edge Deployment (Vehicle ECU)
```yaml
# Model optimization for embedded systems
optimization:
  quantization: INT8  # Reduce model size by 4x
  pruning: 0.3        # Remove 30% least important weights
  inference_engine: ONNX Runtime
  target_latency: <50ms

hardware:
  platform: NVIDIA Jetson Xavier NX / Intel Myriad X
  memory: <100MB per model
  power_budget: <5W

monitoring:
  - Track inference latency
  - Log anomaly rate (should be <1%)
  - Alert on detector failures
```

### Cloud Deployment (Fleet-wide)
```yaml
architecture:
  ingestion: Apache Kafka
  preprocessing: Apache Spark Structured Streaming
  inference: TensorFlow Serving / Ray Serve
  storage: TimescaleDB (anomalies) + S3 (raw data)

scalability:
  - Horizontal scaling based on vehicle count
  - Batch processing for non-real-time analysis
  - A/B testing for model updates

mlops:
  - Model versioning with MLflow
  - Automated retraining on new anomaly patterns
  - Canary deployments (5% -> 25% -> 100%)
  - Rollback on performance degradation
```

## Evaluation Metrics

### For Labeled Test Sets
```python
from sklearn.metrics import (
    precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, classification_report
)

def evaluate_detector(y_true: np.ndarray, y_pred: np.ndarray, scores: np.ndarray):
    """
    Comprehensive evaluation of anomaly detector.

    Args:
        y_true: Ground truth labels (1=anomaly, 0=normal)
        y_pred: Predicted labels (1=anomaly, 0=normal)
        scores: Anomaly scores (continuous)
    """
    # Convert Isolation Forest labels (-1, 1) to (1, 0)
    y_pred_binary = (y_pred == -1).astype(int)

    # Metrics
    precision = precision_score(y_true, y_pred_binary)
    recall = recall_score(y_true, y_pred_binary)
    f1 = f1_score(y_true, y_pred_binary)

    # AUC-ROC (requires scores)
    # Negate scores since Isolation Forest: lower = more anomalous
    auc = roc_auc_score(y_true, -scores)

    print(f"Precision: {precision:.3f}")
    print(f"Recall: {recall:.3f}")
    print(f"F1-Score: {f1:.3f}")
    print(f"AUC-ROC: {auc:.3f}")
    print("\nConfusion Matrix:")
    print(confusion_matrix(y_true, y_pred_binary))
    print("\nClassification Report:")
    print(classification_report(y_true, y_pred_binary,
                                target_names=['Normal', 'Anomaly']))
```

### For Unlabeled Production Data
```python
def monitor_detector_health(predictions: np.ndarray, scores: np.ndarray):
    """
    Monitor detector behavior in production (no ground truth).

    Alerts:
    - Anomaly rate too high (>5%) -> possible drift
    - Anomaly rate too low (<0.1%) -> detector not sensitive
    - Score distribution shift -> model degradation
    """
    anomaly_rate = (predictions == -1).mean()
    score_mean = scores.mean()
    score_std = scores.std()

    print(f"Anomaly Rate: {anomaly_rate:.2%}")
    print(f"Score Mean: {score_mean:.3f} +/- {score_std:.3f}")

    # Alerts
    if anomaly_rate > 0.05:
        print("WARNING: High anomaly rate detected. Possible data drift.")
    elif anomaly_rate < 0.001:
        print("WARNING: Low anomaly rate. Detector may not be sensitive enough.")
```

## Production Checklist

- [ ] Model trained on representative normal data (>10k samples)
- [ ] Threshold calibrated on validation set (target: 1-2% false positive rate)
- [ ] Feature engineering validated for edge cases (missing sensors, extreme temps)
- [ ] Model compressed for edge deployment (ONNX + quantization)
- [ ] Inference latency tested (<100ms p99)
- [ ] Monitoring dashboards configured (Grafana + Prometheus)
- [ ] Alert thresholds set (anomaly rate, detector health)
- [ ] Retraining pipeline automated (weekly batch on new normal data)
- [ ] A/B testing framework ready
- [ ] Rollback procedure documented

---

## Driver Behavior Analysis

# Driver Behavior Analysis and Safety Scoring

Analyze driving patterns, compute safety scores, and provide personalized feedback for driver improvement. Focus on risk assessment, insurance optimization, and training recommendations.

## Use Cases

1. **Safety Scoring**: Quantitative assessment of driver risk (0-100 scale)
2. **Insurance Optimization**: Usage-based insurance (UBI) premiums
3. **Driver Training**: Personalized improvement recommendations
4. **Fleet Management**: Identify high-risk drivers for intervention
5. **Accident Prevention**: Predict and prevent risky behaviors

## Feature Engineering

```python
import pandas as pd
import numpy as np
from typing import Dict, Tuple
from scipy.stats import zscore

class DriverBehaviorFeatureEngineer:
    """
    Extract driver behavior features from vehicle telemetry.

    Feature categories:
    - Acceleration patterns (smooth vs aggressive)
    - Braking behavior (harsh braking frequency)
    - Speed management (speeding, speed variance)
    - Cornering (lateral acceleration)
    - Anticipation (time-to-collision events)
    - Distraction indicators (steering wheel anomalies)
    """

    @staticmethod
    def extract_trip_features(trip_data: pd.DataFrame) -> Dict[str, float]:
        """
        Extract behavior features from a single trip.

        Expected columns:
        - timestamp, speed_kmh, acceleration_ms2, lateral_accel_ms2,
        - brake_pressure, steering_angle, distance_to_vehicle_m,
        - speed_limit_kmh (if available)
        """
        features = {}

        # Trip metadata
        features['duration_min'] = (
            (trip_data['timestamp'].max() - trip_data['timestamp'].min())
            .total_seconds() / 60
        )
        features['distance_km'] = trip_data['speed_kmh'].sum() / 3600  # Simplified

        # Acceleration analysis
        accel = trip_data['acceleration_ms2']
        features['accel_mean'] = accel.mean()
        features['accel_std'] = accel.std()
        features['accel_max'] = accel.max()

        # Harsh acceleration events (> 2.5 m/s²)
        harsh_accel = accel > 2.5
        features['harsh_accel_count'] = harsh_accel.sum()
        features['harsh_accel_rate_per_100km'] = (
            features['harsh_accel_count'] / (features['distance_km'] + 1e-3) * 100
        )

        # Braking analysis
        # Assume deceleration is negative acceleration
        decel = accel[accel < 0]
        features['decel_mean'] = decel.mean() if len(decel) > 0 else 0
        features['decel_std'] = decel.std() if len(decel) > 0 else 0

        # Harsh braking events (< -3.0 m/s²)
        harsh_brake = accel < -3.0
        features['harsh_brake_count'] = harsh_brake.sum()
        features['harsh_brake_rate_per_100km'] = (
            features['harsh_brake_count'] / (features['distance_km'] + 1e-3) * 100
        )

        # Brake pressure statistics
        if 'brake_pressure' in trip_data.columns:
            brake = trip_data['brake_pressure']
            features['brake_pressure_mean'] = brake.mean()
            features['brake_pressure_max'] = brake.max()

            # Emergency braking (brake pressure > 0.8)
            emergency_brake = brake > 0.8
            features['emergency_brake_count'] = emergency_brake.sum()

        # Speed management
        speed = trip_data['speed_kmh']
        features['speed_mean'] = speed.mean()
        features['speed_std'] = speed.std()
        features['speed_max'] = speed.max()

        # Speed variance (indication of smooth vs erratic driving)
        features['speed_variance'] = speed.var()

        # Speeding analysis
        if 'speed_limit_kmh' in trip_data.columns:
            speeding = speed > trip_data['speed_limit_kmh']
            features['speeding_pct'] = (speeding.sum() / len(trip_data)) * 100

            # Excessive speeding (>20 km/h over limit)
            excessive_speeding = (speed - trip_data['speed_limit_kmh']) > 20
            features['excessive_speeding_pct'] = (
                excessive_speeding.sum() / len(trip_data)
            ) * 100
        else:
            features['speeding_pct'] = 0
            features['excessive_speeding_pct'] = 0

        # Cornering analysis
        if 'lateral_accel_ms2' in trip_data.columns:
            lateral_accel = trip_data['lateral_accel_ms2']
            features['lateral_accel_mean'] = abs(lateral_accel).mean()
            features['lateral_accel_max'] = abs(lateral_accel).max()

            # Harsh cornering (lateral accel > 4 m/s²)
            harsh_corner = abs(lateral_accel) > 4.0
            features['harsh_corner_count'] = harsh_corner.sum()
            features['harsh_corner_rate_per_100km'] = (
                features['harsh_corner_count'] / (features['distance_km'] + 1e-3) * 100
            )

        # Anticipation and safety margins
        if 'distance_to_vehicle_m' in trip_data.columns:
            # Time-to-collision (TTC) at current speed
            # TTC = distance / speed
            ttc = trip_data['distance_to_vehicle_m'] / (
                trip_data['speed_kmh'] / 3.6 + 1e-3
            )  # Convert to m/s

            # Critical TTC events (<2 seconds)
            critical_ttc = ttc < 2.0
            features['critical_ttc_count'] = critical_ttc.sum()
            features['critical_ttc_rate_per_100km'] = (
                features['critical_ttc_count'] / (features['distance_km'] + 1e-3) * 100
            )

            features['avg_following_distance_m'] = trip_data['distance_to_vehicle_m'].mean()

        # Steering behavior (distraction indicator)
        if 'steering_angle' in trip_data.columns:
            steering = trip_data['steering_angle']
            features['steering_variance'] = steering.diff().abs().var()

            # Erratic steering (high frequency oscillations)
            steering_changes = abs(steering.diff())
            features['erratic_steering_events'] = (steering_changes > 10).sum()

        # Idle time (inefficient driving)
        idle = (speed < 1) & (accel.abs() < 0.1)
        features['idle_time_min'] = idle.sum() / 60  # Assuming 1 Hz data

        return features

    @staticmethod
    def aggregate_driver_features(
        trip_features_list: list
    ) -> pd.DataFrame:
        """
        Aggregate features across multiple trips for driver profiling.

        Args:
            trip_features_list: List of feature dictionaries (one per trip)

        Returns:
            DataFrame with aggregated driver statistics
        """
        df = pd.DataFrame(trip_features_list)

        # Aggregate statistics
        agg_features = {}

        # Mean metrics
        mean_cols = [
            'harsh_accel_rate_per_100km',
            'harsh_brake_rate_per_100km',
            'harsh_corner_rate_per_100km',
            'speeding_pct',
            'excessive_speeding_pct',
            'speed_variance',
            'critical_ttc_rate_per_100km'
        ]

        for col in mean_cols:
            if col in df.columns:
                agg_features[f'{col}_mean'] = df[col].mean()
                agg_features[f'{col}_std'] = df[col].std()

        # Count metrics
        count_cols = [
            'harsh_accel_count',
            'harsh_brake_count',
            'emergency_brake_count',
            'critical_ttc_count'
        ]

        for col in count_cols:
            if col in df.columns:
                agg_features[f'{col}_total'] = df[col].sum()

        # Totals
        agg_features['total_trips'] = len(df)
        agg_features['total_distance_km'] = df['distance_km'].sum()
        agg_features['total_duration_min'] = df['duration_min'].sum()

        return pd.DataFrame([agg_features])


# Example usage
if __name__ == "__main__":
    # Load trip data
    trip_df = pd.read_parquet('trip_001.parquet')

    # Extract features
    engineer = DriverBehaviorFeatureEngineer()
    features = engineer.extract_trip_features(trip_df)

    print("Trip Features:")
    for key, value in features.items():
        print(f"  {key}: {value:.3f}")
```

## Safety Scoring Model

```python
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from typing import Dict, Tuple
import joblib

class DriverSafetyScoringModel:
    """
    Compute comprehensive driver safety score (0-100).

    Methodology:
    - Weighted composite of sub-scores
    - Penalize risky behaviors
    - Reward safe driving patterns
    - Calibrated against industry benchmarks
    """

    def __init__(self):
        """
        Initialize scoring model with component weights.
        """
        # Component weights (must sum to 1.0)
        self.weights = {
            'acceleration': 0.20,
            'braking': 0.25,
            'speed': 0.25,
            'cornering': 0.15,
            'anticipation': 0.15
        }

        # Benchmark values (50th percentile of safe drivers)
        self.benchmarks = {
            'harsh_accel_rate_per_100km': 5.0,
            'harsh_brake_rate_per_100km': 3.0,
            'harsh_corner_rate_per_100km': 2.0,
            'speeding_pct': 10.0,
            'excessive_speeding_pct': 1.0,
            'speed_variance': 150.0,
            'critical_ttc_rate_per_100km': 2.0
        }

        # Penalty factors (multiplier for scores below threshold)
        self.penalties = {
            'emergency_brake_count': 5.0,  # -5 points per event
            'critical_ttc_count': 3.0       # -3 points per event
        }

    def compute_acceleration_score(self, features: Dict) -> float:
        """
        Score acceleration behavior (0-100).

        Lower harsh acceleration rate = higher score.
        """
        rate = features.get('harsh_accel_rate_per_100km_mean', 0)
        benchmark = self.benchmarks['harsh_accel_rate_per_100km']

        # Exponential decay: score = 100 * exp(-rate / benchmark)
        score = 100 * np.exp(-rate / benchmark)

        return np.clip(score, 0, 100)

    def compute_braking_score(self, features: Dict) -> float:
        """
        Score braking behavior (0-100).

        Penalize harsh braking and emergency stops.
        """
        rate = features.get('harsh_brake_rate_per_100km_mean', 0)
        benchmark = self.benchmarks['harsh_brake_rate_per_100km']

        base_score = 100 * np.exp(-rate / benchmark)

        # Apply penalty for emergency braking
        emergency_count = features.get('emergency_brake_count_total', 0)
        penalty = emergency_count * self.penalties['emergency_brake_count']

        score = base_score - penalty

        return np.clip(score, 0, 100)

    def compute_speed_score(self, features: Dict) -> float:
        """
        Score speed management (0-100).

        Penalize speeding and erratic speed changes.
        """
        speeding_pct = features.get('speeding_pct_mean', 0)
        excessive_pct = features.get('excessive_speeding_pct_mean', 0)
        speed_var = features.get('speed_variance_mean', 0)

        # Speed limit compliance
        speeding_benchmark = self.benchmarks['speeding_pct']
        speeding_score = 100 * np.exp(-speeding_pct / speeding_benchmark)

        # Excessive speeding (heavy penalty)
        excessive_benchmark = self.benchmarks['excessive_speeding_pct']
        excessive_penalty = 50 * (excessive_pct / (excessive_benchmark + 1))

        # Speed smoothness
        variance_benchmark = self.benchmarks['speed_variance']
        smoothness_score = 100 * np.exp(-speed_var / variance_benchmark)

        # Weighted average
        score = (
            0.5 * speeding_score +
            0.3 * smoothness_score -
            0.2 * excessive_penalty
        )

        return np.clip(score, 0, 100)

    def compute_cornering_score(self, features: Dict) -> float:
        """
        Score cornering behavior (0-100).

        Reward smooth cornering, penalize harsh turns.
        """
        rate = features.get('harsh_corner_rate_per_100km_mean', 0)
        benchmark = self.benchmarks['harsh_corner_rate_per_100km']

        score = 100 * np.exp(-rate / benchmark)

        return np.clip(score, 0, 100)

    def compute_anticipation_score(self, features: Dict) -> float:
        """
        Score anticipation and safety margins (0-100).

        Penalize tailgating and critical TTC events.
        """
        ttc_rate = features.get('critical_ttc_rate_per_100km_mean', 0)
        benchmark = self.benchmarks['critical_ttc_rate_per_100km']

        base_score = 100 * np.exp(-ttc_rate / benchmark)

        # Apply penalty for critical TTC events
        ttc_count = features.get('critical_ttc_count_total', 0)
        penalty = ttc_count * self.penalties['critical_ttc_count']

        score = base_score - penalty

        return np.clip(score, 0, 100)

    def compute_overall_score(self, features: Dict) -> Tuple[float, Dict[str, float]]:
        """
        Compute weighted overall safety score.

        Returns:
            overall_score: Composite score (0-100)
            component_scores: Dictionary of sub-scores
        """
        # Compute component scores
        components = {
            'acceleration': self.compute_acceleration_score(features),
            'braking': self.compute_braking_score(features),
            'speed': self.compute_speed_score(features),
            'cornering': self.compute_cornering_score(features),
            'anticipation': self.compute_anticipation_score(features)
        }

        # Weighted average
        overall = sum(
            components[key] * self.weights[key]
            for key in components
        )

        return overall, components

    def classify_risk_level(self, score: float) -> str:
        """
        Classify driver into risk category.

        Args:
            score: Safety score (0-100)

        Returns:
            Risk category string
        """
        if score >= 85:
            return 'Low Risk'
        elif score >= 70:
            return 'Medium Risk'
        elif score >= 50:
            return 'High Risk'
        else:
            return 'Critical Risk'

    def generate_feedback(
        self,
        components: Dict[str, float]
    ) -> list:
        """
        Generate personalized feedback for driver improvement.

        Args:
            components: Component scores dictionary

        Returns:
            List of improvement recommendations
        """
        feedback = []

        # Identify weakest areas
        sorted_components = sorted(components.items(), key=lambda x: x[1])

        for component, score in sorted_components[:2]:  # Focus on 2 worst
            if score < 70:
                if component == 'acceleration':
                    feedback.append(
                        "⚠️ Reduce harsh acceleration. Gradually increase speed to "
                        "improve fuel efficiency and safety."
                    )
                elif component == 'braking':
                    feedback.append(
                        "⚠️ Anticipate stops earlier to avoid harsh braking. "
                        "Maintain safe following distance."
                    )
                elif component == 'speed':
                    feedback.append(
                        "⚠️ Adhere to speed limits and maintain consistent speed. "
                        "Reduce speeding incidents."
                    )
                elif component == 'cornering':
                    feedback.append(
                        "⚠️ Slow down before corners. Smooth steering reduces tire wear "
                        "and improves stability."
                    )
                elif component == 'anticipation':
                    feedback.append(
                        "⚠️ Increase following distance. Avoid tailgating to reduce "
                        "collision risk."
                    )

        # Positive reinforcement for strong areas
        best_component = max(components.items(), key=lambda x: x[1])
        if best_component[1] >= 90:
            feedback.append(
                f"✅ Excellent {best_component[0]} behavior! Keep it up."
            )

        return feedback


# Example usage
if __name__ == "__main__":
    # Sample driver features (aggregated from multiple trips)
    driver_features = {
        'harsh_accel_rate_per_100km_mean': 7.2,
        'harsh_brake_rate_per_100km_mean': 4.5,
        'harsh_corner_rate_per_100km_mean': 1.8,
        'speeding_pct_mean': 15.0,
        'excessive_speeding_pct_mean': 2.5,
        'speed_variance_mean': 180.0,
        'critical_ttc_rate_per_100km_mean': 3.0,
        'emergency_brake_count_total': 2,
        'critical_ttc_count_total': 5
    }

    # Compute safety score
    scorer = DriverSafetyScoringModel()
    overall_score, components = scorer.compute_overall_score(driver_features)
    risk_level = scorer.classify_risk_level(overall_score)

    print(f"\nOverall Safety Score: {overall_score:.1f} / 100")
    print(f"Risk Level: {risk_level}\n")

    print("Component Scores:")
    for component, score in components.items():
        print(f"  {component.capitalize()}: {score:.1f}")

    print("\nPersonalized Feedback:")
    feedback = scorer.generate_feedback(components)
    for item in feedback:
        print(f"  {item}")
```

## Driver Clustering

```python
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

class DriverClustering:
    """
    Cluster drivers into behavioral profiles.

    Profiles:
    - Conservative: Low speeds, smooth acceleration/braking
    - Aggressive: High speeds, harsh maneuvers
    - Efficient: Optimized for fuel/energy efficiency
    - Distracted: Erratic patterns, low anticipation
    """

    def __init__(self, n_clusters: int = 4):
        self.n_clusters = n_clusters
        self.scaler = StandardScaler()
        self.kmeans = KMeans(n_clusters=n_clusters, random_state=42)

    def prepare_features(self, driver_data: pd.DataFrame) -> pd.DataFrame:
        """
        Select and normalize features for clustering.

        Expected columns: driver_id, harsh_accel_rate, harsh_brake_rate,
        speeding_pct, speed_variance, critical_ttc_rate
        """
        feature_cols = [
            'harsh_accel_rate_per_100km_mean',
            'harsh_brake_rate_per_100km_mean',
            'speeding_pct_mean',
            'speed_variance_mean',
            'critical_ttc_rate_per_100km_mean'
        ]

        X = driver_data[feature_cols]
        X_scaled = self.scaler.fit_transform(X)

        return X_scaled, feature_cols

    def fit_predict(self, driver_data: pd.DataFrame) -> np.ndarray:
        """
        Cluster drivers and return labels.

        Returns:
            Cluster labels (0 to n_clusters-1)
        """
        X_scaled, _ = self.prepare_features(driver_data)
        labels = self.kmeans.fit_predict(X_scaled)

        return labels

    def visualize_clusters(
        self,
        driver_data: pd.DataFrame,
        labels: np.ndarray
    ):
        """
        Visualize driver clusters using pair plot.
        """
        # Add cluster labels
        driver_data_labeled = driver_data.copy()
        driver_data_labeled['cluster'] = labels

        # Select key features for visualization
        viz_features = [
            'harsh_accel_rate_per_100km_mean',
            'harsh_brake_rate_per_100km_mean',
            'speeding_pct_mean',
            'cluster'
        ]

        sns.pairplot(
            driver_data_labeled[viz_features],
            hue='cluster',
            palette='viridis',
            diag_kind='kde'
        )
        plt.suptitle('Driver Behavior Clusters', y=1.02)
        plt.show()

    def describe_clusters(
        self,
        driver_data: pd.DataFrame,
        labels: np.ndarray
    ) -> pd.DataFrame:
        """
        Describe cluster characteristics.

        Returns:
            DataFrame with cluster profiles
        """
        driver_data_labeled = driver_data.copy()
        driver_data_labeled['cluster'] = labels

        profiles = driver_data_labeled.groupby('cluster').agg({
            'harsh_accel_rate_per_100km_mean': 'mean',
            'harsh_brake_rate_per_100km_mean': 'mean',
            'speeding_pct_mean': 'mean',
            'speed_variance_mean': 'mean',
            'critical_ttc_rate_per_100km_mean': 'mean'
        }).round(2)

        return profiles

    def assign_profile_names(
        self,
        profiles: pd.DataFrame
    ) -> Dict[int, str]:
        """
        Assign interpretable names to clusters.
        """
        names = {}

        for cluster_id in profiles.index:
            accel = profiles.loc[cluster_id, 'harsh_accel_rate_per_100km_mean']
            brake = profiles.loc[cluster_id, 'harsh_brake_rate_per_100km_mean']
            speeding = profiles.loc[cluster_id, 'speeding_pct_mean']

            # Rule-based naming
            if accel < 3 and brake < 2 and speeding < 5:
                names[cluster_id] = "Conservative"
            elif accel > 8 and brake > 5:
                names[cluster_id] = "Aggressive"
            elif speeding > 20:
                names[cluster_id] = "Speeder"
            else:
                names[cluster_id] = "Average"

        return names
```

## Deployment Architecture

```yaml
# Driver behavior analytics pipeline
pipeline:
  data_collection:
    source: Vehicle telemetry (CAN bus) + GPS
    frequency: 10 Hz (acceleration, speed), 1 Hz (location)
    storage: TimescaleDB (raw) + Parquet (trips)

  trip_segmentation:
    algorithm: Speed-based (ignition on/off or idle detection)
    min_duration: 2 minutes
    min_distance: 1 km

  feature_extraction:
    engine: Apache Spark (batch) or Python (streaming)
    frequency: Per-trip (real-time) + weekly aggregation
    storage: PostgreSQL (features table)

  scoring:
    model: Rule-based composite score
    update_frequency: Daily (driver profile)
    storage: PostgreSQL (scores table)

  dashboard:
    framework: Streamlit / React
    update_frequency: Real-time (trip-level), daily (aggregates)
    features: Score trends, feedback, leaderboard

monitoring:
  metrics:
    - Score distribution (fleet-wide)
    - Score volatility (per driver)
    - Feature extraction success rate
    - Dashboard latency

alerts:
  - Critical risk driver detected (score < 50)
  - Repeated risky behaviors (3+ harsh events per trip)
  - Score degradation (>10 point drop in 7 days)
```

## Production Checklist

- [ ] Trip segmentation validated (accuracy > 95%)
- [ ] Feature extraction handles edge cases (short trips, missing sensors)
- [ ] Score calibration validated against insurance claims data
- [ ] Feedback messages reviewed for clarity and positivity
- [ ] Dashboard responsive (<2s load time)
- [ ] Privacy compliance (GDPR, CCPA) - anonymization
- [ ] Driver consent workflow implemented
- [ ] Alert thresholds configured (avoid alert fatigue)
- [ ] A/B testing for scoring algorithm changes
- [ ] Driver appeal process documented

---

## Energy Optimization

# Energy Optimization and Route Planning

Optimize energy consumption through intelligent route planning, charging strategies, and predictive algorithms. Focus on electric vehicles with battery-electric and plug-in hybrid powertrains.

## Use Cases

1. **Route Optimization**: Minimize energy consumption for given destination
2. **Charging Strategy**: Optimize charging times and locations for cost/time
3. **Range Prediction**: Accurate remaining range estimation
4. **Eco-Routing**: Balance time vs energy trade-offs
5. **Fleet Electrification**: Optimal EV deployment planning

## Route Optimization with Reinforcement Learning

```python
import numpy as np
import pandas as pd
import gym
from gym import spaces
from typing import Tuple, Dict, List
import torch
import torch.nn as nn
import torch.optim as optim
from collections import deque
import random

class EVRoutingEnvironment(gym.Env):
    """
    OpenAI Gym environment for EV route optimization.

    State: Current location, SOC, traffic conditions, weather
    Action: Next waypoint selection
    Reward: -(energy_consumed + time_penalty + charging_cost)
    """

    def __init__(
        self,
        road_network: pd.DataFrame,
        charging_stations: pd.DataFrame,
        battery_capacity_kwh: float = 75.0
    ):
        """
        Args:
            road_network: Graph with edges (src, dst, distance, elevation, speed_limit)
            charging_stations: Locations with (lat, lon, power_kw, cost_per_kwh)
            battery_capacity_kwh: Vehicle battery capacity
        """
        super().__init__()

        self.road_network = road_network
        self.charging_stations = charging_stations
        self.battery_capacity = battery_capacity_kwh

        # State space: [current_node_id, soc, time_of_day, traffic_level]
        self.observation_space = spaces.Box(
            low=np.array([0, 0, 0, 0]),
            high=np.array([len(road_network), 100, 24, 10]),
            dtype=np.float32
        )

        # Action space: [next_node_id, charge_decision (0=no, 1=yes)]
        self.action_space = spaces.MultiDiscrete([len(road_network), 2])

        self.reset()

    def reset(self) -> np.ndarray:
        """
        Reset environment to initial state.

        Returns:
            Initial observation
        """
        self.current_node = 0  # Start node
        self.destination_node = len(self.road_network) - 1
        self.soc = 80.0  # Start with 80% SOC
        self.time = 8.0  # Start at 8 AM
        self.total_energy = 0
        self.total_cost = 0
        self.trajectory = [self.current_node]

        return self._get_observation()

    def _get_observation(self) -> np.ndarray:
        """Get current state observation."""
        traffic_level = self._get_traffic_level(self.time)
        return np.array([
            self.current_node,
            self.soc,
            self.time,
            traffic_level
        ], dtype=np.float32)

    def _get_traffic_level(self, time: float) -> float:
        """
        Model traffic congestion by time of day.

        Peak hours: 7-9 AM, 5-7 PM -> High traffic
        """
        if (7 <= time <= 9) or (17 <= time <= 19):
            return 8.0  # High traffic
        elif (6 <= time <= 10) or (16 <= time <= 20):
            return 5.0  # Medium traffic
        else:
            return 2.0  # Low traffic

    def _compute_energy_consumption(
        self,
        distance_km: float,
        elevation_gain_m: float,
        speed_kmh: float,
        traffic_level: float
    ) -> float:
        """
        Estimate energy consumption for segment.

        Model: Base consumption + elevation + traffic penalty
        """
        # Base consumption (kWh per 100 km)
        base_consumption = 18.0

        # Elevation impact (100m climb ≈ 1 kWh)
        elevation_energy = max(0, elevation_gain_m / 100)

        # Speed efficiency (optimal around 60 km/h)
        speed_factor = 1 + 0.01 * abs(speed_kmh - 60)

        # Traffic penalty (stop-and-go increases consumption)
        traffic_factor = 1 + 0.05 * traffic_level

        total_energy = (
            base_consumption * distance_km / 100 * speed_factor * traffic_factor +
            elevation_energy
        )

        return total_energy

    def step(self, action: Tuple[int, int]) -> Tuple[np.ndarray, float, bool, Dict]:
        """
        Execute action and return next state.

        Args:
            action: (next_node_id, charge_decision)

        Returns:
            observation, reward, done, info
        """
        next_node, charge_decision = action

        # Get edge info
        edge = self.road_network[
            (self.road_network['src'] == self.current_node) &
            (self.road_network['dst'] == next_node)
        ]

        if edge.empty:
            # Invalid action (no edge)
            return self._get_observation(), -1000, True, {'error': 'invalid_edge'}

        edge = edge.iloc[0]
        distance = edge['distance_km']
        elevation = edge['elevation_gain_m']
        speed_limit = edge['speed_limit_kmh']

        # Traffic-adjusted speed
        traffic_level = self._get_traffic_level(self.time)
        avg_speed = speed_limit * (1 - 0.05 * traffic_level)  # Slower in traffic

        # Energy consumption
        energy_consumed = self._compute_energy_consumption(
            distance, elevation, avg_speed, traffic_level
        )

        # Update SOC
        self.soc -= (energy_consumed / self.battery_capacity) * 100

        # Time elapsed
        time_elapsed = distance / avg_speed  # hours
        self.time += time_elapsed

        # Charging decision
        charging_cost = 0
        charging_time = 0

        if charge_decision == 1:
            # Find nearest charging station
            station = self.charging_stations.iloc[0]  # Simplified
            charge_amount_kwh = (80 - self.soc) / 100 * self.battery_capacity
            charging_time = charge_amount_kwh / station['power_kw']
            charging_cost = charge_amount_kwh * station['cost_per_kwh']

            self.soc = 80.0  # Charge to 80%
            self.time += charging_time
            self.total_cost += charging_cost

        # Update trajectory
        self.current_node = next_node
        self.trajectory.append(next_node)
        self.total_energy += energy_consumed

        # Check if done
        done = False
        if self.current_node == self.destination_node:
            done = True
        elif self.soc < 10:
            # Ran out of battery
            done = True
            reward = -1000
            return self._get_observation(), reward, done, {'error': 'battery_depleted'}

        # Compute reward
        # Minimize: energy + time + charging cost
        reward = -(
            energy_consumed +
            10 * time_elapsed +  # Time penalty
            charging_cost
        )

        # Bonus for reaching destination
        if done and self.current_node == self.destination_node:
            reward += 100

        info = {
            'energy_consumed': energy_consumed,
            'time_elapsed': time_elapsed,
            'charging_cost': charging_cost,
            'soc': self.soc
        }

        return self._get_observation(), reward, done, info


class DQN(nn.Module):
    """
    Deep Q-Network for route optimization.

    Architecture: Fully connected layers with ReLU activations.
    """

    def __init__(self, state_dim: int, action_dim: int):
        super().__init__()

        self.fc = nn.Sequential(
            nn.Linear(state_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 128),
            nn.ReLU(),
            nn.Linear(128, action_dim)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.fc(x)


class DQNAgent:
    """
    DQN agent for EV route optimization.

    Uses experience replay and target network for stable learning.
    """

    def __init__(
        self,
        state_dim: int,
        action_dim: int,
        lr: float = 0.001,
        gamma: float = 0.99,
        epsilon: float = 1.0,
        epsilon_decay: float = 0.995,
        epsilon_min: float = 0.01
    ):
        self.state_dim = state_dim
        self.action_dim = action_dim
        self.gamma = gamma
        self.epsilon = epsilon
        self.epsilon_decay = epsilon_decay
        self.epsilon_min = epsilon_min

        # Q-network and target network
        self.q_network = DQN(state_dim, action_dim)
        self.target_network = DQN(state_dim, action_dim)
        self.target_network.load_state_dict(self.q_network.state_dict())

        self.optimizer = optim.Adam(self.q_network.parameters(), lr=lr)
        self.criterion = nn.MSELoss()

        # Experience replay
        self.memory = deque(maxlen=10000)
        self.batch_size = 64

    def select_action(self, state: np.ndarray) -> int:
        """
        Epsilon-greedy action selection.
        """
        if random.random() < self.epsilon:
            return random.randint(0, self.action_dim - 1)
        else:
            state_tensor = torch.FloatTensor(state).unsqueeze(0)
            with torch.no_grad():
                q_values = self.q_network(state_tensor)
            return q_values.argmax().item()

    def store_transition(
        self,
        state: np.ndarray,
        action: int,
        reward: float,
        next_state: np.ndarray,
        done: bool
    ):
        """Store experience in replay buffer."""
        self.memory.append((state, action, reward, next_state, done))

    def train(self):
        """Train Q-network on batch from replay buffer."""
        if len(self.memory) < self.batch_size:
            return

        # Sample batch
        batch = random.sample(self.memory, self.batch_size)
        states, actions, rewards, next_states, dones = zip(*batch)

        states = torch.FloatTensor(np.array(states))
        actions = torch.LongTensor(actions)
        rewards = torch.FloatTensor(rewards)
        next_states = torch.FloatTensor(np.array(next_states))
        dones = torch.FloatTensor(dones)

        # Current Q-values
        q_values = self.q_network(states).gather(1, actions.unsqueeze(1)).squeeze()

        # Target Q-values
        with torch.no_grad():
            next_q_values = self.target_network(next_states).max(1)[0]
            target_q_values = rewards + self.gamma * next_q_values * (1 - dones)

        # Loss and optimization
        loss = self.criterion(q_values, target_q_values)

        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        # Decay epsilon
        self.epsilon = max(self.epsilon_min, self.epsilon * self.epsilon_decay)

    def update_target_network(self):
        """Copy weights from Q-network to target network."""
        self.target_network.load_state_dict(self.q_network.state_dict())


# Example training loop
if __name__ == "__main__":
    # Create environment (with dummy data)
    road_network = pd.DataFrame({
        'src': [0, 1, 2],
        'dst': [1, 2, 3],
        'distance_km': [10, 15, 20],
        'elevation_gain_m': [50, 100, 150],
        'speed_limit_kmh': [60, 80, 100]
    })

    charging_stations = pd.DataFrame({
        'lat': [37.7749],
        'lon': [-122.4194],
        'power_kw': [150],
        'cost_per_kwh': [0.25]
    })

    env = EVRoutingEnvironment(road_network, charging_stations)

    # Initialize agent
    agent = DQNAgent(
        state_dim=env.observation_space.shape[0],
        action_dim=len(road_network)  # Simplified
    )

    # Training
    episodes = 500
    for episode in range(episodes):
        state = env.reset()
        total_reward = 0

        for step in range(100):
            action = agent.select_action(state)
            # Simplified action (no charging decision for now)
            next_state, reward, done, info = env.step((action, 0))

            agent.store_transition(state, action, reward, next_state, done)
            agent.train()

            state = next_state
            total_reward += reward

            if done:
                break

        # Update target network every 10 episodes
        if episode % 10 == 0:
            agent.update_target_network()

        if episode % 50 == 0:
            print(f"Episode {episode}, Total Reward: {total_reward:.2f}, "
                  f"Epsilon: {agent.epsilon:.3f}")
```

## Charging Strategy Optimization

```python
import pulp
import numpy as np
import pandas as pd
from typing import List, Dict, Tuple

class ChargingStrategyOptimizer:
    """
    Optimize charging schedule for fleet to minimize cost and maximize availability.

    Objective: Minimize electricity cost while ensuring all vehicles charged for next day.

    Constraints:
    - Each vehicle must reach target SOC before departure
    - Charger capacity limits (power, number of chargers)
    - Time-of-use electricity pricing
    """

    def __init__(
        self,
        n_vehicles: int,
        n_chargers: int,
        charger_power_kw: float,
        time_slots: int = 24,
        battery_capacity_kwh: float = 75.0
    ):
        """
        Args:
            n_vehicles: Number of vehicles in fleet
            n_chargers: Number of available chargers
            charger_power_kw: Charging power per charger [kW]
            time_slots: Planning horizon (hours)
            battery_capacity_kwh: Vehicle battery capacity
        """
        self.n_vehicles = n_vehicles
        self.n_chargers = n_chargers
        self.charger_power = charger_power_kw
        self.time_slots = time_slots
        self.battery_capacity = battery_capacity_kwh

    def optimize_schedule(
        self,
        arrival_soc: np.ndarray,
        target_soc: np.ndarray,
        arrival_times: np.ndarray,
        departure_times: np.ndarray,
        electricity_prices: np.ndarray
    ) -> Dict:
        """
        Optimize charging schedule using linear programming.

        Args:
            arrival_soc: Current SOC for each vehicle [%] (n_vehicles,)
            target_soc: Desired SOC for each vehicle [%] (n_vehicles,)
            arrival_times: Arrival time slot for each vehicle (n_vehicles,)
            departure_times: Departure time slot for each vehicle (n_vehicles,)
            electricity_prices: Price per kWh for each time slot [$/kWh] (time_slots,)

        Returns:
            Dictionary with optimal charging schedule
        """
        # Create optimization problem
        prob = pulp.LpProblem("Fleet_Charging_Optimization", pulp.LpMinimize)

        # Decision variables: charging[vehicle, time] = kWh charged in time slot
        charging = {}
        for v in range(self.n_vehicles):
            for t in range(self.time_slots):
                charging[v, t] = pulp.LpVariable(
                    f"charge_v{v}_t{t}",
                    lowBound=0,
                    upBound=self.charger_power  # Max charge rate
                )

        # Binary variable: is_charging[vehicle, time] = 1 if vehicle is charging
        is_charging = {}
        for v in range(self.n_vehicles):
            for t in range(self.time_slots):
                is_charging[v, t] = pulp.LpVariable(
                    f"is_charging_v{v}_t{t}",
                    cat='Binary'
                )

        # Objective: Minimize total electricity cost
        total_cost = pulp.lpSum([
            charging[v, t] * electricity_prices[t]
            for v in range(self.n_vehicles)
            for t in range(self.time_slots)
        ])
        prob += total_cost

        # Constraint 1: Each vehicle reaches target SOC
        for v in range(self.n_vehicles):
            energy_needed = (
                (target_soc[v] - arrival_soc[v]) / 100 * self.battery_capacity
            )

            total_charged = pulp.lpSum([
                charging[v, t]
                for t in range(int(arrival_times[v]), int(departure_times[v]))
            ])

            prob += total_charged >= energy_needed, f"target_soc_v{v}"

        # Constraint 2: Charger capacity (max n_chargers in use at once)
        for t in range(self.time_slots):
            prob += (
                pulp.lpSum([is_charging[v, t] for v in range(self.n_vehicles)]) <=
                self.n_chargers
            ), f"charger_capacity_t{t}"

        # Constraint 3: Link charging amount to is_charging binary
        for v in range(self.n_vehicles):
            for t in range(self.time_slots):
                prob += charging[v, t] <= self.charger_power * is_charging[v, t]

        # Constraint 4: Only charge when vehicle is available
        for v in range(self.n_vehicles):
            for t in range(self.time_slots):
                if t < arrival_times[v] or t >= departure_times[v]:
                    prob += charging[v, t] == 0

        # Solve
        prob.solve(pulp.PULP_CBC_CMD(msg=0))

        # Extract solution
        schedule = np.zeros((self.n_vehicles, self.time_slots))
        for v in range(self.n_vehicles):
            for t in range(self.time_slots):
                schedule[v, t] = pulp.value(charging[v, t])

        total_cost_value = pulp.value(prob.objective)
        total_energy = schedule.sum()

        return {
            'schedule': schedule,
            'total_cost_usd': total_cost_value,
            'total_energy_kwh': total_energy,
            'status': pulp.LpStatus[prob.status]
        }

    def visualize_schedule(self, schedule: np.ndarray, electricity_prices: np.ndarray):
        """
        Visualize charging schedule.

        Args:
            schedule: Charging schedule matrix (n_vehicles, time_slots)
            electricity_prices: Price per time slot
        """
        import matplotlib.pyplot as plt

        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

        # Heatmap of charging schedule
        im = ax1.imshow(schedule, aspect='auto', cmap='YlOrRd')
        ax1.set_ylabel('Vehicle ID')
        ax1.set_title('Charging Schedule (kWh per hour)')
        plt.colorbar(im, ax=ax1, label='Energy (kWh)')

        # Electricity prices
        ax2.bar(range(self.time_slots), electricity_prices, color='steelblue')
        ax2.set_xlabel('Hour of Day')
        ax2.set_ylabel('Price ($/kWh)')
        ax2.set_title('Time-of-Use Electricity Pricing')

        plt.tight_layout()
        plt.show()


# Example usage
if __name__ == "__main__":
    # Fleet parameters
    n_vehicles = 10
    n_chargers = 5

    # Vehicle data
    np.random.seed(42)
    arrival_soc = np.random.uniform(20, 50, n_vehicles)  # Return with 20-50% SOC
    target_soc = np.full(n_vehicles, 90.0)  # Charge to 90%
    arrival_times = np.random.randint(18, 20, n_vehicles)  # Return 6-8 PM
    departure_times = np.random.randint(6, 8, n_vehicles)  # Depart 6-8 AM next day

    # Time-of-use pricing (higher during peak hours)
    electricity_prices = np.array([
        0.08, 0.08, 0.08, 0.08, 0.08, 0.08,  # 12AM-6AM: Off-peak
        0.15, 0.15, 0.20, 0.20, 0.15, 0.15,  # 6AM-12PM: Morning peak
        0.12, 0.12, 0.12, 0.12, 0.20, 0.20,  # 12PM-6PM: Afternoon peak
        0.18, 0.18, 0.12, 0.12, 0.08, 0.08   # 6PM-12AM: Evening/off-peak
    ])

    # Optimize
    optimizer = ChargingStrategyOptimizer(
        n_vehicles=n_vehicles,
        n_chargers=n_chargers,
        charger_power_kw=50.0
    )

    result = optimizer.optimize_schedule(
        arrival_soc=arrival_soc,
        target_soc=target_soc,
        arrival_times=arrival_times,
        departure_times=departure_times,
        electricity_prices=electricity_prices
    )

    print(f"Optimization Status: {result['status']}")
    print(f"Total Cost: ${result['total_cost_usd']:.2f}")
    print(f"Total Energy: {result['total_energy_kwh']:.2f} kWh")

    # Visualize
    optimizer.visualize_schedule(result['schedule'], electricity_prices)
```

## Eco-Routing with Multi-Objective Optimization

```python
import numpy as np
import pandas as pd
from typing import List, Tuple
from scipy.optimize import minimize

class EcoRouter:
    """
    Multi-objective route optimization: minimize energy AND time.

    Uses Pareto optimization to explore trade-off frontier.
    """

    def __init__(
        self,
        road_network: pd.DataFrame,
        battery_capacity_kwh: float = 75.0
    ):
        """
        Args:
            road_network: Graph edges with distance, elevation, speed_limit
            battery_capacity_kwh: Vehicle battery capacity
        """
        self.road_network = road_network
        self.battery_capacity = battery_capacity_kwh

    def compute_route_metrics(
        self,
        route: List[int],
        preference_weight: float = 0.5
    ) -> Tuple[float, float, float]:
        """
        Compute energy, time, and weighted score for route.

        Args:
            route: List of node IDs
            preference_weight: Weight for energy vs time (0=all time, 1=all energy)

        Returns:
            energy_kwh, time_hours, weighted_score
        """
        total_energy = 0
        total_time = 0

        for i in range(len(route) - 1):
            src, dst = route[i], route[i + 1]

            # Find edge
            edge = self.road_network[
                (self.road_network['src'] == src) &
                (self.road_network['dst'] == dst)
            ]

            if edge.empty:
                return float('inf'), float('inf'), float('inf')

            edge = edge.iloc[0]

            # Energy (simplified model)
            base_consumption = 18.0  # kWh per 100 km
            elevation_energy = max(0, edge['elevation_gain_m'] / 100)
            segment_energy = (
                base_consumption * edge['distance_km'] / 100 + elevation_energy
            )

            # Time
            segment_time = edge['distance_km'] / edge['speed_limit_kmh']

            total_energy += segment_energy
            total_time += segment_time

        # Weighted score (normalized)
        # Assuming typical trip: 50 km, 0.5 hours, 10 kWh
        energy_normalized = total_energy / 10
        time_normalized = total_time / 0.5

        weighted_score = (
            preference_weight * energy_normalized +
            (1 - preference_weight) * time_normalized
        )

        return total_energy, total_time, weighted_score

    def find_pareto_routes(
        self,
        start: int,
        end: int,
        candidate_routes: List[List[int]],
        n_pareto: int = 5
    ) -> pd.DataFrame:
        """
        Find Pareto-optimal routes (non-dominated solutions).

        Args:
            start: Start node
            end: End node
            candidate_routes: List of possible routes
            n_pareto: Number of Pareto solutions to return

        Returns:
            DataFrame with Pareto-optimal routes
        """
        results = []

        for route in candidate_routes:
            if route[0] != start or route[-1] != end:
                continue

            energy, time, _ = self.compute_route_metrics(route, preference_weight=0.5)

            if energy < float('inf'):
                results.append({
                    'route': route,
                    'energy_kwh': energy,
                    'time_hours': time
                })

        df = pd.DataFrame(results)

        # Find Pareto frontier (non-dominated solutions)
        is_pareto = np.ones(len(df), dtype=bool)

        for i in range(len(df)):
            for j in range(len(df)):
                if i == j:
                    continue

                # j dominates i if j is better in both objectives
                if (df.loc[j, 'energy_kwh'] <= df.loc[i, 'energy_kwh'] and
                    df.loc[j, 'time_hours'] <= df.loc[i, 'time_hours'] and
                    (df.loc[j, 'energy_kwh'] < df.loc[i, 'energy_kwh'] or
                     df.loc[j, 'time_hours'] < df.loc[i, 'time_hours'])):
                    is_pareto[i] = False
                    break

        pareto_df = df[is_pareto].sort_values('energy_kwh').head(n_pareto)

        return pareto_df


# Example usage
if __name__ == "__main__":
    # Sample road network
    road_network = pd.DataFrame({
        'src': [0, 0, 1, 1, 2],
        'dst': [1, 2, 3, 2, 3],
        'distance_km': [30, 40, 20, 15, 25],
        'elevation_gain_m': [100, 50, 200, 300, 100],
        'speed_limit_kmh': [80, 100, 60, 50, 80]
    })

    # Candidate routes (could be generated by routing algorithm)
    candidate_routes = [
        [0, 1, 3],  # Route A
        [0, 2, 3],  # Route B
        [0, 1, 2, 3]  # Route C
    ]

    router = EcoRouter(road_network)

    # Find Pareto-optimal routes
    pareto_routes = router.find_pareto_routes(
        start=0,
        end=3,
        candidate_routes=candidate_routes
    )

    print("Pareto-Optimal Routes:")
    print(pareto_routes[['energy_kwh', 'time_hours']])
```

## Production Deployment

```yaml
# Energy optimization pipeline
architecture:
  route_service:
    framework: FastAPI
    endpoints:
      - POST /api/v1/optimize-route (request: origin, destination, preferences)
      - GET /api/v1/charging-stations (params: location, radius)
    latency: <500ms p95

  optimization_engine:
    algorithm: DQN (pre-trained) + heuristic fallback
    model_storage: S3 / Azure Blob
    inference: CPU (sufficient for routing)

  charging_optimizer:
    algorithm: Linear programming (PuLP)
    trigger: Nightly batch (10 PM)
    runtime: <5 minutes for 100 vehicles

  data_sources:
    - Road network: OpenStreetMap + HERE Maps
    - Traffic: Real-time API (Google, TomTom)
    - Weather: OpenWeatherMap API
    - Charging stations: PlugShare, ChargePoint API
    - Electricity prices: Utility API

monitoring:
  metrics:
    - Route quality (energy savings vs baseline)
    - Prediction accuracy (estimated vs actual energy)
    - API latency
    - Model drift (consumption patterns change)

  alerts:
    - Prediction error > 20%
    - API latency > 1s
    - Charging optimizer failure
```

## Production Checklist

- [ ] Road network data updated (quarterly refresh)
- [ ] Traffic API integrated with fallback to historical averages
- [ ] Energy model calibrated on real vehicle data (R² > 0.85)
- [ ] Pareto routes validated by drivers (user study)
- [ ] Charging optimizer tested for feasibility (always finds solution)
- [ ] API rate limits configured (avoid external API overages)
- [ ] Model versioning in place (A/B test new algorithms)
- [ ] User preference storage (remember eco vs fast preference)
- [ ] Privacy compliance (location data anonymization)
- [ ] Offline mode (cache recent routes, fallback to heuristics)

---

## Fleet Analytics

# Fleet Analytics for Connected Vehicles

Build comprehensive analytics dashboards and KPI tracking for vehicle fleets. Focus on operational efficiency, cost optimization, and performance monitoring.

## Key Performance Indicators (KPIs)

### Vehicle Health
- **Average SOH**: Fleet-wide battery health
- **Maintenance Compliance**: % vehicles on schedule
- **Fault Rate**: Faults per 1000 km
- **Downtime**: Hours unavailable per vehicle per month

### Energy & Efficiency
- **Energy Efficiency**: kWh per 100 km (fleet average, by vehicle type)
- **Charging Efficiency**: % of energy delivered vs drawn from grid
- **Idle Time**: % time parked with systems active
- **Regenerative Braking**: % energy recovered

### Utilization
- **Fleet Utilization**: % time vehicles in use
- **Distance per Day**: Average km per vehicle per day
- **Trip Count**: Number of trips per vehicle per week
- **Occupancy Rate**: % trips with passengers (if applicable)

### Cost Metrics
- **Total Cost of Ownership (TCO)**: Per vehicle per year
- **Energy Cost**: $ per kWh charged
- **Maintenance Cost**: $ per km
- **Insurance Cost**: $ per vehicle per year

### Safety & Compliance
- **Incident Rate**: Incidents per million km
- **Driver Safety Score**: 0-100 composite score
- **Compliance Violations**: Speeding, harsh braking events
- **Recall Compliance**: % vehicles with open recalls addressed

## Dashboard Architecture

```python
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from typing import Dict, List
import streamlit as st
from datetime import datetime, timedelta

class FleetAnalyticsDashboard:
    """
    Comprehensive fleet analytics dashboard with real-time KPIs.

    Data sources:
    - Vehicle telemetry (PostgreSQL/TimescaleDB)
    - Maintenance records (ERP system)
    - Charging sessions (Charging management platform)
    - Driver profiles (Driver management system)
    """

    def __init__(self, db_connection):
        """
        Args:
            db_connection: Database connection object
        """
        self.db = db_connection

    def compute_fleet_kpis(
        self,
        start_date: datetime,
        end_date: datetime,
        vehicle_filter: List[str] = None
    ) -> Dict:
        """
        Compute all fleet-level KPIs for specified time range.

        Args:
            start_date: Start of analysis period
            end_date: End of analysis period
            vehicle_filter: Optional list of vehicle IDs to analyze

        Returns:
            Dictionary of KPIs
        """
        # Query vehicle data
        query = f"""
        SELECT
            vehicle_id,
            timestamp,
            odometer_km,
            soc,
            soh,
            energy_consumed_kwh,
            fault_codes,
            is_driving,
            driver_id
        FROM vehicle_telemetry
        WHERE timestamp BETWEEN '{start_date}' AND '{end_date}'
        """

        if vehicle_filter:
            query += f" AND vehicle_id IN ({','.join(map(repr, vehicle_filter))})"

        df = pd.read_sql(query, self.db)

        kpis = {}

        # Vehicle Health KPIs
        kpis['avg_soh'] = df.groupby('vehicle_id')['soh'].last().mean()
        kpis['soh_std'] = df.groupby('vehicle_id')['soh'].last().std()

        # Fault rate
        total_km = (
            df.groupby('vehicle_id')['odometer_km'].max() -
            df.groupby('vehicle_id')['odometer_km'].min()
        ).sum()

        fault_count = df['fault_codes'].notna().sum()
        kpis['fault_rate_per_1000km'] = (fault_count / total_km) * 1000 if total_km > 0 else 0

        # Energy efficiency
        total_energy = df['energy_consumed_kwh'].sum()
        kpis['fleet_efficiency_kwh_per_100km'] = (total_energy / total_km) * 100 if total_km > 0 else 0

        # Utilization
        total_hours = (end_date - start_date).total_seconds() / 3600
        driving_hours = df[df['is_driving']]['timestamp'].count() * (1/3600)  # Assuming 1 Hz data
        kpis['fleet_utilization_pct'] = (driving_hours / (total_hours * df['vehicle_id'].nunique())) * 100

        # Distance metrics
        n_vehicles = df['vehicle_id'].nunique()
        n_days = (end_date - start_date).days
        kpis['avg_km_per_vehicle_per_day'] = total_km / (n_vehicles * n_days) if n_days > 0 else 0

        # Cost metrics (assuming cost models)
        kpis['total_energy_cost_usd'] = total_energy * 0.12  # $0.12 per kWh
        kpis['energy_cost_per_km_usd'] = kpis['total_energy_cost_usd'] / total_km if total_km > 0 else 0

        return kpis

    def plot_soh_distribution(self, vehicle_data: pd.DataFrame) -> go.Figure:
        """
        Plot SOH distribution across fleet.

        Args:
            vehicle_data: DataFrame with columns: vehicle_id, soh
        """
        fig = go.Figure()

        # Histogram
        fig.add_trace(go.Histogram(
            x=vehicle_data['soh'],
            nbinsx=30,
            name='SOH Distribution',
            marker_color='steelblue'
        ))

        # Add threshold lines
        fig.add_vline(x=80, line_dash="dash", line_color="red",
                      annotation_text="EOL Threshold (80%)")
        fig.add_vline(x=90, line_dash="dash", line_color="orange",
                      annotation_text="Maintenance Alert (90%)")

        fig.update_layout(
            title='Fleet Battery SOH Distribution',
            xaxis_title='State of Health (%)',
            yaxis_title='Number of Vehicles',
            showlegend=False
        )

        return fig

    def plot_energy_efficiency_by_vehicle_type(
        self,
        vehicle_data: pd.DataFrame
    ) -> go.Figure:
        """
        Box plot of energy efficiency by vehicle type.

        Args:
            vehicle_data: Columns: vehicle_type, efficiency_kwh_per_100km
        """
        fig = px.box(
            vehicle_data,
            x='vehicle_type',
            y='efficiency_kwh_per_100km',
            color='vehicle_type',
            title='Energy Efficiency by Vehicle Type',
            labels={
                'efficiency_kwh_per_100km': 'Energy Efficiency (kWh/100km)',
                'vehicle_type': 'Vehicle Type'
            }
        )

        fig.update_layout(showlegend=False)
        return fig

    def plot_utilization_heatmap(
        self,
        usage_data: pd.DataFrame
    ) -> go.Figure:
        """
        Heatmap of fleet utilization by day and hour.

        Args:
            usage_data: Columns: timestamp, vehicle_id, is_driving
        """
        # Aggregate to hourly utilization
        usage_data['hour'] = usage_data['timestamp'].dt.hour
        usage_data['day_of_week'] = usage_data['timestamp'].dt.day_name()

        utilization = (
            usage_data.groupby(['day_of_week', 'hour'])['is_driving']
            .mean() * 100
        ).reset_index()

        # Pivot for heatmap
        pivot = utilization.pivot(index='day_of_week', columns='hour', values='is_driving')

        # Reorder days
        day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        pivot = pivot.reindex(day_order)

        fig = go.Figure(data=go.Heatmap(
            z=pivot.values,
            x=pivot.columns,
            y=pivot.index,
            colorscale='YlOrRd',
            colorbar=dict(title='Utilization %')
        ))

        fig.update_layout(
            title='Fleet Utilization by Day and Hour',
            xaxis_title='Hour of Day',
            yaxis_title='Day of Week'
        )

        return fig

    def plot_maintenance_cost_trend(
        self,
        maintenance_data: pd.DataFrame
    ) -> go.Figure:
        """
        Line plot of monthly maintenance costs.

        Args:
            maintenance_data: Columns: date, cost_usd, vehicle_id
        """
        # Aggregate to monthly
        monthly = (
            maintenance_data
            .groupby(pd.Grouper(key='date', freq='M'))['cost_usd']
            .agg(['sum', 'mean', 'count'])
            .reset_index()
        )

        fig = make_subplots(specs=[[{"secondary_y": True}]])

        # Total cost
        fig.add_trace(
            go.Bar(
                x=monthly['date'],
                y=monthly['sum'],
                name='Total Cost',
                marker_color='steelblue'
            ),
            secondary_y=False
        )

        # Average cost per vehicle
        fig.add_trace(
            go.Scatter(
                x=monthly['date'],
                y=monthly['mean'],
                name='Avg Cost per Vehicle',
                mode='lines+markers',
                marker_color='darkorange',
                line=dict(width=3)
            ),
            secondary_y=True
        )

        fig.update_layout(
            title='Monthly Maintenance Costs',
            xaxis_title='Month'
        )

        fig.update_yaxes(title_text='Total Cost ($)', secondary_y=False)
        fig.update_yaxes(title_text='Avg Cost per Vehicle ($)', secondary_y=True)

        return fig

    def plot_driver_safety_scores(
        self,
        driver_data: pd.DataFrame
    ) -> go.Figure:
        """
        Bar chart of driver safety scores with risk categories.

        Args:
            driver_data: Columns: driver_id, safety_score, risk_category
        """
        # Sort by safety score
        driver_data = driver_data.sort_values('safety_score', ascending=False)

        # Color mapping
        color_map = {
            'Low Risk': 'green',
            'Medium Risk': 'orange',
            'High Risk': 'red'
        }

        colors = driver_data['risk_category'].map(color_map)

        fig = go.Figure()

        fig.add_trace(go.Bar(
            x=driver_data['driver_id'],
            y=driver_data['safety_score'],
            marker_color=colors,
            text=driver_data['safety_score'].round(1),
            textposition='outside'
        ))

        fig.add_hline(y=70, line_dash="dash", line_color="red",
                      annotation_text="Retraining Threshold")

        fig.update_layout(
            title='Driver Safety Scores',
            xaxis_title='Driver ID',
            yaxis_title='Safety Score (0-100)',
            showlegend=False
        )

        return fig

    def generate_executive_summary(self, kpis: Dict) -> str:
        """
        Generate text summary of key findings.

        Args:
            kpis: Dictionary of computed KPIs

        Returns:
            Markdown-formatted summary
        """
        summary = f"""
## Fleet Executive Summary

### Vehicle Health
- **Average SOH**: {kpis['avg_soh']:.1f}% ± {kpis['soh_std']:.1f}%
- **Fault Rate**: {kpis['fault_rate_per_1000km']:.2f} faults per 1000 km

### Energy & Efficiency
- **Fleet Efficiency**: {kpis['fleet_efficiency_kwh_per_100km']:.2f} kWh per 100 km
- **Total Energy Cost**: ${kpis['total_energy_cost_usd']:.2f}
- **Cost per km**: ${kpis['energy_cost_per_km_usd']:.4f}

### Utilization
- **Fleet Utilization**: {kpis['fleet_utilization_pct']:.1f}%
- **Avg Distance**: {kpis['avg_km_per_vehicle_per_day']:.1f} km per vehicle per day

### Recommendations
"""

        # Add recommendations based on KPIs
        if kpis['avg_soh'] < 85:
            summary += "- **ACTION REQUIRED**: Fleet average SOH below 85%. Schedule battery assessments.\n"

        if kpis['fleet_utilization_pct'] < 50:
            summary += "- **OPTIMIZATION**: Fleet utilization below 50%. Consider fleet size optimization.\n"

        if kpis['fleet_efficiency_kwh_per_100km'] > 25:
            summary += "- **EFFICIENCY**: Energy efficiency above industry average. Investigate driver training needs.\n"

        return summary


# Streamlit Dashboard Application
def main():
    st.set_page_config(page_title="Fleet Analytics Dashboard", layout="wide")

    st.title("🚗 Fleet Analytics Dashboard")

    # Sidebar filters
    st.sidebar.header("Filters")
    date_range = st.sidebar.date_input(
        "Date Range",
        value=(datetime.now() - timedelta(days=30), datetime.now())
    )

    vehicle_types = st.sidebar.multiselect(
        "Vehicle Types",
        options=['Sedan', 'SUV', 'Van', 'Truck'],
        default=['Sedan', 'SUV']
    )

    # Initialize dashboard
    # db_connection = create_database_connection()  # Implement as needed
    # dashboard = FleetAnalyticsDashboard(db_connection)

    # Placeholder data for demo
    st.header("Key Performance Indicators")

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Avg SOH", "92.3%", delta="-1.2%")
    with col2:
        st.metric("Fleet Efficiency", "18.5 kWh/100km", delta="+0.3")
    with col3:
        st.metric("Utilization", "68%", delta="+5%")
    with col4:
        st.metric("Fault Rate", "2.1/1000km", delta="-0.5")

    # Charts
    st.header("Detailed Analytics")

    tab1, tab2, tab3, tab4 = st.tabs(
        ["Vehicle Health", "Energy & Efficiency", "Utilization", "Costs"]
    )

    with tab1:
        st.subheader("Battery SOH Distribution")
        # Sample data
        soh_data = pd.DataFrame({
            'vehicle_id': [f'V{i:03d}' for i in range(100)],
            'soh': np.random.normal(92, 5, 100).clip(70, 100)
        })
        # fig = dashboard.plot_soh_distribution(soh_data)
        # st.plotly_chart(fig, use_container_width=True)

    with tab2:
        st.subheader("Energy Efficiency by Vehicle Type")
        # Charts would go here

    with tab3:
        st.subheader("Fleet Utilization Heatmap")
        # Charts would go here

    with tab4:
        st.subheader("Maintenance Cost Trends")
        # Charts would go here


if __name__ == "__main__":
    main()
```

## Advanced Analytics: Clustering & Segmentation

```python
from sklearn.cluster import KMeans, DBSCAN
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

class FleetSegmentation:
    """
    Segment fleet vehicles into clusters based on usage patterns.

    Use cases:
    - Identify maintenance risk groups
    - Optimize charging schedules by usage pattern
    - Personalize driver training
    """

    def __init__(self, n_clusters: int = 5):
        """
        Args:
            n_clusters: Number of vehicle segments
        """
        self.n_clusters = n_clusters
        self.scaler = StandardScaler()
        self.kmeans = KMeans(n_clusters=n_clusters, random_state=42)
        self.pca = PCA(n_components=2)

    def engineer_clustering_features(
        self,
        vehicle_data: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Create features for clustering.

        Expected columns:
        - vehicle_id, total_km, avg_trip_distance_km, max_speed_kmh,
        - harsh_accel_rate, harsh_brake_rate, idle_time_pct,
        - energy_efficiency_kwh_per_100km, soh, age_days
        """
        features = pd.DataFrame()

        # Usage intensity
        features['total_km'] = vehicle_data['total_km']
        features['avg_trip_distance_km'] = vehicle_data['avg_trip_distance_km']

        # Driving style
        features['max_speed_kmh'] = vehicle_data['max_speed_kmh']
        features['harsh_accel_rate'] = vehicle_data['harsh_accel_rate']
        features['harsh_brake_rate'] = vehicle_data['harsh_brake_rate']
        features['idle_time_pct'] = vehicle_data['idle_time_pct']

        # Efficiency & health
        features['energy_efficiency'] = vehicle_data['energy_efficiency_kwh_per_100km']
        features['soh'] = vehicle_data['soh']

        # Age
        features['age_days'] = vehicle_data['age_days']

        return features

    def fit_predict(self, X: pd.DataFrame) -> np.ndarray:
        """
        Cluster vehicles and return cluster labels.

        Args:
            X: Feature matrix

        Returns:
            Cluster labels (0 to n_clusters-1)
        """
        # Normalize features
        X_scaled = self.scaler.fit_transform(X)

        # Cluster
        labels = self.kmeans.fit_predict(X_scaled)

        return labels

    def visualize_clusters(self, X: pd.DataFrame, labels: np.ndarray):
        """
        Visualize clusters in 2D using PCA.

        Args:
            X: Feature matrix
            labels: Cluster labels
        """
        # PCA for visualization
        X_scaled = self.scaler.transform(X)
        X_pca = self.pca.fit_transform(X_scaled)

        plt.figure(figsize=(10, 6))
        scatter = plt.scatter(
            X_pca[:, 0],
            X_pca[:, 1],
            c=labels,
            cmap='viridis',
            alpha=0.6,
            edgecolors='k'
        )
        plt.colorbar(scatter, label='Cluster')
        plt.xlabel(f'PC1 ({self.pca.explained_variance_ratio_[0]:.1%} variance)')
        plt.ylabel(f'PC2 ({self.pca.explained_variance_ratio_[1]:.1%} variance)')
        plt.title('Vehicle Fleet Segmentation (PCA Projection)')
        plt.tight_layout()
        plt.show()

    def describe_clusters(
        self,
        X: pd.DataFrame,
        labels: np.ndarray
    ) -> pd.DataFrame:
        """
        Describe each cluster with summary statistics.

        Returns:
            DataFrame with cluster profiles
        """
        X_with_labels = X.copy()
        X_with_labels['cluster'] = labels

        cluster_profiles = X_with_labels.groupby('cluster').agg([
            'mean', 'std', 'min', 'max', 'count'
        ])

        return cluster_profiles

    def assign_cluster_names(
        self,
        cluster_profiles: pd.DataFrame
    ) -> Dict[int, str]:
        """
        Assign interpretable names to clusters based on characteristics.

        Example logic:
        - High km + low SOH = "High Usage, Aging"
        - Low km + high SOH = "Light Usage, Healthy"
        - High harsh_accel + low efficiency = "Aggressive Drivers"
        """
        names = {}

        for cluster_id in cluster_profiles.index.get_level_values(0).unique():
            profile = cluster_profiles.loc[cluster_id]

            # Extract key metrics (using 'mean' aggregation)
            total_km = profile[('total_km', 'mean')]
            soh = profile[('soh', 'mean')]
            harsh_rate = profile[('harsh_accel_rate', 'mean')]
            efficiency = profile[('energy_efficiency', 'mean')]

            # Rule-based naming
            if total_km > 50000 and soh < 85:
                names[cluster_id] = "High Usage, Aging"
            elif total_km < 20000 and soh > 95:
                names[cluster_id] = "Light Usage, Healthy"
            elif harsh_rate > 5 and efficiency > 20:
                names[cluster_id] = "Aggressive Drivers"
            elif efficiency < 15 and soh > 90:
                names[cluster_id] = "Efficient, Well-Maintained"
            else:
                names[cluster_id] = f"Cluster {cluster_id}"

        return names


# Example usage
if __name__ == "__main__":
    # Load vehicle data
    vehicle_df = pd.read_csv('fleet_vehicle_profiles.csv')

    # Initialize segmentation
    segmenter = FleetSegmentation(n_clusters=5)

    # Engineer features
    X = segmenter.engineer_clustering_features(vehicle_df)

    # Cluster
    labels = segmenter.fit_predict(X)

    # Visualize
    segmenter.visualize_clusters(X, labels)

    # Describe clusters
    profiles = segmenter.describe_clusters(X, labels)
    print("\nCluster Profiles:")
    print(profiles)

    # Assign names
    names = segmenter.assign_cluster_names(profiles)
    print("\nCluster Names:")
    for cluster_id, name in names.items():
        print(f"  Cluster {cluster_id}: {name}")
```

## Real-Time Streaming Analytics

```python
from kafka import KafkaConsumer
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import json
from typing import Dict
import logging

logger = logging.getLogger(__name__)

class RealTimeFleetAnalytics:
    """
    Stream processing for real-time fleet analytics.

    Architecture:
    - Kafka: Ingest vehicle telemetry
    - Processing: Compute rolling KPIs
    - InfluxDB: Store time-series metrics
    - Grafana: Visualization
    """

    def __init__(
        self,
        kafka_brokers: list,
        kafka_topic: str,
        influx_url: str,
        influx_token: str,
        influx_org: str,
        influx_bucket: str
    ):
        """
        Args:
            kafka_brokers: List of Kafka broker addresses
            kafka_topic: Topic name for vehicle telemetry
            influx_url: InfluxDB server URL
            influx_token: InfluxDB authentication token
            influx_org: InfluxDB organization
            influx_bucket: InfluxDB bucket name
        """
        # Kafka consumer
        self.consumer = KafkaConsumer(
            kafka_topic,
            bootstrap_servers=kafka_brokers,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='latest',
            enable_auto_commit=True
        )

        # InfluxDB client
        self.influx_client = InfluxDBClient(
            url=influx_url,
            token=influx_token,
            org=influx_org
        )
        self.write_api = self.influx_client.write_api(write_options=SYNCHRONOUS)
        self.bucket = influx_bucket
        self.org = influx_org

        # State management (for rolling metrics)
        self.vehicle_states = {}

    def process_telemetry_message(self, message: Dict):
        """
        Process single telemetry message and compute metrics.

        Expected message format:
        {
            "vehicle_id": "V001",
            "timestamp": "2024-03-19T10:00:00Z",
            "odometer_km": 12345.6,
            "soc": 75,
            "soh": 92,
            "voltage": 400.5,
            "current": 150.2,
            "temperature": 35.0,
            "speed_kmh": 80,
            "is_driving": true
        }
        """
        vehicle_id = message['vehicle_id']
        timestamp = message['timestamp']

        # Update vehicle state
        if vehicle_id not in self.vehicle_states:
            self.vehicle_states[vehicle_id] = {
                'last_odometer': message['odometer_km'],
                'energy_consumed_kwh': 0,
                'trip_count': 0
            }

        state = self.vehicle_states[vehicle_id]

        # Compute derived metrics
        distance_delta = message['odometer_km'] - state['last_odometer']

        # Power consumption (simplified)
        power_kw = (message['voltage'] * message['current']) / 1000
        energy_delta_kwh = power_kw * (1 / 3600)  # Assuming 1 second interval

        state['energy_consumed_kwh'] += energy_delta_kwh
        state['last_odometer'] = message['odometer_km']

        # Trip detection
        if message['is_driving'] and not state.get('was_driving', False):
            state['trip_count'] += 1

        state['was_driving'] = message['is_driving']

        # Write metrics to InfluxDB
        self.write_vehicle_metrics(message, distance_delta, energy_delta_kwh)

    def write_vehicle_metrics(
        self,
        message: Dict,
        distance_delta: float,
        energy_delta: float
    ):
        """
        Write processed metrics to InfluxDB.
        """
        vehicle_id = message['vehicle_id']
        timestamp = message['timestamp']

        # Core telemetry
        point = Point("vehicle_telemetry") \
            .tag("vehicle_id", vehicle_id) \
            .field("soc", message['soc']) \
            .field("soh", message['soh']) \
            .field("voltage", message['voltage']) \
            .field("current", message['current']) \
            .field("temperature", message['temperature']) \
            .field("speed_kmh", message['speed_kmh']) \
            .time(timestamp)

        self.write_api.write(bucket=self.bucket, org=self.org, record=point)

        # Derived metrics
        if distance_delta > 0:
            efficiency_kwh_per_100km = (energy_delta / distance_delta) * 100

            point_derived = Point("vehicle_metrics") \
                .tag("vehicle_id", vehicle_id) \
                .field("energy_consumed_kwh", energy_delta) \
                .field("distance_km", distance_delta) \
                .field("efficiency_kwh_per_100km", efficiency_kwh_per_100km) \
                .time(timestamp)

            self.write_api.write(bucket=self.bucket, org=self.org, record=point_derived)

    def run(self):
        """
        Start consuming messages from Kafka and process in real-time.
        """
        logger.info("Starting real-time fleet analytics processor...")

        try:
            for message in self.consumer:
                try:
                    self.process_telemetry_message(message.value)
                except Exception as e:
                    logger.error(f"Error processing message: {e}")

        except KeyboardInterrupt:
            logger.info("Shutting down...")
        finally:
            self.consumer.close()
            self.influx_client.close()


# Example usage
if __name__ == "__main__":
    processor = RealTimeFleetAnalytics(
        kafka_brokers=['localhost:9092'],
        kafka_topic='vehicle-telemetry',
        influx_url='http://localhost:8086',
        influx_token='your-influx-token',
        influx_org='your-org',
        influx_bucket='fleet-analytics'
    )

    processor.run()
```

## Deployment Checklist

- [ ] Data pipeline validated (Kafka -> Processing -> Storage)
- [ ] Dashboard responsive (<2s load time)
- [ ] Real-time metrics update frequency configured (1-10s)
- [ ] Historical data retention policy defined
- [ ] Alert thresholds configured for critical KPIs
- [ ] User access controls implemented (RBAC)
- [ ] Dashboard mobile-responsive
- [ ] Export functionality (CSV, PDF reports)
- [ ] Scheduled reports automated (daily, weekly, monthly)
- [ ] Data quality monitoring (missing data, outliers)

---

## Predictive Maintenance

# Predictive Maintenance for Automotive Components

Predict component failures before they occur using supervised ML and survival analysis. Focus on battery SOH, tire wear, brake pad life, and electric motor degradation.

## Use Cases

1. **Battery State of Health (SOH)**: Predict remaining useful life, capacity fade, impedance rise
2. **Tire Wear**: Estimate tread depth, predict replacement needs
3. **Brake System**: Brake pad thickness, rotor wear, fluid degradation
4. **Electric Motor**: Bearing wear, insulation degradation, magnet demagnetization
5. **Cooling System**: Pump failure, radiator clogging, coolant degradation

## Problem Formulation

### Regression (Remaining Useful Life)
Predict time-to-failure or remaining capacity as continuous value.

**Algorithms**:
- Gradient Boosting (XGBoost, LightGBM, CatBoost)
- Random Forest
- LSTM/GRU for sequential degradation

### Classification (Failure within Window)
Predict if failure will occur in next N days/cycles.

**Algorithms**:
- Gradient Boosting Classifiers
- Logistic Regression (baseline)
- Neural Networks

### Survival Analysis (Time-to-Event)
Model probability of survival beyond time t, handling censored data.

**Algorithms**:
- Cox Proportional Hazards
- Random Survival Forests
- Deep survival models (DeepSurv)

## Battery SOH Prediction

### Feature Engineering

```python
import numpy as np
import pandas as pd
from scipy.stats import skew, kurtosis
from typing import Dict

class BatterySOHFeatureEngineer:
    """
    Extract features from battery charge/discharge cycles for SOH prediction.

    Features capture:
    - Capacity fade
    - Impedance rise
    - Charge acceptance degradation
    - Thermal behavior changes
    """

    @staticmethod
    def extract_cycle_features(
        cycle_data: pd.DataFrame,
        metadata: Dict
    ) -> Dict[str, float]:
        """
        Extract features from a single charge/discharge cycle.

        Expected columns:
        - timestamp, voltage, current, temperature, soc
        """
        features = {}

        # Metadata
        features['cycle_number'] = metadata['cycle_number']
        features['total_kwh_throughput'] = metadata['total_kwh_throughput']
        features['age_days'] = metadata['age_days']
        features['ambient_temp_avg'] = metadata.get('ambient_temp_avg', 25.0)

        # Capacity features
        charge_data = cycle_data[cycle_data['current'] > 0]
        discharge_data = cycle_data[cycle_data['current'] < 0]

        if len(charge_data) > 0:
            features['charge_capacity_ah'] = (
                charge_data['current'].sum() *
                (charge_data['timestamp'].diff().dt.total_seconds().mean() / 3600)
            )
            features['charge_duration_min'] = (
                (charge_data['timestamp'].max() - charge_data['timestamp'].min())
                .total_seconds() / 60
            )
        else:
            features['charge_capacity_ah'] = 0
            features['charge_duration_min'] = 0

        if len(discharge_data) > 0:
            features['discharge_capacity_ah'] = abs(
                discharge_data['current'].sum() *
                (discharge_data['timestamp'].diff().dt.total_seconds().mean() / 3600)
            )
            features['discharge_duration_min'] = (
                (discharge_data['timestamp'].max() - discharge_data['timestamp'].min())
                .total_seconds() / 60
            )
        else:
            features['discharge_capacity_ah'] = 0
            features['discharge_duration_min'] = 0

        # Coulombic efficiency
        if features['charge_capacity_ah'] > 0:
            features['coulombic_efficiency'] = (
                features['discharge_capacity_ah'] / features['charge_capacity_ah']
            )
        else:
            features['coulombic_efficiency'] = 1.0

        # Voltage features
        features['voltage_mean'] = cycle_data['voltage'].mean()
        features['voltage_std'] = cycle_data['voltage'].std()
        features['voltage_min'] = cycle_data['voltage'].min()
        features['voltage_max'] = cycle_data['voltage'].max()

        # dV/dSOC (charge acceptance indicator)
        if len(charge_data) > 10:
            soc_bins = pd.cut(charge_data['soc'], bins=10)
            voltage_per_soc = charge_data.groupby(soc_bins)['voltage'].mean()
            features['dv_dsoc_slope'] = np.polyfit(
                range(len(voltage_per_soc)),
                voltage_per_soc.values,
                1
            )[0]
        else:
            features['dv_dsoc_slope'] = 0

        # Impedance proxy (voltage drop at constant current)
        if len(discharge_data) > 100:
            # Find steady-state discharge region (SOC 80% -> 20%)
            steady_discharge = discharge_data[
                (discharge_data['soc'] >= 20) & (discharge_data['soc'] <= 80)
            ]
            if len(steady_discharge) > 10:
                # Impedance ~ voltage_drop / current
                current_mean = steady_discharge['current'].mean()
                voltage_drop_per_amp = steady_discharge['voltage'].std() / abs(current_mean)
                features['impedance_proxy'] = voltage_drop_per_amp
            else:
                features['impedance_proxy'] = 0
        else:
            features['impedance_proxy'] = 0

        # Thermal features
        features['temp_mean'] = cycle_data['temperature'].mean()
        features['temp_max'] = cycle_data['temperature'].max()
        features['temp_std'] = cycle_data['temperature'].std()
        features['temp_rise'] = (
            cycle_data['temperature'].max() - cycle_data['temperature'].min()
        )

        # Temperature-power correlation (thermal management quality)
        if len(cycle_data) > 10:
            power = cycle_data['voltage'] * cycle_data['current']
            temp_power_corr = cycle_data['temperature'].corr(power)
            features['temp_power_correlation'] = temp_power_corr
        else:
            features['temp_power_correlation'] = 0

        # Resting voltage (open-circuit voltage after rest period)
        # Indicates equilibrium state
        rest_data = cycle_data[abs(cycle_data['current']) < 1.0]  # <1A = rest
        if len(rest_data) > 5:
            features['rest_voltage'] = rest_data['voltage'].mean()
        else:
            features['rest_voltage'] = cycle_data['voltage'].mean()

        # Statistical features
        features['voltage_skewness'] = skew(cycle_data['voltage'])
        features['voltage_kurtosis'] = kurtosis(cycle_data['voltage'])

        return features

    @staticmethod
    def create_degradation_trends(
        cycle_features_df: pd.DataFrame,
        window: int = 10
    ) -> pd.DataFrame:
        """
        Create trend features from cycle history.

        Args:
            cycle_features_df: Features per cycle (sorted by cycle_number)
            window: Rolling window size for trend calculation
        """
        trends = cycle_features_df.copy()

        # Capacity fade rate
        trends['capacity_fade_rate'] = (
            -trends['discharge_capacity_ah']
            .rolling(window=window, min_periods=3)
            .apply(lambda x: np.polyfit(range(len(x)), x, 1)[0])
        )

        # Impedance rise rate
        trends['impedance_rise_rate'] = (
            trends['impedance_proxy']
            .rolling(window=window, min_periods=3)
            .apply(lambda x: np.polyfit(range(len(x)), x, 1)[0])
        )

        # Efficiency degradation
        trends['efficiency_decline_rate'] = (
            -trends['coulombic_efficiency']
            .rolling(window=window, min_periods=3)
            .apply(lambda x: np.polyfit(range(len(x)), x, 1)[0])
        )

        # Temperature increase trend (thermal management degradation)
        trends['temp_increase_rate'] = (
            trends['temp_mean']
            .rolling(window=window, min_periods=3)
            .apply(lambda x: np.polyfit(range(len(x)), x, 1)[0])
        )

        # Volatility features (increased variance = instability)
        trends['capacity_volatility'] = (
            trends['discharge_capacity_ah'].rolling(window=window).std()
        )

        return trends.fillna(0)


# Example usage
if __name__ == "__main__":
    # Load cycle data
    cycle_df = pd.read_parquet('battery_cycle_001.parquet')
    metadata = {
        'cycle_number': 1,
        'total_kwh_throughput': 120.5,
        'age_days': 45
    }

    engineer = BatterySOHFeatureEngineer()
    features = engineer.extract_cycle_features(cycle_df, metadata)

    print("Extracted features:")
    for key, value in features.items():
        print(f"  {key}: {value:.4f}")
```

### Model Implementation: Gradient Boosting

```python
import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from typing import Tuple
import joblib
import logging

logger = logging.getLogger(__name__)

class BatterySOHPredictor:
    """
    LightGBM-based State of Health predictor.

    Predicts:
    - Current SOH (0-100%)
    - Remaining useful cycles (until 80% SOH)
    - Capacity at next cycle
    """

    def __init__(self, model_params: dict = None):
        """
        Args:
            model_params: LightGBM hyperparameters
        """
        default_params = {
            'objective': 'regression',
            'metric': 'rmse',
            'boosting_type': 'gbdt',
            'num_leaves': 31,
            'learning_rate': 0.05,
            'feature_fraction': 0.8,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'max_depth': 6,
            'min_child_samples': 20,
            'verbosity': -1,
            'n_jobs': -1
        }
        self.params = model_params or default_params
        self.model = None
        self.feature_names = None

    def train(
        self,
        X: pd.DataFrame,
        y: np.ndarray,
        n_splits: int = 5,
        n_estimators: int = 500,
        early_stopping_rounds: int = 50
    ) -> dict:
        """
        Train SOH predictor with time-series cross-validation.

        Args:
            X: Feature matrix (cycle features)
            y: Target (SOH percentage, 0-100)
            n_splits: Number of CV splits
            n_estimators: Number of boosting rounds
            early_stopping_rounds: Early stopping patience

        Returns:
            Training metrics
        """
        self.feature_names = X.columns.tolist()

        # Time-series cross-validation (preserve temporal order)
        tscv = TimeSeriesSplit(n_splits=n_splits)

        cv_scores = []
        for fold, (train_idx, val_idx) in enumerate(tscv.split(X)):
            X_train, X_val = X.iloc[train_idx], X.iloc[val_idx]
            y_train, y_val = y[train_idx], y[val_idx]

            train_data = lgb.Dataset(X_train, label=y_train)
            val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

            model = lgb.train(
                self.params,
                train_data,
                num_boost_round=n_estimators,
                valid_sets=[val_data],
                valid_names=['val'],
                callbacks=[
                    lgb.early_stopping(early_stopping_rounds),
                    lgb.log_evaluation(period=0)  # Silent
                ]
            )

            # Evaluate
            y_pred = model.predict(X_val)
            mae = mean_absolute_error(y_val, y_pred)
            rmse = np.sqrt(mean_squared_error(y_val, y_pred))
            r2 = r2_score(y_val, y_pred)

            cv_scores.append({'mae': mae, 'rmse': rmse, 'r2': r2})
            logger.info(f"Fold {fold+1}: MAE={mae:.3f}, RMSE={rmse:.3f}, R2={r2:.3f}")

        # Train final model on full data
        full_data = lgb.Dataset(X, label=y)
        self.model = lgb.train(
            self.params,
            full_data,
            num_boost_round=n_estimators
        )

        # Aggregate CV metrics
        avg_metrics = {
            'mae': np.mean([s['mae'] for s in cv_scores]),
            'rmse': np.mean([s['rmse'] for s in cv_scores]),
            'r2': np.mean([s['r2'] for s in cv_scores]),
            'cv_scores': cv_scores
        }

        logger.info(f"Average CV MAE: {avg_metrics['mae']:.3f}%")
        logger.info(f"Average CV RMSE: {avg_metrics['rmse']:.3f}%")
        logger.info(f"Average CV R2: {avg_metrics['r2']:.3f}")

        return avg_metrics

    def predict(self, X: pd.DataFrame) -> np.ndarray:
        """
        Predict SOH for new samples.

        Returns:
            Predicted SOH values (0-100%)
        """
        if self.model is None:
            raise ValueError("Model must be trained before prediction")

        return self.model.predict(X)

    def predict_with_uncertainty(
        self,
        X: pd.DataFrame,
        n_iterations: int = 100
    ) -> Tuple[np.ndarray, np.ndarray]:
        """
        Predict with uncertainty estimation using dropout simulation.

        Returns:
            mean_predictions: Mean predicted SOH
            std_predictions: Standard deviation (uncertainty)
        """
        # LightGBM doesn't have native dropout, so we use bootstrapping
        predictions = []

        for _ in range(n_iterations):
            # Random feature subsample
            feature_fraction = self.params.get('feature_fraction', 0.8)
            n_features = int(len(X.columns) * feature_fraction)
            random_features = np.random.choice(
                X.columns,
                size=n_features,
                replace=False
            )

            pred = self.model.predict(X[random_features])
            predictions.append(pred)

        predictions = np.array(predictions)
        mean_pred = predictions.mean(axis=0)
        std_pred = predictions.std(axis=0)

        return mean_pred, std_pred

    def predict_remaining_cycles(
        self,
        X: pd.DataFrame,
        current_soh: np.ndarray,
        eol_threshold: float = 80.0
    ) -> np.ndarray:
        """
        Predict remaining useful cycles until end-of-life.

        Args:
            X: Current feature matrix
            current_soh: Current SOH values
            eol_threshold: End-of-life SOH threshold (default 80%)

        Returns:
            Estimated remaining cycles
        """
        # Estimate degradation rate from recent trend
        if 'capacity_fade_rate' in X.columns:
            fade_rates = X['capacity_fade_rate'].values
            # Prevent division by zero
            fade_rates = np.where(np.abs(fade_rates) < 1e-6, -0.1, fade_rates)

            # RUL = (current_soh - eol_threshold) / abs(fade_rate)
            rul = (current_soh - eol_threshold) / np.abs(fade_rates)

            # Clip to reasonable range [0, 5000]
            rul = np.clip(rul, 0, 5000)
        else:
            # Fallback: assume constant 0.05% fade per cycle
            rul = (current_soh - eol_threshold) / 0.05

        return rul

    def feature_importance(self, plot: bool = False) -> pd.DataFrame:
        """
        Get feature importance scores.

        Args:
            plot: If True, display bar plot

        Returns:
            DataFrame with feature names and importance scores
        """
        if self.model is None:
            raise ValueError("Model must be trained before feature importance")

        importance = self.model.feature_importance(importance_type='gain')
        importance_df = pd.DataFrame({
            'feature': self.feature_names,
            'importance': importance
        }).sort_values('importance', ascending=False)

        if plot:
            import matplotlib.pyplot as plt
            plt.figure(figsize=(10, 6))
            plt.barh(importance_df['feature'][:15], importance_df['importance'][:15])
            plt.xlabel('Importance (Gain)')
            plt.title('Top 15 Features for SOH Prediction')
            plt.gca().invert_yaxis()
            plt.tight_layout()
            plt.show()

        return importance_df

    def save(self, path: str):
        """Save trained model."""
        if self.model is None:
            raise ValueError("Cannot save untrained model")

        joblib.dump({
            'model': self.model,
            'params': self.params,
            'feature_names': self.feature_names
        }, path)
        logger.info(f"Model saved to {path}")

    @classmethod
    def load(cls, path: str) -> 'BatterySOHPredictor':
        """Load trained model."""
        data = joblib.load(path)
        predictor = cls(model_params=data['params'])
        predictor.model = data['model']
        predictor.feature_names = data['feature_names']
        logger.info(f"Model loaded from {path}")
        return predictor


# Example usage
if __name__ == "__main__":
    # Load preprocessed cycle features
    df = pd.read_parquet('battery_cycle_features.parquet')

    # Features and target
    feature_cols = [col for col in df.columns if col not in ['soh', 'battery_id']]
    X = df[feature_cols]
    y = df['soh'].values

    # Train predictor
    predictor = BatterySOHPredictor()
    metrics = predictor.train(X, y, n_splits=5)

    # Feature importance
    importance_df = predictor.feature_importance()
    print("\nTop 10 Most Important Features:")
    print(importance_df.head(10))

    # Save model
    predictor.save('battery_soh_predictor.pkl')

    # Predict with uncertainty
    X_test = X.iloc[-100:]
    mean_pred, std_pred = predictor.predict_with_uncertainty(X_test)

    print("\nPredictions with uncertainty:")
    for i in range(5):
        print(f"  Sample {i}: {mean_pred[i]:.2f}% +/- {std_pred[i]:.2f}%")

    # Remaining useful life
    rul = predictor.predict_remaining_cycles(X_test, mean_pred)
    print(f"\nEstimated RUL: {rul[:5]} cycles")
```

## LSTM for Sequential Degradation

```python
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import numpy as np
import pandas as pd

class BatterySequenceDataset(Dataset):
    """Dataset for multi-cycle battery sequences."""

    def __init__(
        self,
        sequences: np.ndarray,
        targets: np.ndarray,
        seq_len: int = 50
    ):
        """
        Args:
            sequences: (N, max_cycles, n_features) array
            targets: (N,) array of target SOH
            seq_len: Sequence length to use
        """
        self.sequences = torch.FloatTensor(sequences[:, -seq_len:, :])
        self.targets = torch.FloatTensor(targets)

    def __len__(self):
        return len(self.sequences)

    def __getitem__(self, idx):
        return self.sequences[idx], self.targets[idx]


class BatterySOHLSTM(nn.Module):
    """
    LSTM-based SOH predictor for sequential degradation modeling.

    Input: (batch, seq_len, n_features) - last N cycles
    Output: (batch,) - predicted SOH at next cycle
    """

    def __init__(
        self,
        n_features: int,
        hidden_dim: int = 64,
        n_layers: int = 2,
        dropout: float = 0.2
    ):
        super().__init__()

        self.lstm = nn.LSTM(
            input_size=n_features,
            hidden_size=hidden_dim,
            num_layers=n_layers,
            batch_first=True,
            dropout=dropout if n_layers > 1 else 0
        )

        self.fc = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(32, 1)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (batch, seq_len, n_features)
        lstm_out, (hidden, _) = self.lstm(x)

        # Use last hidden state
        out = self.fc(hidden[-1])  # (batch, 1)
        return out.squeeze()  # (batch,)


def train_lstm_predictor(
    train_sequences: np.ndarray,
    train_targets: np.ndarray,
    val_sequences: np.ndarray,
    val_targets: np.ndarray,
    n_features: int,
    epochs: int = 100,
    batch_size: int = 32,
    lr: float = 0.001
) -> BatterySOHLSTM:
    """
    Train LSTM SOH predictor.

    Args:
        train_sequences: (N_train, seq_len, n_features)
        train_targets: (N_train,) - SOH values
        val_sequences: (N_val, seq_len, n_features)
        val_targets: (N_val,)
        n_features: Number of input features
        epochs: Training epochs
        batch_size: Batch size
        lr: Learning rate

    Returns:
        Trained model
    """
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Create datasets
    train_dataset = BatterySequenceDataset(train_sequences, train_targets)
    val_dataset = BatterySequenceDataset(val_sequences, val_targets)

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size)

    # Model
    model = BatterySOHLSTM(n_features=n_features).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    criterion = nn.MSELoss()

    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0

    for epoch in range(epochs):
        # Training
        model.train()
        train_loss = 0
        for sequences, targets in train_loader:
            sequences = sequences.to(device)
            targets = targets.to(device)

            optimizer.zero_grad()
            outputs = model(sequences)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()

            train_loss += loss.item()

        train_loss /= len(train_loader)

        # Validation
        model.eval()
        val_loss = 0
        with torch.no_grad():
            for sequences, targets in val_loader:
                sequences = sequences.to(device)
                targets = targets.to(device)
                outputs = model(sequences)
                loss = criterion(outputs, targets)
                val_loss += loss.item()

        val_loss /= len(val_loader)

        if (epoch + 1) % 10 == 0:
            print(f"Epoch {epoch+1}/{epochs} - "
                  f"Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}")

        # Early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            patience_counter = 0
            best_model_state = model.state_dict()
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch+1}")
                break

    # Load best model
    model.load_state_dict(best_model_state)
    return model
```

## Tire Wear Prediction

```python
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
import numpy as np
import pandas as pd

class TireWearPredictor:
    """
    Predict tire tread depth based on usage patterns.

    Features:
    - Mileage
    - Driving style (acceleration, braking intensity)
    - Road conditions (highway vs city, temperature)
    - Tire pressure history
    - Load distribution
    """

    def __init__(self):
        self.model = RandomForestRegressor(
            n_estimators=200,
            max_depth=15,
            min_samples_split=10,
            random_state=42,
            n_jobs=-1
        )
        self.initial_tread_depth_mm = 8.0  # New tire

    def extract_features(self, vehicle_data: pd.DataFrame) -> pd.DataFrame:
        """
        Extract tire wear features from vehicle telemetry.

        Expected columns:
        - mileage, speed, acceleration, brake_pressure,
        - tire_pressure_fl, tire_pressure_fr, tire_pressure_rl, tire_pressure_rr,
        - ambient_temp, road_surface
        """
        features = pd.DataFrame()

        # Usage features
        features['total_mileage_km'] = vehicle_data['mileage']
        features['avg_speed_kmh'] = vehicle_data.groupby('vehicle_id')['speed'].transform('mean')

        # Driving style
        features['harsh_accel_count'] = (
            (vehicle_data['acceleration'] > 2.5)
            .groupby(vehicle_data['vehicle_id']).transform('sum')
        )
        features['harsh_brake_count'] = (
            (vehicle_data['brake_pressure'] > 0.7)
            .groupby(vehicle_data['vehicle_id']).transform('sum')
        )

        # Tire pressure (underinflation accelerates wear)
        tire_cols = ['tire_pressure_fl', 'tire_pressure_fr',
                     'tire_pressure_rl', 'tire_pressure_rr']
        features['avg_tire_pressure_bar'] = vehicle_data[tire_cols].mean(axis=1)
        features['tire_pressure_variance'] = vehicle_data[tire_cols].var(axis=1)

        # Underinflation events
        optimal_pressure = 2.5  # bar
        features['underinflation_events'] = (
            (vehicle_data[tire_cols] < optimal_pressure * 0.9).sum(axis=1)
            .groupby(vehicle_data['vehicle_id']).transform('sum')
        )

        # Environmental
        features['avg_temp_c'] = vehicle_data.groupby('vehicle_id')['ambient_temp'].transform('mean')

        # Road surface distribution
        if 'road_surface' in vehicle_data.columns:
            road_dummies = pd.get_dummies(vehicle_data['road_surface'], prefix='road')
            for col in road_dummies.columns:
                features[col] = road_dummies[col].groupby(vehicle_data['vehicle_id']).transform('mean')

        return features

    def train(self, X: pd.DataFrame, y: np.ndarray):
        """
        Train tire wear predictor.

        Args:
            X: Feature matrix
            y: Measured tread depth [mm]
        """
        X_train, X_val, y_train, y_val = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        self.model.fit(X_train, y_train)

        # Evaluate
        train_score = self.model.score(X_train, y_train)
        val_score = self.model.score(X_val, y_val)
        print(f"Training R2: {train_score:.3f}")
        print(f"Validation R2: {val_score:.3f}")

    def predict_tread_depth(self, X: pd.DataFrame) -> np.ndarray:
        """Predict current tread depth [mm]."""
        return self.model.predict(X)

    def predict_replacement_mileage(
        self,
        X: pd.DataFrame,
        current_mileage: np.ndarray,
        min_tread_depth_mm: float = 1.6
    ) -> np.ndarray:
        """
        Predict mileage at which tire should be replaced.

        Args:
            X: Current feature matrix
            current_mileage: Current vehicle mileage [km]
            min_tread_depth_mm: Legal minimum tread depth

        Returns:
            Estimated mileage at replacement [km]
        """
        current_tread = self.predict_tread_depth(X)

        # Estimate wear rate (mm per 1000 km)
        wear_so_far = self.initial_tread_depth_mm - current_tread
        wear_rate = wear_so_far / (current_mileage / 1000)

        # Remaining mileage
        remaining_tread = current_tread - min_tread_depth_mm
        remaining_mileage = (remaining_tread / wear_rate) * 1000

        replacement_mileage = current_mileage + remaining_mileage

        return replacement_mileage
```

## Deployment Architecture

```yaml
# Predictive maintenance pipeline
pipeline:
  data_ingestion:
    source: Vehicle telemetry stream (Kafka)
    frequency: Real-time for critical, daily batch for non-critical

  feature_engineering:
    engine: Apache Spark / Pandas
    caching: Redis (recent features)

  inference:
    model_serving: TensorFlow Serving / FastAPI
    latency: <100ms for real-time, <1h for batch

  output:
    storage: PostgreSQL (predictions) + Grafana dashboards
    alerts: PagerDuty / Slack for critical predictions
    recommendations: Maintenance scheduling system

monitoring:
  metrics:
    - Prediction accuracy (MAE, RMSE)
    - Model drift (feature distribution shift)
    - Alert precision/recall
    - Business KPIs (maintenance cost reduction, downtime)

  retraining:
    trigger: Performance degradation OR new failure modes
    frequency: Monthly for battery SOH, quarterly for tires
    validation: Holdout test set + field validation
```

## Production Checklist

- [ ] Training data spans full degradation lifecycle (0 -> EOL)
- [ ] Model validated on multiple battery/component types
- [ ] Feature engineering handles missing sensors gracefully
- [ ] Prediction confidence intervals calibrated
- [ ] Alert thresholds set based on cost-benefit analysis
- [ ] Integration with maintenance scheduling system tested
- [ ] Model versioning and rollback procedure in place
- [ ] Monitoring dashboards for prediction accuracy
- [ ] Retraining pipeline automated with data quality checks
- [ ] A/B testing framework for model updates

---

## Time Series Forecasting

# Time-Series Forecasting for Automotive Systems

Forecast battery degradation, energy consumption, and charging demand using specialized time-series models.

## Use Cases

1. **Battery Degradation Forecasting**: Predict SOH trajectory over 5-10 years
2. **Energy Consumption Prediction**: Forecast energy usage for route planning
3. **Charging Demand Forecasting**: Predict station load for grid management
4. **Range Estimation**: Predict remaining range under varying conditions
5. **Thermal Management**: Forecast cooling/heating needs

## Algorithm Selection

### Prophet (Meta)
**Best for**: Business forecasting with seasonality and holidays

**Pros**:
- Handles missing data and outliers
- Automatic seasonality detection
- Interpretable components (trend, weekly, yearly)
- Fast training

**Cons**:
- Assumes additive model structure
- Limited for multivariate forecasting

**Use cases**: Charging station demand, fleet energy consumption

### LSTM/GRU
**Best for**: Complex non-linear temporal dependencies

**Pros**:
- Captures long-term dependencies
- Handles multivariate inputs
- Flexible architecture

**Cons**:
- Requires large training data
- Slow to train
- Hyperparameter sensitive

**Use cases**: Battery SOH trajectory, multi-sensor degradation

### ARIMA/SARIMAX
**Best for**: Stationary time-series with clear seasonality

**Pros**:
- Statistical rigor
- Confidence intervals
- Interpretable parameters

**Cons**:
- Requires stationarity
- Struggles with non-linear patterns
- Manual order selection

**Use cases**: Short-term energy consumption, charging demand

### Temporal Fusion Transformer (TFT)
**Best for**: Multi-horizon forecasting with multiple covariates

**Pros**:
- State-of-the-art performance
- Attention mechanism for interpretability
- Handles static and dynamic features

**Cons**:
- Computationally expensive
- Requires significant data
- Complex implementation

**Use cases**: Long-term battery degradation, fleet-wide energy optimization

## Battery SOH Forecasting with Prophet

```python
from prophet import Prophet
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from typing import Tuple, Dict

class BatterySOHForecaster:
    """
    Forecast battery State of Health using Facebook Prophet.

    Models degradation as:
    - Trend: Long-term capacity fade
    - Seasonal: Usage patterns (daily, weekly)
    - Regressor: Temperature, charge cycles
    """

    def __init__(
        self,
        growth: str = 'linear',
        seasonality_mode: str = 'additive'
    ):
        """
        Args:
            growth: 'linear' or 'logistic' (for bounded degradation)
            seasonality_mode: 'additive' or 'multiplicative'
        """
        self.model = Prophet(
            growth=growth,
            seasonality_mode=seasonality_mode,
            yearly_seasonality=False,  # Not relevant for batteries
            weekly_seasonality=True,   # Usage patterns
            daily_seasonality=True,    # Charge cycles
            changepoint_prior_scale=0.05  # Flexibility of trend changes
        )
        self.trained = False

    def prepare_data(
        self,
        soh_history: pd.DataFrame,
        temperature_history: pd.DataFrame = None
    ) -> pd.DataFrame:
        """
        Prepare data for Prophet.

        Args:
            soh_history: Columns: timestamp, soh
            temperature_history: Columns: timestamp, avg_temp_c

        Returns:
            DataFrame with columns: ds (timestamp), y (SOH), temp (optional)
        """
        df = soh_history.rename(columns={'timestamp': 'ds', 'soh': 'y'})

        # Cap for logistic growth (max 100%, min 0%)
        df['cap'] = 100.0
        df['floor'] = 0.0

        # Add temperature as regressor
        if temperature_history is not None:
            temp_df = temperature_history.rename(columns={'timestamp': 'ds'})
            df = df.merge(temp_df, on='ds', how='left')
            df['avg_temp_c'] = df['avg_temp_c'].fillna(method='ffill')

        return df

    def fit(self, df: pd.DataFrame):
        """
        Train Prophet model.

        Args:
            df: Prepared DataFrame (ds, y, optional regressors)
        """
        # Add regressors if present
        if 'avg_temp_c' in df.columns:
            self.model.add_regressor('avg_temp_c', prior_scale=0.5)

        self.model.fit(df)
        self.trained = True
        print("Model trained successfully")

    def forecast(
        self,
        periods: int,
        freq: str = 'D',
        include_history: bool = True,
        temperature_forecast: pd.DataFrame = None
    ) -> pd.DataFrame:
        """
        Generate SOH forecast.

        Args:
            periods: Number of periods to forecast
            freq: Frequency ('D' for daily, 'H' for hourly)
            include_history: Include historical fit
            temperature_forecast: Future temperature values

        Returns:
            DataFrame with columns: ds, yhat (predicted SOH), yhat_lower, yhat_upper
        """
        if not self.trained:
            raise ValueError("Model must be trained before forecasting")

        # Create future dataframe
        future = self.model.make_future_dataframe(
            periods=periods,
            freq=freq,
            include_history=include_history
        )

        # Add cap/floor for logistic growth
        future['cap'] = 100.0
        future['floor'] = 0.0

        # Add temperature regressor
        if temperature_forecast is not None and 'avg_temp_c' in self.model.extra_regressors:
            temp_df = temperature_forecast.rename(columns={'timestamp': 'ds'})
            future = future.merge(temp_df, on='ds', how='left')
            # Forward fill missing values
            future['avg_temp_c'] = future['avg_temp_c'].fillna(method='ffill')

        # Forecast
        forecast = self.model.predict(future)

        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']]

    def plot_forecast(self, forecast: pd.DataFrame):
        """Plot forecast with components."""
        fig1 = self.model.plot(forecast)
        plt.title('Battery SOH Forecast')
        plt.ylabel('SOH (%)')
        plt.xlabel('Date')

        fig2 = self.model.plot_components(forecast)
        plt.show()

    def cross_validate(
        self,
        df: pd.DataFrame,
        initial: str = '365 days',
        period: str = '90 days',
        horizon: str = '180 days'
    ) -> pd.DataFrame:
        """
        Perform time-series cross-validation.

        Args:
            df: Training data
            initial: Initial training period
            period: Spacing between cutoff dates
            horizon: Forecast horizon

        Returns:
            DataFrame with CV results
        """
        from prophet.diagnostics import cross_validation, performance_metrics

        self.fit(df)

        df_cv = cross_validation(
            self.model,
            initial=initial,
            period=period,
            horizon=horizon
        )

        df_metrics = performance_metrics(df_cv)
        print("Cross-Validation Metrics:")
        print(df_metrics[['horizon', 'mse', 'rmse', 'mae', 'mape']].head())

        return df_cv


# Example usage
if __name__ == "__main__":
    # Load historical SOH data
    soh_df = pd.read_csv('battery_soh_history.csv', parse_dates=['timestamp'])

    # Optional: Load temperature data
    temp_df = pd.read_csv('temperature_history.csv', parse_dates=['timestamp'])

    # Initialize forecaster
    forecaster = BatterySOHForecaster(growth='logistic')

    # Prepare data
    train_df = forecaster.prepare_data(soh_df, temp_df)

    # Train
    forecaster.fit(train_df)

    # Forecast 365 days ahead
    forecast = forecaster.forecast(periods=365, freq='D')

    # Plot
    forecaster.plot_forecast(forecast)

    # Print key predictions
    future_forecast = forecast[forecast['ds'] > soh_df['timestamp'].max()]
    print("\nSOH Predictions (next 12 months):")
    print(future_forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].head(12))

    # Estimate EOL (80% SOH)
    eol_date = future_forecast[future_forecast['yhat'] <= 80.0]['ds'].iloc[0]
    print(f"\nEstimated End-of-Life Date (80% SOH): {eol_date}")
```

## LSTM for Multi-Variate Forecasting

```python
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import numpy as np
import pandas as pd
from typing import Tuple

class BatteryMultivariateDataset(Dataset):
    """
    Dataset for multivariate battery forecasting.

    Features: voltage, current, temperature, SOC
    Target: Future SOH
    """

    def __init__(
        self,
        data: np.ndarray,
        target: np.ndarray,
        seq_len: int = 100,
        pred_len: int = 10
    ):
        """
        Args:
            data: (N_samples, N_features) array
            target: (N_samples,) array (SOH)
            seq_len: Input sequence length
            pred_len: Prediction horizon
        """
        self.seq_len = seq_len
        self.pred_len = pred_len

        # Create sequences
        self.sequences = []
        self.targets = []

        for i in range(len(data) - seq_len - pred_len + 1):
            self.sequences.append(data[i:i+seq_len])
            self.targets.append(target[i+seq_len+pred_len-1])

        self.sequences = torch.FloatTensor(np.array(self.sequences))
        self.targets = torch.FloatTensor(np.array(self.targets))

    def __len__(self):
        return len(self.sequences)

    def __getitem__(self, idx):
        return self.sequences[idx], self.targets[idx]


class BatteryLSTMForecaster(nn.Module):
    """
    Multi-layer LSTM for battery SOH forecasting.

    Architecture:
    - Encoder LSTM: Process input sequence
    - Attention: Weight important time steps
    - Decoder: Generate future predictions
    """

    def __init__(
        self,
        n_features: int,
        hidden_dim: int = 128,
        n_layers: int = 3,
        dropout: float = 0.3
    ):
        super().__init__()

        self.n_features = n_features
        self.hidden_dim = hidden_dim

        # LSTM layers
        self.lstm = nn.LSTM(
            input_size=n_features,
            hidden_size=hidden_dim,
            num_layers=n_layers,
            batch_first=True,
            dropout=dropout
        )

        # Attention mechanism
        self.attention = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Linear(hidden_dim, 1)
        )

        # Output layer
        self.fc = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, 1)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (batch, seq_len, n_features)

        # LSTM encoding
        lstm_out, _ = self.lstm(x)
        # lstm_out: (batch, seq_len, hidden_dim)

        # Attention weights
        attention_weights = self.attention(lstm_out)
        # attention_weights: (batch, seq_len, 1)
        attention_weights = torch.softmax(attention_weights, dim=1)

        # Weighted sum
        context = torch.sum(lstm_out * attention_weights, dim=1)
        # context: (batch, hidden_dim)

        # Prediction
        out = self.fc(context)
        return out.squeeze()


def train_lstm_forecaster(
    train_data: np.ndarray,
    train_target: np.ndarray,
    val_data: np.ndarray,
    val_target: np.ndarray,
    n_features: int,
    seq_len: int = 100,
    pred_len: int = 10,
    epochs: int = 100,
    batch_size: int = 64,
    lr: float = 0.001
) -> BatteryLSTMForecaster:
    """
    Train LSTM forecaster.

    Args:
        train_data: Training features (N, n_features)
        train_target: Training SOH values (N,)
        val_data: Validation features
        val_target: Validation SOH values
        n_features: Number of input features
        seq_len: Input sequence length
        pred_len: Prediction horizon (time steps ahead)
        epochs: Training epochs
        batch_size: Batch size
        lr: Learning rate

    Returns:
        Trained model
    """
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Create datasets
    train_dataset = BatteryMultivariateDataset(
        train_data, train_target, seq_len, pred_len
    )
    val_dataset = BatteryMultivariateDataset(
        val_data, val_target, seq_len, pred_len
    )

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size)

    # Model
    model = BatteryLSTMForecaster(n_features=n_features).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    criterion = nn.MSELoss()

    best_val_loss = float('inf')
    patience = 15
    patience_counter = 0

    for epoch in range(epochs):
        # Training
        model.train()
        train_loss = 0
        for sequences, targets in train_loader:
            sequences = sequences.to(device)
            targets = targets.to(device)

            optimizer.zero_grad()
            outputs = model(sequences)
            loss = criterion(outputs, targets)
            loss.backward()

            # Gradient clipping
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)

            optimizer.step()
            train_loss += loss.item()

        train_loss /= len(train_loader)

        # Validation
        model.eval()
        val_loss = 0
        with torch.no_grad():
            for sequences, targets in val_loader:
                sequences = sequences.to(device)
                targets = targets.to(device)
                outputs = model(sequences)
                loss = criterion(outputs, targets)
                val_loss += loss.item()

        val_loss /= len(val_loader)

        if (epoch + 1) % 10 == 0:
            print(f"Epoch {epoch+1}/{epochs} - "
                  f"Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}")

        # Early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            patience_counter = 0
            best_model_state = model.state_dict()
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch+1}")
                break

    # Load best model
    model.load_state_dict(best_model_state)
    print(f"Best validation loss: {best_val_loss:.4f}")

    return model


def forecast_multi_step(
    model: BatteryLSTMForecaster,
    initial_sequence: np.ndarray,
    n_steps: int,
    device: str = 'cpu'
) -> np.ndarray:
    """
    Multi-step ahead forecasting with recursive prediction.

    Args:
        model: Trained LSTM model
        initial_sequence: (seq_len, n_features) - starting sequence
        n_steps: Number of steps to forecast ahead
        device: 'cpu' or 'cuda'

    Returns:
        Forecasted SOH values (n_steps,)
    """
    model.eval()
    model.to(device)

    predictions = []
    current_seq = torch.FloatTensor(initial_sequence).unsqueeze(0).to(device)
    # current_seq: (1, seq_len, n_features)

    with torch.no_grad():
        for _ in range(n_steps):
            # Predict next value
            pred = model(current_seq)
            predictions.append(pred.item())

            # Update sequence (shift left, add prediction)
            # Note: This assumes last feature is SOH. Adjust as needed.
            new_step = current_seq[0, -1, :].clone()
            new_step[-1] = pred  # Update SOH feature

            # Shift sequence
            current_seq = torch.cat([
                current_seq[:, 1:, :],
                new_step.unsqueeze(0).unsqueeze(0)
            ], dim=1)

    return np.array(predictions)
```

## Energy Consumption Forecasting

```python
from sklearn.ensemble import GradientBoostingRegressor
import numpy as np
import pandas as pd
from typing import Dict

class EnergyConsumptionForecaster:
    """
    Forecast vehicle energy consumption based on route and conditions.

    Features:
    - Route profile (distance, elevation change, road type)
    - Weather (temperature, wind, precipitation)
    - Traffic (congestion level, stop frequency)
    - Vehicle state (SOC, weight, tire pressure)
    - Driver behavior (historical consumption)
    """

    def __init__(self):
        self.model = GradientBoostingRegressor(
            n_estimators=200,
            learning_rate=0.05,
            max_depth=6,
            min_samples_split=20,
            random_state=42
        )

    def engineer_route_features(self, route_data: pd.DataFrame) -> pd.DataFrame:
        """
        Extract features from route data.

        Expected columns:
        - distance_km, elevation_gain_m, avg_speed_kmh,
        - road_type, ambient_temp_c, wind_speed_kmh,
        - traffic_level, stop_count
        """
        features = pd.DataFrame()

        # Route characteristics
        features['distance_km'] = route_data['distance_km']
        features['elevation_gain_m'] = route_data['elevation_gain_m']
        features['avg_speed_kmh'] = route_data['avg_speed_kmh']

        # Energy-relevant derived features
        features['elevation_per_km'] = (
            route_data['elevation_gain_m'] / (route_data['distance_km'] + 1e-3)
        )

        # Speed efficiency (most efficient around 60 km/h)
        features['speed_efficiency'] = np.exp(-((route_data['avg_speed_kmh'] - 60) / 30) ** 2)

        # Road type encoding
        if 'road_type' in route_data.columns:
            road_dummies = pd.get_dummies(route_data['road_type'], prefix='road')
            features = pd.concat([features, road_dummies], axis=1)

        # Weather impact
        features['ambient_temp_c'] = route_data['ambient_temp_c']
        features['temp_deviation_from_20'] = abs(route_data['ambient_temp_c'] - 20)
        features['wind_speed_kmh'] = route_data.get('wind_speed_kmh', 0)

        # Traffic impact
        features['traffic_level'] = route_data.get('traffic_level', 0)
        features['stops_per_km'] = (
            route_data.get('stop_count', 0) / (route_data['distance_km'] + 1e-3)
        )

        return features

    def train(self, X: pd.DataFrame, y: np.ndarray):
        """
        Train energy consumption model.

        Args:
            X: Feature matrix
            y: Energy consumed [kWh]
        """
        self.model.fit(X, y)
        score = self.model.score(X, y)
        print(f"Training R2: {score:.3f}")

    def predict_consumption(self, X: pd.DataFrame) -> np.ndarray:
        """
        Predict energy consumption for routes.

        Returns:
            Energy consumption [kWh]
        """
        return self.model.predict(X)

    def predict_range(
        self,
        route_features: pd.DataFrame,
        current_soc: float,
        battery_capacity_kwh: float
    ) -> Dict[str, float]:
        """
        Predict remaining range based on route profile.

        Args:
            route_features: Features for candidate routes
            current_soc: Current state of charge (0-100%)
            battery_capacity_kwh: Total battery capacity

        Returns:
            Dictionary with range estimates
        """
        # Available energy
        available_energy_kwh = (current_soc / 100) * battery_capacity_kwh

        # Predict consumption per route
        consumption_per_km = self.predict_consumption(route_features)

        # Range estimates
        estimated_range_km = available_energy_kwh / (consumption_per_km + 1e-6)

        return {
            'available_energy_kwh': available_energy_kwh,
            'estimated_consumption_kwh_per_km': consumption_per_km.mean(),
            'estimated_range_km': estimated_range_km.mean(),
            'range_uncertainty_km': estimated_range_km.std()
        }


# Example usage
if __name__ == "__main__":
    # Load historical trip data
    trips_df = pd.read_csv('historical_trips.csv')

    # Feature engineering
    forecaster = EnergyConsumptionForecaster()
    X = forecaster.engineer_route_features(trips_df)
    y = trips_df['energy_consumed_kwh'].values

    # Train
    forecaster.train(X, y)

    # Predict for new route
    new_route = pd.DataFrame([{
        'distance_km': 150,
        'elevation_gain_m': 500,
        'avg_speed_kmh': 80,
        'road_type': 'highway',
        'ambient_temp_c': 15,
        'wind_speed_kmh': 20,
        'traffic_level': 2,
        'stop_count': 5
    }])

    route_features = forecaster.engineer_route_features(new_route)
    range_estimate = forecaster.predict_range(
        route_features,
        current_soc=70,
        battery_capacity_kwh=75
    )

    print("\nRange Estimate:")
    for key, value in range_estimate.items():
        print(f"  {key}: {value:.2f}")
```

## Charging Demand Forecasting (SARIMAX)

```python
from statsmodels.tsa.statespace.sarimax import SARIMAX
import pandas as pd
import numpy as np
from typing import Tuple

class ChargingDemandForecaster:
    """
    Forecast charging station demand using SARIMAX.

    Captures:
    - Hourly seasonality (peak hours)
    - Weekly seasonality (weekday vs weekend)
    - Exogenous factors (weather, events)
    """

    def __init__(
        self,
        order: Tuple[int, int, int] = (1, 1, 1),
        seasonal_order: Tuple[int, int, int, int] = (1, 1, 1, 24)
    ):
        """
        Args:
            order: (p, d, q) for ARIMA
            seasonal_order: (P, D, Q, s) for seasonal component
                s=24 for hourly data with daily seasonality
        """
        self.order = order
        self.seasonal_order = seasonal_order
        self.model = None

    def fit(
        self,
        y: pd.Series,
        exog: pd.DataFrame = None
    ):
        """
        Fit SARIMAX model.

        Args:
            y: Time-series of charging demand (indexed by datetime)
            exog: Exogenous variables (temperature, events, etc.)
        """
        self.model = SARIMAX(
            y,
            exog=exog,
            order=self.order,
            seasonal_order=self.seasonal_order,
            enforce_stationarity=False,
            enforce_invertibility=False
        )

        self.results = self.model.fit(disp=False)
        print("Model fitted successfully")
        print(self.results.summary())

    def forecast(
        self,
        steps: int,
        exog: pd.DataFrame = None
    ) -> pd.DataFrame:
        """
        Forecast future demand.

        Args:
            steps: Number of steps ahead
            exog: Future exogenous variables

        Returns:
            DataFrame with forecast and confidence intervals
        """
        if self.model is None:
            raise ValueError("Model must be fitted before forecasting")

        forecast = self.results.get_forecast(steps=steps, exog=exog)
        forecast_df = forecast.summary_frame()

        return forecast_df.rename(columns={
            'mean': 'demand_forecast',
            'mean_ci_lower': 'lower_bound',
            'mean_ci_upper': 'upper_bound'
        })


# Example usage
if __name__ == "__main__":
    # Load hourly charging demand data
    demand_df = pd.read_csv('charging_demand.csv', parse_dates=['timestamp'])
    demand_df = demand_df.set_index('timestamp')

    # Exogenous variables
    exog_df = demand_df[['temperature_c', 'is_weekend', 'is_holiday']]
    y = demand_df['num_active_chargers']

    # Fit model
    forecaster = ChargingDemandForecaster(
        order=(1, 1, 1),
        seasonal_order=(1, 1, 1, 24)  # Daily seasonality
    )
    forecaster.fit(y, exog=exog_df)

    # Forecast next 48 hours
    future_exog = pd.DataFrame({
        'temperature_c': np.random.normal(20, 5, 48),
        'is_weekend': [0] * 24 + [1] * 24,
        'is_holiday': [0] * 48
    })

    forecast = forecaster.forecast(steps=48, exog=future_exog)
    print("\nDemand Forecast (next 48 hours):")
    print(forecast.head(12))
```

## Deployment Strategy

```yaml
# Time-series forecasting pipeline
pipeline:
  data_preparation:
    resampling: Hourly / Daily aggregation
    missing_data: Forward fill + interpolation
    outlier_handling: Median filter + IQR clipping

  feature_engineering:
    lag_features: [1, 7, 30] days
    rolling_statistics: Mean, std over [7, 30] day windows
    calendar_features: Hour, day_of_week, month, is_holiday

  model_training:
    framework: Prophet (quick) / LSTM (complex)
    validation: Time-series cross-validation
    hyperparameter_tuning: Bayesian optimization

  inference:
    frequency: Daily batch for long-term, real-time for short-term
    latency: <1s for API requests

  monitoring:
    metrics:
      - MAPE (Mean Absolute Percentage Error)
      - Coverage (% actual within confidence interval)
      - Forecast bias (systematic over/under prediction)

  retraining:
    trigger: MAPE > 10% OR weekly schedule
    validation: Backtest on last 90 days
```

## Production Checklist

- [ ] Historical data spans multiple seasons/years (if seasonal)
- [ ] Missing data strategy validated (forward fill, interpolation)
- [ ] Outliers identified and handled (capping, removal)
- [ ] Stationarity tested (ADF test) and differencing applied if needed
- [ ] Cross-validation on time-series splits (not random)
- [ ] Confidence intervals calibrated (90% coverage target)
- [ ] Model performance monitored (MAPE, coverage)
- [ ] Forecast horizon validated against business needs
- [ ] Retraining pipeline automated with data quality checks
- [ ] A/B testing for model updates (gradual rollout)
