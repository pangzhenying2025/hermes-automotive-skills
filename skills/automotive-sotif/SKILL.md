---
name: automotive-sotif
description: >
  Analysis of ML model and algorithm limitations including false positives/negatives, domain shift, adversarial inputs, and ODD boundary behavior. Covers 15 topics across sotif domain. Includes 15 skill files covering ASAM OpenDRIVE 1.7, ASAM OpenSCENARIO 2.0, GDPR (Data Privacy), ISO 11064 Ergonomics, ISO 19206 Road Vehicles Ultrasonic, ISO 21448 SOTIF, ISO 26262 Functional Safety, ISO 26262-3 (Hazard Analysis) and more.
tags: [acceptable-risk, acceptance-criteria, adas, adversarial-robustness, adversarial-testing, algorithm-insufficiency, area-1, area-2, area-3, area-4, automotive, automotive-sotif, autonomous-driving, camera, carla, concept-drift, continuous-improvement, corner-case-generation, corner-cases, coverage, coverage-metrics, database, degraded-conditions, disengagement-analysis, driver-monitoring, false-positives, field-monitoring, field-testing, fleet-data, fleet-monitoring, fmea, functional-insufficiency, functional-safety, hmi-design, human-baseline, human-factors, iso-21448, known-safe, known-unsafe, lidar, mileage-targets, misuse, mitigation, ml-safety, mode-confusion, model-verification, multi-sensor-fusion, nominal-scenarios, odd, odd-boundary, odd-exclusion, ood-detection, openscenario, ota-updates, out-of-distribution, overreliance, parameter-variation, perception, radar, requirements-validation, residual-risk, risk-evaluation, safety-case, scenario-analysis, scenario-catalog, scenario-testing, sensor-insufficiency, shadow-mode, simulation, simulation-testing, sotif, statistical-analysis, statistical-confidence, statistical-validation, stpa, takeover-request, test-generation, traceability, training-data, triggering-conditions, unknown-safe, unknown-unsafe, validation, validation-strategy, verification]
---

# Automotive Sotif

15 skill files covering sotif domain for automotive software engineering.

## Applicable Standards

- ASAM OpenDRIVE 1.7
- ASAM OpenSCENARIO 2.0
- GDPR (Data Privacy)
- ISO 11064 Ergonomics
- ISO 19206 Road Vehicles Ultrasonic
- ISO 21448 SOTIF
- ISO 26262 Functional Safety
- ISO 26262-3 (Hazard Analysis)
- ISO 26262-3 (Risk Assessment)
- ISO 26262-3 (Safety Goals)
- ISO 26262-4
- ISO 26262-4 (System Design)
- ISO 26262-4 (System Validation)
- ISO 26262-6 (Software Development)
- ISO 26262-6 (Software Validation)
- ISO 26262-8 (Supporting Processes)
- ISO 34502 Road Vehicle Test Scenarios
- ISO 34502 Road Vehicles Test Scenarios
- ISO 34502 Test Scenarios
- ISO/PAS 21448:2019
- ISO/TR 4804 Safety of AI
- ISO/TR 4804 Safety of AI in Road Vehicles
- NHTSA Driver Distraction Guidelines
- SAE J3016
- SAE J3016 Automation Levels
- UL 4600 Autonomous Systems
- UL 4600 Autonomous Systems Safety
- UN ECE R157 (ALKS Software Update)
- UN ECE R157 (ALKS)

## Use Cases

- ML model safety assurance for perception/planning
- False positive/negative analysis
- Out-of-distribution detection
- Adversarial robustness testing
- Domain adaptation validation
- Fleet data collection and analysis
- Disengagement pattern identification
- Near-miss event detection
- Continuous SOTIF improvement post-deployment
- Safety performance monitoring
- Reasonably foreseeable misuse identification
- Mode confusion analysis and mitigation
- Driver monitoring system requirements
- HMI design for SOTIF compliance
- Takeover request strategy development
- ODD nominal condition specification
- Requirements derivation for Area 1 operation
- Verification test plan for nominal scenarios
- Performance baseline establishment
- Type approval demonstration of intended functionality

## Topics Covered

### Functional Insufficiency

- sotif-algorithm-insufficiency
- sotif-sensor-insufficiency

### Functional Safety

- sotif-overview

### Human Factors

- sotif-human-factors

### Ml Safety

- sotif-ml-safety-assurance

### Risk Assessment

- sotif-risk-evaluation

### Scenario Analysis

- sotif-known-safe-scenarios
- sotif-known-unsafe-scenarios
- sotif-triggering-conditions
- sotif-unknown-safe-scenarios
- sotif-unknown-unsafe-scenarios

### Scenario Management

- sotif-scenario-catalog

### Validation

- sotif-field-monitoring
- sotif-simulation-testing
- sotif-validation-strategy

## Constraints

- Adversarial robustness vs accuracy tradeoff
- Cannot eliminate Area 4 (always residual uncertainty)
- Cannot eliminate all false positives/negatives
- Cannot eliminate all functional insufficiencies (physics limits sensors)
- Cannot eliminate all residual risk (physics, uncertainty)
- Cannot prevent all misuse (only mitigate reasonably foreseeable cases)
- Cannot prove Area 3 is empty (unknown unknowns by definition)
- Combinatorial explosion of parameter space
- Combined conditions grow exponentially (curse of dimensionality)
- Computational cost for billions of km
- Computational cost of exhaustive exploration
- Computational limits on model complexity
- Concept drift detection requires baseline data
- Data privacy regulations limit data collection
- Determining criticality threshold requires system-specific analysis

## Required Tools

- Accident database access (NHTSA FARS, GIDAS)
- Adversarial testing libraries
- Adversarial testing libraries (Foolbox, CleverHans)
- Bayesian inference frameworks
- Bayesian inference frameworks (PyMC3, Stan)
- Big data analytics (Spark, Python pandas)
- CARLA or SUMO (open-source) or VTD/IPG (commercial)
- Cloud computing for scale (AWS, Azure, GCP)
- Cloud data pipeline (Kafka, AWS Kinesis)
- Coverage analysis frameworks
- Data logging and analysis (MATLAB, Python pandas)
- Data management platforms
- Database management system
- Dataset management (Roboflow, Scale AI)
- Driving simulator for user studies


## Instructions

### sotif-algorithm-insufficiency

## Core Competencies

Expert in analyzing algorithm insufficiencies, particularly ML-based perception and planning algorithms, which are a major source of SOTIF hazards in modern ADAS/AD systems.

### Algorithm Insufficiency Types

**Classical Algorithms**:
- Lane detection: Failures on faded/missing markings, shadows, construction zones
- Object tracking: Track loss in occlusion, ID switches
- Path planning: Suboptimal routes, oscillations, local minima

**ML-Based Algorithms**:
- False negatives: Missed detections (pedestrian, vehicle, obstacle)
- False positives: Phantom objects (shadows, reflections)
- Misclassification: VRU misclassified as vehicle, vice versa
- Domain shift: Performance degradation on out-of-distribution data
- Adversarial vulnerability: Physical adversarial patches

### ML Model Failure Modes

**Training Data Insufficiency**:
- Underrepresented scenarios (rare edge cases)
- Geographic bias (trained on sunny California, tested in snowy Michigan)
- Temporal bias (trained on summer data, tested in winter)
- Sensor bias (trained on one camera model, deployed on another)

**Model Architecture Limitations**:
- Limited receptive field (cannot see distant small objects)
- Insufficient capacity (underfitting)
- Overfitting (memorizes training data, poor generalization)
- Computational constraints (latency, throughput)

**Out-of-Distribution (OOD) Data**:
- Novel object categories not in training data
- Unusual lighting conditions
- Extreme weather not represented in training
- Infrastructure variations (road markings, signs)

**Adversarial Examples**:
- Physical adversarial patches (fool object detector)
- Perturbations to sensor inputs
- Spoofing attacks (fake objects injected)

## False Positive/Negative Analysis

```python
import numpy as np
from sklearn.metrics import confusion_matrix, precision_recall_curve

class DetectionPerformanceAnalyzer:
"""Analyze false positive and false negative rates for object detection"""

def __init__(self, ground_truth, predictions, confidence_threshold=0.5):
"""
Parameters:
- ground_truth: List of ground truth bounding boxes
- predictions: List of predicted bounding boxes with confidence scores
- confidence_threshold: Confidence threshold for positive detection
"""
self.ground_truth = ground_truth
self.predictions = predictions
self.threshold = confidence_threshold


def calculate_metrics(self):
"""Calculate detection metrics"""
tp = 0  # True positives
fp = 0  # False positives
fn = 0  # False negatives

# Match predictions to ground truth (simplified IoU matching)
matched_gt = set()
for pred in self.predictions:
if pred['confidence'] < self.threshold:
continue
matched = False
for i, gt in enumerate(self.ground_truth):
if i in matched_gt:
continue
iou = self._calculate_iou(pred['bbox'], gt['bbox'])
if iou > 0.5:  # IoU threshold
tp += 1
matched_gt.add(i)
matched = True
break
if not matched:
fp += 1  # False positive

fn = len(self.ground_truth) - len(matched_gt)  # False negatives

precision = tp / (tp + fp) if (tp + fp) > 0 else 0
recall = tp / (tp + fn) if (tp + fn) > 0 else 0
f1_score = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

return {
"true_positives": tp,
"false_positives": fp,
"false_negatives": fn,
"precision": precision,
"recall": recall,
"f1_score": f1_score
}


def _calculate_iou(self, box1, box2):
"""Calculate Intersection over Union"""
x1_min, y1_min, x1_max, y1_max = box1
x2_min, y2_min, x2_max, y2_max = box2

inter_xmin = max(x1_min, x2_min)
inter_ymin = max(y1_min, y2_min)
inter_xmax = min(x1_max, x2_max)
inter_ymax = min(y1_max, y2_max)

inter_area = max(0, inter_xmax - inter_xmin) * max(0, inter_ymax - inter_ymin)
box1_area = (x1_max - x1_min) * (y1_max - y1_min)
box2_area = (x2_max - x2_min) * (y2_max - y2_min)
union_area = box1_area + box2_area - inter_area

return inter_area / union_area if union_area > 0 else 0


def analyze_fn_scenarios(self):
"""Analyze scenarios where false negatives occur"""
fn_scenarios = []
for i, gt in enumerate(self.ground_truth):
matched = any(
self._calculate_iou(pred['bbox'], gt['bbox']) > 0.5 and pred['confidence'] >= self.threshold
for pred in self.predictions
)
if not matched:
fn_scenarios.append({
"object_class": gt.get('class', 'unknown'),
"size": self._get_bbox_size(gt['bbox']),
"distance": gt.get('distance', 0),
"occlusion": gt.get('occlusion', 0)
})
return fn_scenarios


def _get_bbox_size(self, bbox):
"""Calculate bounding box area"""
x1, y1, x2, y2 = bbox
return (x2 - x1) * (y2 - y1)

# Example usage
ground_truth = [
{'bbox': [100, 150, 200, 300], 'class': 'pedestrian', 'distance': 50},
{'bbox': [500, 200, 600, 400], 'class': 'vehicle', 'distance': 30},
]

predictions = [
{'bbox': [105, 155, 205, 305], 'confidence': 0.85, 'class': 'pedestrian'},
# Missing vehicle detection (false negative)
]

analyzer = DetectionPerformanceAnalyzer(ground_truth, predictions)
metrics = analyzer.calculate_metrics()
print(f"Precision: {metrics['precision']:.2f}, Recall: {metrics['recall']:.2f}")
print(f"False negatives: {metrics['false_negatives']}")

fn_scenarios = analyzer.analyze_fn_scenarios()
for scenario in fn_scenarios:
print(f"FN: {scenario['object_class']} at {scenario['distance']}m, size {scenario['size']:.0f}px²")
```

## Out-of-Distribution (OOD) Detection

```python
import torch
import torch.nn as nn

class OODDetector:
"""Detect out-of-distribution inputs to perception model"""

def __init__(self, model, ood_threshold=0.8):
self.model = model
self.ood_threshold = ood_threshold


def detect_ood(self, input_data):
"""
Detect if input is OOD using maximum softmax probability

Low max probability indicates OOD (model uncertain)
"""
with torch.no_grad():
output = self.model(input_data)
probabilities = torch.softmax(output, dim=1)
max_prob, predicted_class = torch.max(probabilities, dim=1)

is_ood = max_prob < self.ood_threshold
return is_ood.item(), max_prob.item(), predicted_class.item()


def detect_ood_mahalanobis(self, input_data, class_means, class_covariance):
"""
Detect OOD using Mahalanobis distance (more robust than softmax)

Measures distance from input to nearest class distribution
"""
with torch.no_grad():
features = self.model.extract_features(input_data)

min_distance = float('inf')
for class_id, mean in class_means.items():
diff = features - mean
distance = torch.sqrt(diff @ torch.inverse(class_covariance) @ diff.T)
min_distance = min(min_distance, distance.item())

is_ood = min_distance > self.ood_threshold
return is_ood, min_distance

# Example usage
# model = load_perception_model()
# ood_detector = OODDetector(model, ood_threshold=0.75)
# is_ood, confidence, pred_class = ood_detector.detect_ood(camera_image)
# if is_ood:
#     print(f"Warning: OOD input detected, confidence {confidence:.2f}")
#     # Trigger fallback strategy or driver warning
```

## Adversarial Robustness Testing

```python
import torch
import torch.nn as nn

def generate_adversarial_example(model, input_image, true_label, epsilon=0.03):
"""
Generate adversarial example using FGSM (Fast Gradient Sign Method)

Parameters:
- model: Neural network model
- input_image: Clean input (torch tensor)
- true_label: Ground truth label
- epsilon: Perturbation magnitude

Returns:
- Adversarial image that fools the model
"""
input_image.requires_grad = True

# Forward pass
output = model(input_image)
loss = nn.CrossEntropyLoss()(output, true_label)

# Backward pass to get gradients
model.zero_grad()
loss.backward()

# Generate adversarial perturbation
perturbation = epsilon * input_image.grad.sign()
adversarial_image = input_image + perturbation

# Clip to valid image range [0, 1]
adversarial_image = torch.clamp(adversarial_image, 0, 1)

return adversarial_image


def test_adversarial_robustness(model, test_dataset, epsilon_values=[0.01, 0.03, 0.05]):
"""
Test model robustness against adversarial attacks
"""
results = {}
for epsilon in epsilon_values:
correct_clean = 0
correct_adversarial = 0

for image, label in test_dataset:
# Test on clean image
output_clean = model(image)
pred_clean = output_clean.argmax(dim=1)
correct_clean += (pred_clean == label).sum().item()

# Generate adversarial example
adv_image = generate_adversarial_example(model, image, label, epsilon)

# Test on adversarial image
output_adv = model(adv_image)
pred_adv = output_adv.argmax(dim=1)
correct_adversarial += (pred_adv == label).sum().item()

accuracy_clean = correct_clean / len(test_dataset)
accuracy_adversarial = correct_adversarial / len(test_dataset)

results[epsilon] = {
"clean_accuracy": accuracy_clean,
"adversarial_accuracy": accuracy_adversarial,
"accuracy_drop": accuracy_clean - accuracy_adversarial
}

return results
```

## Mitigation Strategies

**Training Data Enhancement**:
- Increase coverage of edge cases (rain, night, occlusion)
- Data augmentation (lighting, weather, sensor noise)
- Synthetic data generation (CARLA, Unity)
- Active learning (label high-uncertainty samples)

**Model Architecture**:
- Ensemble models (combine multiple models)
- Uncertainty quantification (Bayesian neural networks, dropout)
- Attention mechanisms (focus on relevant regions)
- Multi-task learning (joint detection + segmentation)

**Runtime Monitoring**:
- OOD detection (flag uncertain inputs)
- Prediction confidence thresholding
- Temporal consistency checks (track smoothness)
- Multi-sensor cross-validation

**Fallback Strategies**:
- Graceful degradation (reduce speed when confidence low)
- Fallback to classical algorithms (if ML fails)
- Driver warning and takeover request
- Minimal risk maneuver (if no driver response)

## Deliverables

- Algorithm performance specification (precision, recall, latency)
- False positive/negative analysis by scenario
- OOD detection strategy and thresholds
- Adversarial robustness test results
- Training data coverage analysis
- Runtime monitoring and fallback architecture

## Best Practices

- Test on diverse datasets (not just training distribution)
- Analyze failure modes by scenario (distance, lighting, occlusion)
- Implement uncertainty quantification (model should know when uncertain)
- Use multi-sensor fusion (reduce dependency on single algorithm)
- Continuous learning pipeline (update model with field data)
- Validate domain adaptation (test on target deployment region)
- Red team adversarial testing (dedicated team tries to fool system)

## Common Pitfalls

- Overfit to training data (poor generalization)
- Not testing on OOD data (deployed region different from training)
- Ignoring uncertainty (model overconfident on edge cases)
- No runtime monitoring (cannot detect degraded performance)
- Single model dependency (no redundancy)

### sotif-field-monitoring

## Core Competencies

Expert in post-deployment field monitoring for SOTIF, analyzing fleet data to discover unknown unsafe scenarios (Area 3), validate residual risk assumptions, and enable continuous safety improvement.

### Field Monitoring Objectives

**Primary Goals**:
- Discover new Area 3 scenarios (unknown unsafe) not identified during validation
- Validate residual risk assumptions from Area 4 analysis
- Monitor system performance degradation over time
- Identify emerging misuse patterns
- Support continuous improvement (software updates)

**Key Metrics**:
- Disengagement rate (safety driver takeovers per million km)
- Critical event rate (TTC < threshold, hard braking, lane departure)
- ODD exit frequency (how often system leaves operational domain)
- System availability (percentage of time system can operate)
- Misuse incidents (hands-off duration, eyes-off duration)

### Data Collection Architecture

**Event Data Recorder (EDR)**:
- Pre-crash data (5-10s before event)
- Crash data (accelerometer, airbag deployment)
- Post-crash data (2-3s after event)
- Mandatory in many jurisdictions (US, EU)

**Autonomous System Data Logger**:
- Sensor data (camera images, lidar point clouds, radar tracks)
- Perception outputs (object detections, classifications, tracks)
- Planning decisions (trajectory, speed, lane change intent)
- Control commands (steering, throttle, brake)
- System state (ODD status, warnings, disengagements)

**Triggering Conditions**:
- Disengagement (driver takeover)
- Near-miss (TTC < 2.5s, hard braking > 0.5g)
- ODD exit (system deactivation due to conditions)
- Sensor fault or degradation
- Misuse detection (driver monitoring alerts)

**Privacy Considerations**:
- Anonymize personally identifiable information (PII)
- Aggregate data before transmission (privacy-preserving)
- Comply with GDPR, CCPA (data protection regulations)
- User consent for data collection

### Fleet Data Analysis Pipeline

```python
import pandas as pd
import numpy as np
from sklearn.cluster import DBSCAN

class FleetDataAnalyzer:
"""Analyze fleet data to identify safety-critical patterns"""

def __init__(self, fleet_data_df):
"""
Parameters:
- fleet_data_df: DataFrame with columns [timestamp, vehicle_id, event_type,
ego_speed, ttc, weather, location, ...]
"""
self.data = fleet_data_df


def calculate_disengagement_rate(self):
"""
Calculate disengagement rate per million km
"""
total_km = self.data['distance_km'].sum()
num_disengagements = len(self.data[self.data['event_type'] == 'disengagement'])

rate = (num_disengagements / total_km) * 1e6  # per million km
return rate


def identify_near_miss_events(self, ttc_threshold=2.5):
"""
Extract near-miss events (TTC below threshold)
"""
near_misses = self.data[
(self.data['ttc'] < ttc_threshold) &
(self.data['ttc'] > 0)
]
return near_misses


def cluster_disengagement_scenarios(self):
"""
Use clustering to identify common disengagement patterns
"""
# Extract features for clustering
disengagements = self.data[self.data['event_type'] == 'disengagement']

features = disengagements[[
'ego_speed', 'ttc', 'road_curvature', 'weather_code', 'time_of_day'
]].values

# DBSCAN clustering
clustering = DBSCAN(eps=0.5, min_samples=5).fit(features)
disengagements['cluster'] = clustering.labels_

# Analyze clusters
cluster_summary = disengagements.groupby('cluster').agg({
'vehicle_id': 'count',
'ego_speed': 'mean',
'ttc': 'mean',
'weather_code': lambda x: x.mode()[0] if len(x) > 0 else None
})

return cluster_summary


def detect_performance_degradation(self, window_days=30):
"""
Detect if system performance is degrading over time
"""
self.data['date'] = pd.to_datetime(self.data['timestamp']).dt.date

# Calculate rolling disengagement rate
daily_stats = self.data.groupby('date').agg({
'event_type': lambda x: (x == 'disengagement').sum(),
'distance_km': 'sum'
})

daily_stats['disengagement_rate'] = (
daily_stats['event_type'] / daily_stats['distance_km']
) * 1e6

rolling_avg = daily_stats['disengagement_rate'].rolling(window=window_days).mean()

# Check for upward trend (degradation)
recent_avg = rolling_avg.iloc[-30:].mean()
baseline_avg = rolling_avg.iloc[:90].mean()

degradation = (recent_avg - baseline_avg) / baseline_avg

return {
"recent_avg": recent_avg,
"baseline_avg": baseline_avg,
"degradation_percent": degradation * 100
}


def analyze_odd_exits(self):
"""
Analyze reasons for ODD exits
"""
odd_exits = self.data[self.data['event_type'] == 'odd_exit']

exit_reasons = odd_exits['exit_reason'].value_counts()

return exit_reasons

# Example usage
fleet_data = pd.DataFrame({
'timestamp': pd.date_range('2026-01-01', periods=10000, freq='H'),
'vehicle_id': np.random.randint(1, 100, 10000),
'event_type': np.random.choice(['disengagement', 'near_miss', 'odd_exit', 'normal'],
10000, p=[0.01, 0.02, 0.05, 0.92]),
'distance_km': np.random.uniform(50, 200, 10000),
'ego_speed': np.random.uniform(60, 120, 10000),
'ttc': np.random.uniform(1, 10, 10000),
'road_curvature': np.random.uniform(0, 0.01, 10000),
'weather_code': np.random.choice([0, 1, 2], 10000),  # 0=clear, 1=rain, 2=fog
'time_of_day': np.random.uniform(0, 24, 10000),
'exit_reason': np.random.choice(['rain', 'fog', 'sensor_fault', 'none'], 10000)
})

analyzer = FleetDataAnalyzer(fleet_data)

disengage_rate = analyzer.calculate_disengagement_rate()
print(f"Disengagement rate: {disengage_rate:.2f} per million km")

near_misses = analyzer.identify_near_miss_events(ttc_threshold=2.5)
print(f"Near-miss events: {len(near_misses)}")

clusters = analyzer.cluster_disengagement_scenarios()
print(f"Disengagement clusters:\\n{clusters}")

degradation = analyzer.detect_performance_degradation()
print(f"Performance degradation: {degradation['degradation_percent']:.1f}%")
```

### Shadow Mode Testing

**Concept**:
- Deploy new software version in parallel with production version
- New version does not control vehicle (shadow mode)
- Compare decisions between versions
- Flag divergences for investigation

```python
class ShadowModeTester:
"""Compare production and shadow algorithm outputs"""

def __init__(self):
self.divergences = []


def compare_outputs(self, production_output, shadow_output, scenario):
"""
Compare production vs shadow decisions
"""
# Check for significant divergence
steering_diff = abs(production_output['steering_angle'] -
shadow_output['steering_angle'])
speed_diff = abs(production_output['target_speed'] -
shadow_output['target_speed'])

if steering_diff > 5.0 or speed_diff > 10.0:  # Thresholds
self.divergences.append({
'scenario': scenario,
'production': production_output,
'shadow': shadow_output,
'steering_diff': steering_diff,
'speed_diff': speed_diff
})


def get_divergence_report(self):
"""Generate report on divergences"""
return pd.DataFrame(self.divergences)
```

### Continuous Improvement Loop

**Process**:
1. **Monitor**: Collect fleet data, detect anomalies
2. **Analyze**: Identify new Area 3 scenarios, performance degradation
3. **Prioritize**: Risk assessment of discovered scenarios
4. **Mitigate**: Update software (algorithm, ODD, HMI)
5. **Validate**: Test updated software in simulation and limited field trial
6. **Deploy**: OTA software update to fleet
7. **Repeat**: Continue monitoring

**Software Update Safety**:
- Validation of updated software (simulation, proving ground)
- Phased rollout (10% fleet first, then 100%)
- Rollback capability if issues detected
- User notification of updates (UN ECE R157 requirement)

## Deliverables

- Field monitoring plan (data collection, triggering conditions, privacy)
- Fleet data analytics dashboard (disengagement rate, near-misses, ODD exits)
- Newly discovered Area 3 scenario reports
- Performance degradation analysis
- Continuous improvement process documentation
- Software update validation reports

## Best Practices

- Collect data on triggering events, not continuous (privacy, bandwidth)
- Anonymize data before transmission (GDPR compliance)
- Automate anomaly detection (cannot manually review all fleet data)
- Prioritize discovered scenarios by risk (severity × exposure)
- Close the loop: Feed field learnings back to scenario catalog
- Monitor not just failures, but also near-misses (leading indicators)
- Use shadow mode before deploying major updates
- Maintain rollback capability for software updates

## Regulatory Considerations

**UN ECE R157 (ALKS L3)**:
- Requires software update process with validation
- Fleet monitoring to detect performance degradation
- Event Data Recorder (EDR) for crash investigation

**GDPR (EU Data Protection)**:
- User consent for data collection
- Anonymization or pseudonymization of data
- Right to deletion (user can request data removal)

**NHTSA (US)**:
- Standing General Order on Crash Reporting (SGO 2021-01)
- Report crashes involving ADS within 24 hours

## Tools

- **Data pipeline**: Apache Kafka, AWS Kinesis for streaming data
- **Storage**: AWS S3, Azure Blob Storage for raw data
- **Analytics**: Python (pandas, scikit-learn), Spark for big data
- **Visualization**: Grafana, Tableau, custom dashboards
- **Anomaly detection**: ML frameworks (TensorFlow, PyTorch)

## Integration with SOTIF Process

1. **Field Monitoring** → Discover new Area 3 scenarios
2. **Area 3 Analysis** → Characterize scenario, determine root cause
3. **Mitigation Development** → Update software/ODD/HMI
4. **Validation** → Simulation + limited field test of update
5. **Deployment** → OTA update to fleet
6. **Continue Monitoring** → Validate mitigation effectiveness

## Common Pitfalls

- Not collecting enough data (insufficient triggering conditions)
- Collecting too much data (privacy concerns, bandwidth cost)
- No automated analysis (fleet data too large for manual review)
- Not closing the loop (learnings not fed back to development)
- Ignoring near-misses (only analyzing crashes is too late)
- No rollback plan for software updates

### sotif-human-factors

## Core Competencies

Expert in analyzing human factors that lead to SOTIF hazards, particularly reasonably foreseeable misuse of ADAS/AD systems due to mode confusion, overreliance, or HMI design flaws.

### Reasonably Foreseeable Misuse

**Definition**: Human behavior that is incorrect but predictable, not intentional abuse.

**Common Misuse Patterns**:
- Treating L2 system as L3 (hands-free, eyes-off)
- Using system outside ODD (wrong road type, weather)
- Ignoring warnings and takeover requests
- Overreliance on automation (reduced vigilance)
- Mode confusion (unaware of system state)
- Delayed takeover (insufficient readiness)

### Mode Confusion

**Types of Mode Confusion**:
- **Activation confusion**: Driver unaware system activated (unintended engagement)
- **Deactivation confusion**: Driver thinks system is active when it is not
- **Capability confusion**: Driver overestimates system capability (L2 treated as L3)
- **State confusion**: Driver uncertain of current system mode (active, standby, fault)

**Causes**:
- Ambiguous HMI state indication
- Silent mode transitions (no clear feedback)
- Similar appearance of L2 and L3 systems
- Gradual degradation without clear warnings

**Consequences**:
- Driver not monitoring road (when monitoring required)
- Driver intervening unnecessarily (false alarms)
- Delayed takeover (when system requests intervention)
- Using system outside ODD

### Overreliance on Automation

**Behavioral Adaptation**:
- **Complacency**: Reduced vigilance due to trust in automation
- **Skill degradation**: Manual driving skills atrophy
- **Automation bias**: Over-trusting system, ignoring contrary evidence
- **Out-of-the-loop unfamiliarity**: Loss of situation awareness

**Factors Increasing Overreliance**:
- High system reliability (fewer false alarms)
- Long duration of automated operation
- Engaging secondary tasks (phone, eating, reading)
- Marketing overstating system capability

**Mitigation**:
- Driver monitoring system (hands-on, gaze tracking)
- Escalating warnings for inattention
- Forced disengagement if no driver response
- Clear communication of system limitations

## Human Factors Analysis Methods

**Hierarchical Task Analysis (HTA)**:
- Decompose driving task into subtasks
- Identify points where driver can deviate from expected behavior
- Example: "Monitor system" → Driver may look at phone instead

**SHERPA (Systematic Human Error Reduction and Prediction Approach)**:
- For each task, identify potential errors:
- Action error (wrong action)
- Timing error (too early/late)
- Omission error (task not performed)
- Retrieval error (information not recalled)

**Cognitive Walkthrough**:
- Step through use cases from driver perspective
- Identify confusing interactions or ambiguous feedback

**Driving Simulator Studies**:
- Observe driver behavior with prototype system
- Measure takeover time, gaze patterns, secondary task engagement

## Driver Monitoring System (DMS) Requirements

```python
class DriverMonitoringSystem:
"""Monitor driver readiness for takeover"""

def __init__(self):
self.hands_on_threshold = 5.0  # seconds
self.eyes_off_threshold = 2.0  # seconds
self.warning_escalation_levels = [
{"duration": 5, "type": "visual"},
{"duration": 10, "type": "haptic"},
{"duration": 15, "type": "audible"},
{"duration": 30, "type": "minimal_risk_maneuver"}
]


def assess_driver_state(self, hands_on_wheel, gaze_on_road, head_pose):
"""
Assess driver readiness

Returns: (readiness_level, warning_type)
- readiness_level: 0 (not ready) to 5 (fully ready)
- warning_type: None, "visual", "haptic", "audible", "takeover"
"""
readiness = 5  # Start with full readiness

# Hands-off detection
if not hands_on_wheel:
hands_off_duration = self._get_hands_off_duration()
if hands_off_duration > self.hands_on_threshold:
readiness -= 2
warning = self._determine_warning_level(hands_off_duration)
return readiness, warning

# Gaze-off detection
if not gaze_on_road:
eyes_off_duration = self._get_eyes_off_duration()
if eyes_off_duration > self.eyes_off_threshold:
readiness -= 3
warning = self._determine_warning_level(eyes_off_duration)
return readiness, warning

# Head pose analysis (drowsiness detection)
if self._detect_drowsiness(head_pose):
readiness -= 2
return readiness, "audible"

return readiness, None


def _determine_warning_level(self, inattention_duration):
"""Escalating warnings based on duration"""
for level in self.warning_escalation_levels:
if inattention_duration <= level["duration"]:
return level["type"]
return "minimal_risk_maneuver"  # Last resort


def _get_hands_off_duration(self):
# Placeholder: Query sensor data
return 8.0  # Example: 8 seconds hands-off


def _get_eyes_off_duration(self):
# Placeholder: Query eye tracking camera
return 3.0  # Example: 3 seconds eyes-off


def _detect_drowsiness(self, head_pose):
# Placeholder: Analyze head nodding, eye closure
return False

# Example usage
dms = DriverMonitoringSystem()
hands_on = False  # Driver hands off wheel
gaze_on = True
head_pose = {"pitch": 0, "yaw": 0, "roll": 0}

readiness, warning = dms.assess_driver_state(hands_on, gaze_on, head_pose)
if readiness < 3:
print(f"Driver not ready for takeover! Issue {warning} warning.")
```

## HMI Design for SOTIF

**Principles**:
- **Clarity**: System state immediately obvious (color coding, icons)
- **Feedback**: Confirmation of mode changes (audible + visual)
- **Consistency**: Same HMI across all functions
- **Simplicity**: Minimize driver cognitive load
- **Redundancy**: Multi-modal feedback (visual + audible + haptic)

**State Indication**:
- **Active**: Green, continuous indicator, system controlling vehicle
- **Standby**: Amber, system available but not controlling
- **Unavailable**: Gray, ODD conditions not met
- **Fault**: Red, system failure, immediate takeover required
- **Takeover Request**: Flashing red, audible alert, haptic (seat vibration)

**Warning Escalation**:
1. Visual: Instrument cluster icon change
2. Haptic: Steering wheel vibration or seat vibration
3. Audible: Beep or voice message
4. Braking: Gentle deceleration to alert driver
5. MRM: Bring vehicle to controlled stop (no driver response)

**Example HMI State Machine**:

```
[System Off] --[Driver activates]--> [Standby]
[Standby] --[ODD conditions met]--> [Active]
[Active] --[ODD exit detected]--> [Takeover Request]
[Takeover Request] --[Driver takes over]--> [Standby]
[Takeover Request] --[No response 10s]--> [MRM]
[Active] --[Sensor fault]--> [Fault State]
```

## Takeover Request Strategy

**Lead Time Calculation**:
- Required: 5-10s for driver to regain situation awareness and act
- Factors: Driver attention level, scenario criticality, system confidence

```python
def calculate_takeover_lead_time(driver_readiness, scenario_criticality, system_confidence):
"""
Calculate required lead time for takeover request

Parameters:
- driver_readiness: 0-5 (0=not attentive, 5=fully attentive)
- scenario_criticality: 0-5 (0=low, 5=imminent hazard)
- system_confidence: 0-1 (model confidence in current action)

Returns:
- Required lead time in seconds
"""
base_lead_time = 5.0  # seconds

# Adjust for driver readiness (less ready = more time needed)
readiness_factor = (5 - driver_readiness) * 1.5

# Adjust for scenario criticality (more critical = less time available)
criticality_factor = -scenario_criticality * 0.5

# Adjust for system confidence (low confidence = request earlier)
confidence_factor = (1 - system_confidence) * 2.0

lead_time = base_lead_time + readiness_factor + criticality_factor + confidence_factor
lead_time = max(3.0, min(lead_time, 15.0))  # Clamp to [3, 15] seconds

return lead_time

# Example: Driver inattentive (readiness=2), low criticality scenario (1), high confidence (0.9)
lead_time = calculate_takeover_lead_time(driver_readiness=2, scenario_criticality=1, system_confidence=0.9)
print(f"Required takeover lead time: {lead_time:.1f} seconds")
```

## Deliverables

- Reasonably foreseeable misuse scenario catalog
- Mode confusion analysis and mitigation strategy
- Driver monitoring system requirements specification
- HMI design specification (state diagrams, visual mockups)
- Takeover request strategy (lead time, warning escalation)
- Driving simulator study results
- Traceability: Misuse scenario → Hazard → HMI mitigation

## Best Practices

- Conduct user studies early (driving simulator, wizard-of-oz)
- Test with diverse driver population (age, experience, cultural background)
- Use standardized methods (HTA, SHERPA) for systematic analysis
- Implement driver monitoring (don't rely on driver to self-monitor)
- Clear distinction in HMI between automation levels (L2 vs L3)
- Marketing and user manual must align with HMI (no overstated capability)
- Test takeover scenarios extensively (reaction time, success rate)
- Monitor field data for misuse patterns (update HMI if needed)

## Regulatory Considerations

**UN ECE R157 (ALKS L3)**:
- Requires driver monitoring system
- Minimum 4s takeover lead time
- Minimal risk maneuver if no driver response

**SAE J3016**:
- Defines automation levels and driver role
- L2: Driver must monitor continuously
- L3: System monitors, requests takeover
- L4: No driver intervention required in ODD

**NHTSA Driver Distraction Guidelines**:
- Visual-manual tasks should not exceed 2s glance time
- Total task time should not exceed 12s

## Integration with SOTIF Process

1. **Reasonably Foreseeable Misuse Analysis** → Identifies Area 2 scenarios
2. **HMI Design** → Mitigation strategy for misuse
3. **Driver Monitoring** → Runtime detection of misuse
4. **Validation** → Driving simulator studies, field testing

## Common Pitfalls

- Underestimating overreliance (drivers trust system too much)
- Ambiguous HMI (driver unsure of system state)
- Insufficient takeover lead time (driver cannot react in time)
- Not testing with real users (engineer assumptions vs actual behavior)
- Marketing overstates capability (creates false expectations)
- No monitoring of field data (misuse patterns not detected post-deployment)

### sotif-known-safe-scenarios

## Core Competencies

Expert in defining and verifying Area 1 (known safe) scenarios in ISO 21448 SOTIF framework — operating conditions where system performs intended function correctly without triggering hazards.

### Area 1 Definition

**Known Safe Scenarios**: Situations where:
- All parameters are within specified ODD
- Sensors provide sufficient data quality
- Algorithms perform as intended
- No reasonably foreseeable misuse
- Hazards are identified and properly controlled

**Purpose**:
- Define baseline for nominal system behavior
- Establish performance requirements
- Serve as reference for regression testing
- Demonstrate intended functionality for type approval

### Characteristics of Area 1

- **Well-understood**: Physics and behavior models validated
- **Measurable boundaries**: Clear thresholds for ODD parameters
- **Reproducible**: Scenarios can be reliably recreated in testing
- **Verifiable**: Pass/fail criteria can be objectively assessed
- **Traceable**: Linked to safety requirements and hazard analysis

## ODD Nominal Condition Specification

**Environmental Parameters**:
- Weather: Dry or light rain (< 5 mm/h), no fog, daylight
- Temperature: 0-40°C ambient
- Visibility: > 200m
- Road surface: Dry/wet asphalt, clean

**Infrastructure Parameters**:
- Lane markings: Standard width (10-15cm), contrast ratio > 5:1
- Road type: Highway, controlled access, no construction
- Curvature: Radius > 250m
- Slope: < 8%

**Traffic Parameters**:
- Speed: Within legal limits (e.g., 60-120 km/h for highway ADAS)
- Traffic density: Light to moderate (> 2s following distance available)
- Vehicle mix: Standard passenger cars and trucks

**System Parameters**:
- All sensors functional (no faults)
- Sensor cleanliness > 70% (no significant contamination)
- Computation load < 80% capacity
- Communication links active (V2X, cloud)

## Verification Approach

1. **Requirements Derivation**: Convert Area 1 conditions into testable requirements
2. **Test Scenario Generation**: Create representative test cases spanning ODD
3. **Acceptance Criteria**: Define performance metrics and thresholds
4. **Test Execution**: Simulation + proving ground + public road
5. **Statistical Validation**: Demonstrate performance meets criteria with confidence level

## Example: Adaptive Cruise Control (ACC)

**Area 1 Scenario Definition**:

| Parameter | Nominal Range | Acceptance Criteria |
|-----------|---------------|---------------------|
| Speed | 60-120 km/h | Maintain setpoint ±3 km/h |
| Following distance | 1.0-2.5s time gap | Maintain target gap ±0.2s |
| Target deceleration | -0.3g max | Jerk < 2 m/s³ (comfort) |
| Lane keeping | Center ±0.3m | Lateral deviation < 0.5m |
| Weather | Dry, daylight | Radar detection range > 150m |

**Test Scenarios**:
- Steady-state following (constant speed lead vehicle)
- Lead vehicle gentle deceleration (0.2g)
- Lead vehicle gentle acceleration (0.15g)
- Lane change with new lead vehicle (different speed)
- Curve negotiation (R=500m, 90 km/h)

**Verification Results**:
- 10,000 simulation runs with parameter variations
- 500 proving ground test runs
- 5,000 km public road validation
- Performance: 99.8% scenarios meet criteria (statistical confidence 99%)

## Test Case Generation

```python
import numpy as np
from dataclasses import dataclass

@dataclass
class Area1Scenario:
"""Known safe scenario for ACC function"""
ego_speed: float  # km/h
lead_speed: float  # km/h
following_distance: float  # meters
road_curvature: float  # 1/m
weather: str  # "dry", "wet"


def is_in_area1(self) -> bool:
"""Check if scenario parameters are within Area 1 (ODD nominal)"""
if not (60 <= self.ego_speed <= 120):
return False
if not (50 <= self.lead_speed <= 130):
return False
# Time gap check: 1-2.5s at ego speed
time_gap = self.following_distance / (self.ego_speed / 3.6)
if not (1.0 <= time_gap <= 2.5):
return False
if not (0 <= self.road_curvature <= 1/250):  # R > 250m
return False
if self.weather not in ["dry", "wet"]:
return False
return True


def generate_test_cases(num_samples: int) -> list:
"""Generate Monte Carlo samples in Area 1"""
scenarios = []
for _ in range(num_samples):
ego_speed = np.random.uniform(60, 120)
lead_speed = np.random.uniform(50, 130)
time_gap = np.random.uniform(1.0, 2.5)
following_distance = (ego_speed / 3.6) * time_gap
road_curvature = np.random.uniform(0, 1/250)
weather = np.random.choice(["dry", "wet"], p=[0.8, 0.2])


scenario = Area1Scenario(
ego_speed=ego_speed,
lead_speed=lead_speed,
following_distance=following_distance,
road_curvature=road_curvature,
weather=weather
)
if scenario.is_in_area1():
scenarios.append(scenario)
return scenarios

# Generate 1000 Area 1 test scenarios
test_cases = Area1Scenario.generate_test_cases(1000)
print(f"Generated {len(test_cases)} Area 1 test cases")
```

## Performance Metrics

**Functional Metrics**:
- Speed control accuracy: Mean error, standard deviation
- Following distance accuracy: Mean error, max deviation
- Lateral control: Lane center deviation, max lateral acceleration

**Comfort Metrics**:
- Longitudinal jerk: Max, mean, 95th percentile
- Lateral jerk: Max, mean, 95th percentile
- Acceleration/deceleration smoothness

**Safety Metrics**:
- Time-to-collision (TTC): Always > 3s
- Minimum following distance: Never < 10m at any speed
- Lane departure: Never > 0.5m from center

## Statistical Validation

**Hypothesis Testing**:
- Null hypothesis: System meets Area 1 performance criteria
- Confidence level: 99% (type approval requirement)
- Sample size calculation based on expected failure rate

**Example**:
- Performance requirement: 99.9% scenarios successful
- Confidence: 99%
- Required sample size: ~4600 test cases (binomial distribution)

## Deliverables

- Area 1 scenario specification with measurable parameters
- Test case database (parameterized scenarios in OpenSCENARIO)
- Verification test plan (simulation + proving ground + field)
- Performance requirement specification with acceptance criteria
- Test results report with statistical confidence analysis
- Traceability matrix: Area 1 scenarios → Safety requirements → Test cases

## Best Practices

- Define Area 1 boundaries conservatively (buffer from ODD limits)
- Use design of experiments (DOE) for efficient parameter space coverage
- Validate in all nominal conditions (not just most frequent)
- Include normal variability (sensor noise, actuator response time)
- Perform regression testing when system updated
- Monitor field performance to confirm Area 1 assumptions

## Integration with SOTIF Process

1. **ODD Definition** → Area 1 represents nominal conditions within ODD
2. **Known Safe Verification** → Demonstrates intended functionality works as specified
3. **Baseline for Comparison** → Area 2/3 analysis references Area 1 performance
4. **Requirements Validation** → Area 1 tests validate safety requirements correctness

## Relationship to ISO 26262

- ISO 26262: Focuses on failures (safety goals, ASIL decomposition)
- ISO 21448: Focuses on nominal performance (Area 1 verification)
- Complementary: Both needed for complete safety case
- Overlap: System-level safety requirements inform both Area 1 criteria and safety goals

## Common Pitfalls

- Defining Area 1 too broadly (includes edge cases that should be Area 2)
- Insufficient test coverage (missing parameter combinations)
- Overly optimistic acceptance criteria (not reflecting real-world variability)
- Not re-validating Area 1 after system updates
- Ignoring sensor degradation within nominal range (e.g., light rain)

### sotif-known-unsafe-scenarios

## Core Competencies

Expert in identifying Area 2 (known unsafe) scenarios in ISO 21448 SOTIF framework — conditions where functional insufficiency or reasonably foreseeable misuse leads to identified hazards.

### Area 2 Definition

**Known Unsafe Scenarios**: Situations where:
- Hazard has been identified through analysis or experience
- Root cause is functional insufficiency (not random failure)
- OR root cause is reasonably foreseeable misuse
- Scenario can be reproduced and characterized

**Sources**:
- Triggering condition analysis (STPA, FMEA, HAZOP)
- Accident database mining (NHTSA, GIDAS)
- Field testing and disengagement analysis
- Simulation-based corner case discovery
- Human factors analysis

### Functional Insufficiency Types

**Sensor Limitations**:
- Detection range insufficient for safe operation
- Resolution inadequate for object classification
- Field-of-view blind spots
- Performance degradation in adverse weather
- Sensitivity to environmental conditions (glare, reflection)

**Algorithm Limitations**:
- False negatives (missed detections)
- False positives (phantom objects)
- Classification errors (VRU misclassified)
- Trajectory prediction errors
- Reaction time insufficient for scenario

**Actuator Limitations**:
- Maximum deceleration insufficient
- Steering angle rate limiting
- Response time delays
- Degraded performance (brake fade, tire wear)

### Reasonably Foreseeable Misuse

**Mode Confusion**:
- Driver unaware system is active (unintended activation)
- Driver assumes higher capability than designed (L2 treated as L3)
- Driver confused by HMI state indication

**Overreliance**:
- Driver removes hands from wheel (L2 system)
- Driver not monitoring road (eyes-off, mind-off)
- Driver sleeping or reading
- Delayed response to takeover request

**Misunderstanding ODD**:
- Using system in weather outside ODD
- Operating on road types not supported
- Ignoring ODD exit warnings

## Systematic Identification Approach

**Step 1: Triggering Condition Sweep**
- Identify all triggering conditions (see sotif-triggering-conditions skill)
- Analyze system response for each condition
- Determine if response exposes hazard

**Step 2: Functional Insufficiency Analysis**
- For each subsystem (sensor, algorithm, actuator):
- What are performance limits?
- Under what conditions are limits exceeded?
- What hazard results from exceeding limit?

**Step 3: Misuse Scenario Analysis**
- Conduct task analysis: What can driver do wrong?
- Apply human factors methods (HTA, SHERPA)
- Identify credible misuse scenarios (not intentional abuse)

**Step 4: Accident Database Correlation**
- Review similar functions in accident databases
- Extract causal factors
- Map to functional insufficiencies or misuse

## Example: Lane Keeping Assist (LKA)

**Known Unsafe Scenario 1: Faded Lane Markings**

- **Triggering Condition**: Lane marking contrast < 3:1, curvature > 1/300m
- **Functional Insufficiency**: Camera cannot reliably detect lane
- **Hazard**: Unintended lane departure → collision with adjacent lane vehicle
- **Severity**: ASIL D (high-speed head-on crash risk)

**Mitigation**:
- Monitor lane marking quality (confidence metric)
- Fallback to GPS/map-based lane tracking
- Driver warning when quality insufficient
- Graceful degradation (reduce assist strength, not abrupt deactivation)

**Known Unsafe Scenario 2: Driver Hands-Off (Misuse)**

- **Triggering Condition**: Driver removes hands from wheel for > 15s
- **Misuse**: Driver treats L2 LKA as L3 (hands-free capable)
- **Hazard**: Delayed takeover when system requests intervention
- **Severity**: ASIL C (insufficient time to avoid hazard)

**Mitigation**:
- Driver monitoring system (hands-on detection, gaze tracking)
- Escalating warnings (visual → haptic → audible)
- System deactivation if no driver response (bring to controlled stop)
- HMI design clarifying L2 monitoring requirement

## Mitigation Strategies

**Design-Based Mitigation**:
- Multi-sensor redundancy (camera + radar + lidar)
- Robust algorithms (handle sensor noise, outliers)
- Conservative behavior (slower speeds, larger margins)
- Fail-operational architectures

**ODD Restriction**:
- Exclude conditions where insufficiency cannot be mitigated
- Example: LKA only available when lane marking quality sufficient

**Driver Interaction**:
- Clear HMI indicating system state and limitations
- Proactive warnings before hazardous condition
- Takeover request with sufficient lead time
- Driver readiness monitoring

**Graceful Degradation**:
- Reduce performance when approaching limits (speed reduction)
- Fallback strategies (sensor fusion, map-based navigation)
- Minimal Risk Condition (MRC) for L3+ systems

## Code Example: Known Unsafe Detection

```cpp
// LKA known unsafe scenario detection
class LKA_KnownUnsafeMonitor {
public:
enum class UnsafeScenario {
NONE,
FADED_LANE_MARKINGS,
SHARP_CURVE_SENSOR_LIMIT,
DRIVER_INATTENTION,
ADVERSE_WEATHER,
CONSTRUCTION_ZONE
};

UnsafeScenario detectKnownUnsafe(
const LaneMarkingQuality& lane_quality,
const RoadGeometry& geometry,
const DriverState& driver,
const WeatherCondition& weather) {


// Known Unsafe 1: Insufficient lane marking quality
if (lane_quality.confidence < 0.6 ||
lane_quality.contrast_ratio < 3.0) {
return UnsafeScenario::FADED_LANE_MARKINGS;
}

// Known Unsafe 2: Curvature exceeds sensor FOV
double curve_radius = 1.0 / geometry.curvature;
double lookahead_distance = calculateLookahead(geometry.ego_speed);
if (curve_radius < 300 && lookahead_distance > camera_fov_distance) {
return UnsafeScenario::SHARP_CURVE_SENSOR_LIMIT;
}

// Known Unsafe 3: Driver hands-off too long
if (driver.hands_off_duration > 15.0) {  // seconds
return UnsafeScenario::DRIVER_INATTENTION;
}

// Known Unsafe 4: Weather outside ODD
if (weather.rain_intensity > 10.0 ||  // mm/h
weather.visibility < 100.0) {      // meters
return UnsafeScenario::ADVERSE_WEATHER;
}

return UnsafeScenario::NONE;
}

void applyMitigation(UnsafeScenario scenario) {
switch (scenario) {
case UnsafeScenario::FADED_LANE_MARKINGS:
// Fallback to map-based lane tracking
enableMapBasedGuidance();
sendDriverWarning("Lane markings unclear, using map data");
break;

case UnsafeScenario::SHARP_CURVE_SENSOR_LIMIT:
// Reduce speed proactively
requestSpeedReduction(10);  // km/h
sendDriverWarning("Curve ahead, speed reduced");
break;

case UnsafeScenario::DRIVER_INATTENTION:
// Escalating warnings
sendDriverTakeoverRequest();
if (driver.hands_off_duration > 30.0) {
initiateMinimalRiskManeuver();
}
break;

case UnsafeScenario::ADVERSE_WEATHER:
// ODD exit: deactivate system
deactivateSystem();
sendDriverWarning("LKA unavailable: weather conditions");
break;

default:
break;
}
}
};
```

## Deliverables

- Known unsafe scenario catalog with root cause analysis
- Functional insufficiency analysis report (sensor, algorithm, actuator limits)
- Reasonably foreseeable misuse scenario list
- Mitigation strategy specification for each Area 2 scenario
- Safety requirements derived from Area 2 analysis
- ODD exclusion criteria (conditions moved outside ODD due to insufficiency)
- Traceability: Known unsafe scenario → Hazard → Mitigation → Verification test

## Best Practices

- Use multiple identification methods (STPA + accident analysis + field data)
- Quantify functional insufficiency (not just qualitative "camera fails in rain")
- Differentiate credible misuse from intentional abuse (focus on credible)
- For each known unsafe: attempt mitigation before ODD restriction
- Validate mitigation effectiveness through testing
- Re-analyze Area 2 after system design changes (may introduce new insufficiencies)
- Document rationale for ODD exclusions (why condition cannot be safely handled)

## Mitigation Priority

1. **Eliminate by design**: Change function/hardware to remove insufficiency
2. **Mitigate by redundancy**: Multi-sensor fusion, fallback strategies
3. **Warn and restrict**: Driver warnings, proactive degradation
4. **Exclude from ODD**: Refuse operation in condition (last resort)

## Integration with ISO 26262

- Known unsafe scenarios inform hazard analysis (HARA)
- Functional insufficiency → Safety requirement (functional safety concept)
- Mitigation strategies → Safety mechanisms (TSC, HSC)
- Area 2 verification → Safety validation testing

## Common Pitfalls

- Focusing only on sensor limits, ignoring algorithm/actuator insufficiencies
- Not considering combined insufficiencies (sensor + algorithm degradation)
- Underestimating reasonably foreseeable misuse (overreliance, mode confusion)
- Mitigation not validated under critical conditions
- ODD restrictions too narrow (non-viable commercial product)

### sotif-ml-safety-assurance

## Core Competencies

Expert in safety assurance for ML-based perception and planning in ADAS/AD systems, addressing unique SOTIF challenges of data-driven algorithms including training data coverage, out-of-distribution behavior, and concept drift.

### ML Safety Challenges for SOTIF

**Training Data Limitations**:
- Underrepresented scenarios (long-tail distribution)
- Geographic bias (trained on California, deployed in Michigan)
- Temporal bias (summer data only, tested in winter)
- Annotation errors (ground truth inaccuracies)
- Sensor bias (training sensor vs deployment sensor mismatch)

**Model Behavior Uncertainty**:
- Out-of-distribution (OOD) inputs (novel scenarios not in training)
- Adversarial vulnerability (physical adversarial patches)
- False positives and false negatives (algorithm insufficiency)
- Overconfidence (high softmax probability on wrong prediction)
- Lack of interpretability (black-box decision-making)

**Deployment Challenges**:
- Concept drift (real-world distribution shifts over time)
- Performance degradation (sensor degradation, environmental changes)
- Continuous learning risks (updating model may introduce new failures)
- Verification complexity (billions of potential inputs)

### Training Data Quality Assurance

**Coverage Analysis**:

```python
import numpy as np
import pandas as pd
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt

class TrainingDataCoverageAnalyzer:
"""Analyze training data coverage for SOTIF"""

def __init__(self, training_data, validation_data):
"""
Parameters:
- training_data: Features from training dataset
- validation_data: Features from validation/deployment dataset
"""
self.training_data = training_data
self.validation_data = validation_data


def visualize_coverage(self):
"""
Visualize training vs validation data in feature space using PCA
"""
# Reduce to 2D for visualization
pca = PCA(n_components=2)
training_2d = pca.fit_transform(self.training_data)
validation_2d = pca.transform(self.validation_data)

plt.figure(figsize=(10, 6))
plt.scatter(training_2d[:, 0], training_2d[:, 1], alpha=0.5, label='Training', s=10)
plt.scatter(validation_2d[:, 0], validation_2d[:, 1], alpha=0.5, label='Validation', s=10)
plt.xlabel('PC1')
plt.ylabel('PC2')
plt.legend()
plt.title('Training Data Coverage')
plt.show()


def calculate_novelty_score(self):
"""
Calculate novelty score for validation data (distance from training distribution)
"""
from sklearn.neighbors import NearestNeighbors

# Fit nearest neighbor model on training data
nn = NearestNeighbors(n_neighbors=5)
nn.fit(self.training_data)

# Calculate distance to nearest training sample for each validation sample
distances, _ = nn.kneighbors(self.validation_data)
novelty_scores = distances.mean(axis=1)

return novelty_scores


def identify_underrepresented_scenarios(self, scenario_labels_training,
scenario_labels_validation):
"""
Identify scenario categories underrepresented in training data
"""
training_dist = pd.Series(scenario_labels_training).value_counts(normalize=True)
validation_dist = pd.Series(scenario_labels_validation).value_counts(normalize=True)

# Calculate coverage gap
gap = validation_dist - training_dist.reindex(validation_dist.index, fill_value=0)

underrepresented = gap[gap > 0.05].sort_values(ascending=False)  # 5% threshold

return underrepresented

# Example usage
# Assume features extracted from sensor data (e.g., scene embeddings)
training_features = np.random.randn(10000, 128)  # 10k training samples, 128-dim features
validation_features = np.random.randn(1000, 128) + 0.5  # Slight distribution shift

analyzer = TrainingDataCoverageAnalyzer(training_features, validation_features)

novelty_scores = analyzer.calculate_novelty_score()
print(f"Validation samples with high novelty (OOD): {(novelty_scores > 2.0).sum()}")
```

**Data Quality Metrics**:
- Annotation accuracy (inter-annotator agreement, Kappa score)
- Scenario diversity (coverage of ODD parameter space)
- Long-tail representation (rare but critical scenarios)
- Sensor quality (resolution, noise, artifacts)
- Temporal coverage (time of day, season, weather)

### Model Verification and Validation

**Test Set Curation**:
- OOD test set (scenarios outside training distribution)
- Corner case test set (challenging scenarios discovered through SOTIF analysis)
- Regression test set (ensure updates don't break existing performance)
- Cross-domain test set (different geographic regions, sensors)

**Performance Metrics**:
- Precision, Recall, F1-score (object detection)
- Mean Average Precision (mAP) at IoU thresholds
- False positive rate (critical for SOTIF — phantom objects cause braking)
- False negative rate (critical for safety — missed objects cause collisions)
- Calibration error (does confidence reflect true probability?)

**Verification Testing**:

```python
import torch
import torch.nn as nn

class MLModelVerifier:
"""Verify ML model for SOTIF compliance"""

def __init__(self, model, test_dataset):
self.model = model
self.test_dataset = test_dataset


def evaluate_performance(self):
"""
Evaluate model on test dataset
"""
self.model.eval()
total_correct = 0
total_samples = 0
false_positives = 0
false_negatives = 0

with torch.no_grad():
for inputs, labels in self.test_dataset:
outputs = self.model(inputs)
predictions = outputs.argmax(dim=1)

total_correct += (predictions == labels).sum().item()
total_samples += labels.size(0)

# FP/FN analysis (assuming binary classification for simplicity)
false_positives += ((predictions == 1) & (labels == 0)).sum().item()
false_negatives += ((predictions == 0) & (labels == 1)).sum().item()

accuracy = total_correct / total_samples
fp_rate = false_positives / total_samples
fn_rate = false_negatives / total_samples

return {
"accuracy": accuracy,
"false_positive_rate": fp_rate,
"false_negative_rate": fn_rate
}


def test_adversarial_robustness(self, epsilon=0.03):
"""
Test model robustness to adversarial perturbations
"""
from torchattacks import FGSM

attack = FGSM(self.model, eps=epsilon)
total_samples = 0
adversarial_failures = 0

for inputs, labels in self.test_dataset:
adv_inputs = attack(inputs, labels)
outputs = self.model(adv_inputs)
predictions = outputs.argmax(dim=1)

adversarial_failures += (predictions != labels).sum().item()
total_samples += labels.size(0)

robustness = 1 - (adversarial_failures / total_samples)
return robustness


def measure_uncertainty(self):
"""
Measure model uncertainty using dropout Monte Carlo
"""
self.model.train()  # Enable dropout
num_samples = 20
uncertainties = []

for inputs, labels in self.test_dataset:
predictions = []

# Multiple forward passes with dropout
for _ in range(num_samples):
with torch.no_grad():
outputs = self.model(inputs)
probabilities = torch.softmax(outputs, dim=1)
predictions.append(probabilities)

# Calculate variance (uncertainty)
predictions = torch.stack(predictions)
uncertainty = predictions.var(dim=0).mean(dim=1)
uncertainties.extend(uncertainty.tolist())

return uncertainties
```

### Runtime Monitoring

**OOD Detection**:

```python
class RuntimeOODMonitor:
"""Detect out-of-distribution inputs at runtime"""

def __init__(self, model, training_statistics):
"""
Parameters:
- training_statistics: Mean and covariance of training feature distribution
"""
self.model = model
self.training_mean = training_statistics['mean']
self.training_cov = training_statistics['covariance']


def detect_ood_mahalanobis(self, input_data):
"""
Detect OOD using Mahalanobis distance
"""
# Extract features from input
with torch.no_grad():
features = self.model.extract_features(input_data)

# Calculate Mahalanobis distance
diff = features - self.training_mean
inv_cov = torch.inverse(self.training_cov)
mahalanobis_dist = torch.sqrt(diff @ inv_cov @ diff.T)

# Threshold (calibrated on validation set)
ood_threshold = 3.0  # Example threshold

is_ood = mahalanobis_dist > ood_threshold

return is_ood, mahalanobis_dist.item()


def monitor_prediction_confidence(self, input_data):
"""
Monitor prediction confidence (low confidence indicates uncertainty)
"""
with torch.no_grad():
output = self.model(input_data)
probabilities = torch.softmax(output, dim=1)
max_prob, predicted_class = torch.max(probabilities, dim=1)

# Low confidence threshold
confidence_threshold = 0.7

is_uncertain = max_prob < confidence_threshold

return is_uncertain, max_prob.item(), predicted_class.item()
```

**Concept Drift Detection**:

```python
from scipy.stats import ks_2samp

class ConceptDriftDetector:
"""Detect concept drift in deployed ML model"""

def __init__(self, baseline_data):
"""
Parameters:
- baseline_data: Feature distribution from training/validation
"""
self.baseline_data = baseline_data


def detect_drift_ks_test(self, current_data, significance=0.05):
"""
Detect distribution shift using Kolmogorov-Smirnov test
"""
drift_detected = False

# Compare each feature dimension
for i in range(self.baseline_data.shape[1]):
statistic, p_value = ks_2samp(self.baseline_data[:, i], current_data[:, i])

if p_value < significance:
drift_detected = True
break

return drift_detected


def detect_drift_performance(self, current_accuracy, baseline_accuracy,
threshold=0.05):
"""
Detect drift based on performance degradation
"""
performance_drop = baseline_accuracy - current_accuracy

drift_detected = performance_drop > threshold

return drift_detected, performance_drop
```

### ML Safety Case Structure

**Claims**:
1. Training data covers relevant ODD scenarios
2. Model achieves acceptable performance on test set
3. Model is robust to OOD and adversarial inputs
4. Runtime monitoring detects degradation
5. Continuous improvement process in place

**Evidence**:
- Training data coverage analysis
- Test set performance metrics (precision, recall, F1)
- Adversarial robustness test results
- OOD detection validation
- Concept drift monitoring plan

**Arguments**:
- Training data representative → Model learns correct patterns
- Test performance acceptable → Model generalizes to deployment
- OOD monitoring active → Novel scenarios flagged for review
- Concept drift detection → Performance degradation caught early

## Deliverables

- ML safety case document
- Training data coverage analysis report
- Model verification test results (performance, robustness, uncertainty)
- Runtime monitoring architecture (OOD detection, concept drift)
- Continuous improvement process (retraining strategy, A/B testing)
- Traceability: Training data → Model → Test results → Safety requirements

## Best Practices

- Curate diverse training data (cover ODD parameter space)
- Use multiple test sets (in-distribution, OOD, adversarial)
- Quantify model uncertainty (Bayesian NNs, dropout Monte Carlo)
- Implement runtime OOD detection (do not trust all predictions equally)
- Monitor for concept drift (distribution shift over time)
- Plan for continuous learning (safe retraining and deployment)
- Use interpretability tools where possible (Grad-CAM, LIME)
- Red team adversarial testing (dedicated team tries to fool model)

## ISO/TR 4804 Recommendations

- Data quality management (annotation, diversity, bias)
- Model development process (training, validation, verification)
- Deployment monitoring (OOD, drift, performance)
- Update management (retraining, A/B testing, rollback)
- Safety argumentation (claims, evidence, arguments)

## Tools

- **Training**: PyTorch, TensorFlow, Keras
- **Data management**: Roboflow, Scale AI, Label Studio
- **Adversarial testing**: Foolbox, CleverHans, Adversarial Robustness Toolbox
- **Monitoring**: Weights & Biases, MLflow, Evidently AI
- **Interpretability**: Captum, LIME, SHAP

## Integration with SOTIF Process

1. **Training Data** → Cover triggering conditions from SOTIF analysis
2. **Model Verification** → Test on known unsafe scenarios (Area 2)
3. **OOD Detection** → Flag potential Area 3 scenarios at runtime
4. **Field Monitoring** → Discover concept drift, update model
5. **Continuous Improvement** → Retrain with field data, close SOTIF loop

## Common Pitfalls

- Insufficient training data diversity (missing edge cases)
- Overconfidence in model (not quantifying uncertainty)
- No runtime OOD detection (model used outside training distribution)
- Ignoring concept drift (performance degrades over time)
- No rollback plan for model updates (unsafe retraining)
- Black-box models without interpretability (difficult to debug failures)

### sotif-overview

## Core Competencies

Expert in ISO 21448 Safety of the Intended Functionality (SOTIF) standard, addressing hazards caused by functional insufficiency and reasonably foreseeable misuse in ADAS/autonomous driving systems (SAE L2+).

### SOTIF vs ISO 26262

- **ISO 26262**: Addresses random hardware failures and systematic failures due to development errors
- **ISO 21448 SOTIF**: Addresses insufficiencies in the intended function itself, even when system operates as designed
- **Complementary standards**: Both required for complete safety case
- **SOTIF triggers**: Environmental conditions, human behavior, system performance limitations
- **Overlapping area**: Systematic failures at system level covered by both standards

### Four Scenario Areas

SOTIF defines four areas based on known/unknown and safe/unsafe scenarios:

- **Area 1 (Known Safe)**: Normal operating conditions, system performs correctly
- **Area 2 (Known Unsafe)**: Identified hazardous scenarios, system must avoid or mitigate
- **Area 3 (Unknown Unsafe)**: Unidentified hazards discovered through testing/field operation
- **Area 4 (Unknown Safe)**: Potential hazards with acceptable residual risk

Goal: Minimize Area 3 (unknown unsafe) through systematic analysis and validation.

### Applicability

- **Required for**: SAE L2+ ADAS functions (lane keeping, adaptive cruise control, automated lane change)
- **Strongly recommended**: SAE L3-L5 autonomous driving systems
- **Type approval**: UN ECE R157 (ALKS) explicitly references ISO 21448
- **ODD-specific**: Each ODD requires separate SOTIF analysis
- **Sensor-dependent systems**: Particularly critical for camera/radar/lidar-based perception

### Key Concepts

**Functional Insufficiency**: Performance limitations of intended function due to:
- Sensor limitations (range, resolution, degraded conditions)
- Algorithm limitations (false positives/negatives, edge cases)
- Actuator limitations (response time, degraded performance)

**Reasonably Foreseeable Misuse**: Human behavior that is incorrect but predictable:
- Driver not monitoring system (mode confusion)
- Using system outside ODD
- Overreliance on automation
- Ignoring warnings

**Triggering Conditions**: Specific scenarios that expose insufficiencies:
- Environmental (rain, fog, low sun, darkness, snow)
- Traffic (cut-in vehicles, VRU behavior, construction zones)
- Infrastructure (faded lane markings, unusual road geometry)

## Approach

1. **ODD Definition**: Define operational design domain with boundaries
2. **Known Unsafe Identification**: Analyze functional insufficiencies and misuse scenarios
3. **Triggering Condition Catalog**: Build comprehensive scenario database
4. **Known Safe Verification**: Validate nominal performance in Area 1
5. **Unknown Unsafe Exploration**: Use simulation, field testing, fleet monitoring
6. **Residual Risk Evaluation**: Assess remaining Area 3/4 risk against acceptance criteria
7. **Continuous Improvement**: Field monitoring to discover new Area 3 scenarios

## SOTIF Process Integration

``` ISO 26262 Safety Lifecycle: Concept Phase → System Development → HW/SW Development → Production
ISO 21448 SOTIF Integration: [ODD Definition] → [Triggering Condition Analysis] → [Validation Strategy] ↓                       ↓                              ↓ Requirements         Scenario Catalog              Sim + Field Testing ↓                       ↓                              ↓ Safety Concept       Known Unsafe Mitigation        Residual Risk Evaluation ```

## Example: Automated Lane Keeping System (ALKS)

**ODD Definition**:
- Highway only (controlled-access roads)
- Speed: 0-60 km/h
- Weather: Daylight, dry/wet road, no fog
- Infrastructure: Clear lane markings, no construction

**Known Unsafe Scenarios**:
- Faded lane markings → Camera cannot detect lanes
- Cut-in vehicle → Insufficient reaction time
- Road edge detection failure → Unintended lane departure

**Triggering Conditions**:
- Lane marking contrast below threshold
- Lateral offset of cut-in vehicle
- Road curvature exceeding sensor FOV

**Mitigation**:
- Lane marking quality monitoring → Fallback to GPS/map
- Multi-sensor fusion (camera + radar + map)
- Driver monitoring system to ensure takeover readiness

## Deliverables

- SOTIF plan aligned with ISO 21448 clause requirements
- ODD specification with measurable boundary conditions
- Triggering condition catalog (1000+ scenarios for L2+)
- Known unsafe scenario mitigation strategies
- Validation strategy (simulation mileage targets, field test KPIs)
- Residual risk assessment report
- SOTIF argument in safety case documentation

## Best Practices

- Start SOTIF analysis early in concept phase (parallel to HARA)
- Use scenario-based approach with logical → concrete → test case traceability
- Combine simulation (billions of km) with field validation (statistical significance)
- Monitor fleet data post-deployment to discover Area 3 scenarios
- Coordinate with ISO 26262 safety manager to avoid gaps/overlaps
- Document ODD assumptions clearly in user manual and HMI
- Use structured scenario databases (OpenSCENARIO, OpenDRIVE)

## Tools and Methods

- **Scenario generation**: CARLA, SUMO, VTD, IPG CarMaker
- **Statistical validation**: Monte Carlo simulation, coverage metrics
- **Field monitoring**: Event Data Recorder (EDR), fleet analytics
- **FMEA/STPA**: Systematic identification of triggering conditions
- **Human factors analysis**: Driving simulator studies for misuse scenarios
- **ML verification**: Adversarial testing, out-of-distribution detection

## Regulatory Landscape

- **UN ECE R157**: ALKS regulation references ISO 21448 for ODD validation
- **EU Type Approval**: Expected to require SOTIF for L3+ systems
- **China GB Standards**: Drafts include SOTIF-like requirements for intelligent driving
- **US NHTSA**: AV ANPRM mentions performance under edge cases (SOTIF philosophy)

## Relationship to ML Safety

ML-based perception/planning introduces unique SOTIF challenges:
- Training data coverage vs real-world distribution shift
- Adversarial examples (physical adversarial patches)
- Model uncertainty quantification
- Continuous learning and model update safety

ISO 21448 provides framework; specific ML assurance methods evolving (ISO/TR 4804).

### sotif-risk-evaluation

## Core Competencies

Expert in evaluating residual risk for SOTIF, establishing acceptable risk thresholds based on societal tolerance, and comparing AD system performance to human driver baseline.

### Residual Risk in SOTIF

**Definition**: Risk remaining after SOTIF process (Areas 3 and 4)
- Area 3: Unknown unsafe scenarios (undiscovered hazards)
- Area 4: Unknown safe scenarios (uncertain but acceptable risk)

**Residual Risk Components**:
- **Frequency**: How often does hazardous scenario occur? (exposure)
- **Severity**: What is the consequence? (injury, fatality, property damage)
- **Controllability**: Can driver intervene? (for L2), Can system mitigate? (for L3+)

**Goal**: Demonstrate residual risk is "tolerable" and "as low as reasonably practicable" (ALARP).

### Human Driver Baseline

**US Statistics (NHTSA 2020)**:
- Fatal crashes: 1.1 per 100 million vehicle-miles (VMT)
- Injury crashes: 60 per 100M VMT
- Property damage only: 100 per 100M VMT
- Total crashes: ~160 per 100M VMT

**Variation by Context**:
- Highway vs urban: Highway fatality rate ~50% of urban
- Weather: Fatal crash rate 2x higher in rain, 3x in snow
- Time of day: Night fatality rate 3x higher than day
- Driver age: Young (16-20) and elderly (70+) have higher crash rates

**ODD-Adjusted Baseline**:
- Compare AD system to human performance in same ODD
- Example: Highway ADAS compared to human highway performance, not overall

### Acceptable Risk Thresholds

**Quantitative Approach**:
- AD system should be "demonstrably safer" than human
- Common target: 2x to 10x reduction in crash rate
- Depends on societal risk tolerance and regulatory requirements

**Qualitative Considerations**:
- Severity distribution: Prefer minor crashes over fatalities
- Crash preventability: Unavoidable scenarios (e.g., sudden medical emergency of other driver)
- Equity: Risk should not be disproportionately transferred to vulnerable road users

**ISO 26262 Risk Classification** (for reference):
- ASIL QM (Quality Management): Lowest risk, no specific safety requirements
- ASIL A: Low risk (1 fatality per 100M hours exposure)
- ASIL B: Medium risk (1 fatality per 10M hours)
- ASIL C: High risk (1 fatality per 1M hours)
- ASIL D: Very high risk (1 fatality per 100k hours)

Note: ISO 26262 addresses random/systematic failures; SOTIF addresses functional insufficiency. Both contribute to overall risk.

### Risk Calculation Methods

**Frequentist Approach**:

```python
import numpy as np
import scipy.stats as stats

class ResidualRiskCalculator:
"""Calculate residual risk for SOTIF"""

def __init__(self, validation_mileage_million_km, observed_crashes):
"""
Parameters:
- validation_mileage_million_km: Total validation mileage
- observed_crashes: Number of safety-critical events
"""
self.mileage = validation_mileage_million_km
self.crashes = observed_crashes


def point_estimate(self):
"""
Simple point estimate of crash rate
"""
crash_rate = self.crashes / self.mileage  # per million km
return crash_rate


def confidence_interval(self, confidence_level=0.95):
"""
Calculate confidence interval on crash rate using Poisson distribution
"""
# For Poisson process, CI based on chi-squared distribution
alpha = 1 - confidence_level

# Lower bound
lower = stats.chi2.ppf(alpha / 2, 2 * self.crashes) / (2 * self.mileage)

# Upper bound
upper = stats.chi2.ppf(1 - alpha / 2, 2 * (self.crashes + 1)) / (2 * self.mileage)

return lower, upper


def compare_to_human(self, human_crash_rate_per_million_km=1.0):
"""
Compare system crash rate to human baseline

Returns: (is_safer, improvement_factor, p_value)
"""
system_rate = self.point_estimate()

# Hypothesis test: H0: system_rate >= human_rate, H1: system_rate < human_rate
# Using Poisson test
expected_crashes = human_crash_rate_per_million_km * self.mileage
p_value = stats.poisson.cdf(self.crashes, expected_crashes)

is_safer = system_rate < human_crash_rate_per_million_km
improvement_factor = human_crash_rate_per_million_km / system_rate if system_rate > 0 else float('inf')

return is_safer, improvement_factor, p_value

# Example: 5 million km validation, 2 crashes observed
calculator = ResidualRiskCalculator(validation_mileage_million_km=5, observed_crashes=2)

point_est = calculator.point_estimate()
print(f"Point estimate crash rate: {point_est:.3f} per million km")

lower, upper = calculator.confidence_interval(confidence_level=0.95)
print(f"95% CI: [{lower:.3f}, {upper:.3f}] per million km")

human_baseline = 1.0  # 1 crash per million km (example)
is_safer, improvement, p_value = calculator.compare_to_human(human_baseline)
print(f"Safer than human: {is_safer}, Improvement factor: {improvement:.1f}x, p-value: {p_value:.3f}")
```

**Bayesian Approach** (incorporate prior knowledge):

```python
import scipy.stats as stats

class BayesianRiskEstimator:
"""Estimate crash rate using Bayesian inference"""

def __init__(self, prior_mean=1.0, prior_std=0.5):
"""
Parameters:
- prior_mean: Prior belief about crash rate (per million km)
- prior_std: Uncertainty in prior belief
"""
# Use Gamma distribution as conjugate prior for Poisson
self.prior_alpha = (prior_mean / prior_std) ** 2
self.prior_beta = prior_mean / (prior_std ** 2)


def update_posterior(self, validation_mileage_million_km, observed_crashes):
"""
Update belief after observing validation data
"""
# Posterior is Gamma(alpha + crashes, beta + mileage)
posterior_alpha = self.prior_alpha + observed_crashes
posterior_beta = self.prior_beta + validation_mileage_million_km

# Posterior mean and std
posterior_mean = posterior_alpha / posterior_beta
posterior_std = np.sqrt(posterior_alpha) / posterior_beta

return posterior_mean, posterior_std


def credible_interval(self, validation_mileage_million_km, observed_crashes,
credibility=0.95):
"""
Bayesian credible interval (analogous to confidence interval)
"""
posterior_alpha = self.prior_alpha + observed_crashes
posterior_beta = self.prior_beta + validation_mileage_million_km

# Credible interval from Gamma distribution
lower = stats.gamma.ppf((1 - credibility) / 2, posterior_alpha, scale=1 / posterior_beta)
upper = stats.gamma.ppf(1 - (1 - credibility) / 2, posterior_alpha, scale=1 / posterior_beta)

return lower, upper

# Example with optimistic prior (system expected to be safer than human)
estimator = BayesianRiskEstimator(prior_mean=0.5, prior_std=0.3)  # Expect 0.5 crashes/M km

posterior_mean, posterior_std = estimator.update_posterior(
validation_mileage_million_km=5, observed_crashes=2
)
print(f"Posterior mean crash rate: {posterior_mean:.3f} ± {posterior_std:.3f} per million km")

lower, upper = estimator.credible_interval(
validation_mileage_million_km=5, observed_crashes=2, credibility=0.95
)
print(f"95% credible interval: [{lower:.3f}, {upper:.3f}] per million km")
```

### Severity Analysis

**Crash Severity Distribution**:
- K (killed): Fatality
- A (incapacitating injury): Hospitalization required
- B (non-incapacitating injury): Visible injury, no hospitalization
- C (possible injury): Complaint of pain, no visible injury
- O (no injury): Property damage only

**Risk Metric Incorporating Severity**:

```python
def calculate_harm_score(crash_severity_distribution):
"""
Calculate weighted harm score based on severity distribution

Parameters:
- crash_severity_distribution: Dict with keys K, A, B, C, O and counts
"""
# Weighting factors (example, can be adjusted)
weights = {
'K': 100,  # Fatality: highest weight
'A': 10,   # Severe injury
'B': 3,    # Moderate injury
'C': 1,    # Minor injury
'O': 0.1   # Property damage
}

total_harm = sum(crash_severity_distribution[severity] * weights[severity]
for severity in crash_severity_distribution)

return total_harm

# Example: System has fewer total crashes, but higher severity?
human_severity = {'K': 1, 'A': 5, 'B': 10, 'C': 30, 'O': 54}  # per 100 crashes
system_severity = {'K': 0, 'A': 2, 'B': 5, 'C': 10, 'O': 20}   # per 37 crashes (lower total)

human_harm = calculate_harm_score(human_severity)
system_harm = calculate_harm_score(system_severity)

print(f"Human harm score: {human_harm:.1f}")
print(f"System harm score: {system_harm:.1f}")
print(f"Harm reduction: {(1 - system_harm / human_harm) * 100:.1f}%")
```

### Societal Risk Tolerance

**Revealed Preference** (observed societal tolerance):
- Aviation: ~1 fatality per 10 billion passenger-km (extremely low tolerance)
- Rail: ~0.1 fatality per billion passenger-km
- Road (human driver): ~5 fatalities per billion vehicle-km
- Implication: Society tolerates higher risk for personal mobility vs public transport

**Expressed Preference** (surveys, public consultation):
- Surveys show public expects AD systems to be "much safer" than human (2-10x)
- Zero-risk expectation unrealistic (cannot achieve zero)
- Transparency and trust important (system failures judged more harshly)

**Ethical Considerations**:
- Risk distribution: Who bears the risk? (occupants vs VRUs)
- Equity: Does system perform equally for all demographics?
- Consent: Occupants choose to use system; VRUs do not

## Deliverables

- Residual risk assessment report with quantitative estimates
- Comparison to human driver baseline (ODD-adjusted)
- Acceptable risk threshold justification
- Severity distribution analysis
- Societal risk tolerance assessment
- Safety case argument for risk acceptability
- Sensitivity analysis (how results change with assumptions)

## Best Practices

- Use ODD-adjusted human baseline (not overall crash rate)
- Report confidence/credible intervals (not just point estimates)
- Analyze severity distribution (not just crash frequency)
- Consider both frequentist and Bayesian approaches
- Acknowledge uncertainty (validation is finite, real-world is infinite)
- Engage stakeholders (public, regulators) on risk tolerance
- Document all assumptions (prior beliefs, statistical models)
- Plan for continuous monitoring (validate residual risk assumptions post-deployment)

## Regulatory Landscape

**UN ECE R157 (ALKS L3)**:
- No explicit quantitative risk threshold
- Requires demonstration of safety through testing
- Emphasizes continuous monitoring and improvement

**ISO 21448**:
- Does not mandate specific acceptable risk level
- Leaves to applicable regulations and societal norms
- Requires demonstration of "sufficient" risk reduction

**Future Trends**:
- Move toward quantitative performance standards (e.g., NHTSA proposals)
- Transparency requirements (publish safety performance data)
- Comparative assessments (AD system vs human in same scenarios)

## Integration with SOTIF Process

1. **Triggering Condition Analysis** → Identify hazards (Areas 2+3)
2. **Validation** → Quantify observed crash rate
3. **Residual Risk Evaluation** → Estimate remaining Area 3/4 risk
4. **Acceptance Criteria** → Compare to thresholds
5. **Safety Case** → Argue risk is tolerable and ALARP
6. **Field Monitoring** → Validate residual risk assumptions

## Common Pitfalls

- Comparing to overall human crash rate (not ODD-adjusted)
- Overconfidence from limited validation data (wide confidence intervals ignored)
- Not accounting for crash severity (frequency alone insufficient)
- Post-hoc rationalization of acceptable risk (should be defined upfront)
- Claiming zero risk (impossible to prove)
- Not planning for continuous monitoring (assumptions may be wrong)

### sotif-scenario-catalog

## Core Competencies

Expert in building and maintaining comprehensive scenario catalogs for SOTIF validation, using structured representations from abstract concepts to concrete test cases.

### Scenario Abstraction Levels

**Logical Scenarios**:
- High-level description in natural language
- Example: "Vehicle cuts in front of ego vehicle"
- No specific parameter values
- Used for initial hazard identification

**Abstract Scenarios**:
- Parameterized with ranges
- Example: "Vehicle cuts in at distance [10-50m], speed difference [-20 to +10 km/h]"
- Captures family of similar scenarios
- Used for coverage analysis

**Concrete Scenarios**:
- Specific parameter values
- Example: "Vehicle cuts in at 25m, 15 km/h slower than ego"
- Directly executable in simulation or test track
- Used for actual validation testing

### Scenario Database Structure

```yaml
# Example scenario catalog entry
scenario_id: SOTIF-ACC-001
logical_description: "Cut-in vehicle from adjacent lane"
function: Adaptive Cruise Control
sotif_area: Area 2 (Known Unsafe)
triggering_condition: Close-range cut-in with high relative velocity

abstract_parameters:
ego_speed: [60, 120]  # km/h
cut_in_distance: [10, 50]  # meters
relative_velocity: [-30, -5]  # km/h (cut-in vehicle slower)
lateral_offset: [0.2, 1.5]  # meters from lane center
road_curvature: [0, 0.005]  # 1/m

hazard: Rear-end collision with cut-in vehicle
severity: ASIL D
mitigation: Emergency braking, driver warning

concrete_instances:
- instance_id: SOTIF-ACC-001-C01
ego_speed: 100
cut_in_distance: 25
relative_velocity: -20
lateral_offset: 0.5
road_curvature: 0.002
expected_result: System brakes, TTC > 2.5s maintained

- instance_id: SOTIF-ACC-001-C02
ego_speed: 80
cut_in_distance: 15
relative_velocity: -25
lateral_offset: 0.8
road_curvature: 0
expected_result: System brakes, driver warning issued
```

## Catalog Construction Process

1. **Triggering Condition Identification**: Use STPA/FMEA to identify triggering conditions
2. **Logical Scenario Definition**: Convert triggering conditions to natural language scenarios
3. **Parameterization**: Identify relevant parameters and their ranges (abstract scenarios)
4. **Combinatorial Generation**: Generate concrete instances covering parameter space
5. **Prioritization**: Rank scenarios by risk (severity × exposure × controllability)
6. **Traceability**: Link scenarios to hazards, requirements, and test cases

## OpenSCENARIO Representation

```xml
<?xml version="1.0" encoding="UTF-8"?>
<OpenSCENARIO>
<FileHeader revMajor="2" revMinor="0" date="2026-03-19"
description="Cut-in scenario for ACC SOTIF validation"/>

<ParameterDeclarations>
<ParameterDeclaration name="ego_speed" parameterType="double" value="100.0"/>
<ParameterDeclaration name="cut_in_distance" parameterType="double" value="25.0"/>
<ParameterDeclaration name="relative_velocity" parameterType="double" value="-20.0"/>
</ParameterDeclarations>

<Entities>
<ScenarioObject name="Ego">
<Vehicle name="vehicle.tesla.model3" vehicleCategory="car"/>
</ScenarioObject>
<ScenarioObject name="Adversary">
<Vehicle name="vehicle.audi.a2" vehicleCategory="car"/>
</ScenarioObject>
</Entities>

<Storyboard>
<Init>
<Actions>
<Private entityRef="Ego">
<PrivateAction>
<LongitudinalAction>
<SpeedAction>
<SpeedActionDynamics dynamicsShape="step" value="0"/>
<SpeedActionTarget>
<AbsoluteTargetSpeed value="$ego_speed"/>
</SpeedActionTarget>
</SpeedAction>
</LongitudinalAction>
</PrivateAction>
</Private>

<Private entityRef="Adversary">
<PrivateAction>
<TeleportAction>
<Position>
<RelativeObjectPosition entityRef="Ego" dx="$cut_in_distance" dy="-3.5" dz="0"/>
</Position>
</TeleportAction>
</PrivateAction>
<PrivateAction>
<LongitudinalAction>
<SpeedAction>
<SpeedActionDynamics dynamicsShape="step" value="0"/>
<SpeedActionTarget>
<AbsoluteTargetSpeed value="${ego_speed + relative_velocity}"/>
</SpeedActionTarget>
</SpeedAction>
</LongitudinalAction>
</PrivateAction>
</Private>
</Actions>
</Init>

<Story name="CutInStory">
<Act name="CutInAct">
<ManeuverGroup maximumExecutionCount="1" name="CutInManeuver">
<Actors selectTriggeringEntities="false">
<EntityRef entityRef="Adversary"/>
</Actors>
<Maneuver name="LaneChangeManeuver">
<Event name="LaneChangeEvent" priority="overwrite">
<Action name="LaneChangeAction">
<PrivateAction>
<LateralAction>
<LaneChangeAction>
<LaneChangeActionDynamics dynamicsShape="sinusoidal" value="2.0"/>
<LaneChangeTarget>
<RelativeTargetLane entityRef="Ego" value="0"/>
</LaneChangeTarget>
</LaneChangeAction>
</LateralAction>
</PrivateAction>
</Action>
<StartTrigger>
<ConditionGroup>
<Condition name="StartCondition" delay="0" conditionEdge="rising">
<ByValueCondition>
<SimulationTimeCondition value="2.0" rule="greaterThan"/>
</ByValueCondition>
</Condition>
</ConditionGroup>
</StartTrigger>
</Event>
</Maneuver>
</ManeuverGroup>

<StartTrigger>
<ConditionGroup>
<Condition name="ActStartCondition" delay="0" conditionEdge="rising">
<ByValueCondition>
<SimulationTimeCondition value="0" rule="greaterThan"/>
</ByValueCondition>
</Condition>
</ConditionGroup>
</StartTrigger>
</Act>
</Story>
</Storyboard>
</OpenSCENARIO>
```

## Scenario Generation Techniques

**Combinatorial Coverage**:

```python
from itertools import product
import pandas as pd

def generate_scenario_combinations(parameter_ranges):
"""
Generate all combinations of parameters for coverage testing
"""
# Define discrete values for each parameter
params = {
"ego_speed": [60, 80, 100, 120],  # km/h
"cut_in_distance": [10, 20, 30, 40, 50],  # meters
"relative_velocity": [-30, -20, -10, -5],  # km/h
"road_curvature": [0, 0.002, 0.005],  # 1/m
}

# Generate all combinations
combinations = list(product(*params.values()))

# Create DataFrame
scenarios = pd.DataFrame(combinations, columns=params.keys())

# Add scenario IDs
scenarios["scenario_id"] = [f"SOTIF-ACC-001-C{i:03d}" for i in range(len(scenarios))]

return scenarios

scenarios = generate_scenario_combinations()
print(f"Generated {len(scenarios)} concrete scenarios")
# Output: 240 scenarios (4 × 5 × 4 × 3)
```

**Latin Hypercube Sampling** (efficient parameter space coverage):

```python
from scipy.stats import qmc
import numpy as np

def generate_lhs_scenarios(num_samples=100):
"""
Generate scenarios using Latin Hypercube Sampling for efficient coverage
"""
# Define parameter bounds
bounds = np.array([
[60, 120],     # ego_speed
[10, 50],      # cut_in_distance
[-30, -5],     # relative_velocity
[0, 0.005],    # road_curvature
])

# Generate LHS samples
sampler = qmc.LatinHypercube(d=4)
samples = sampler.random(n=num_samples)

# Scale to parameter bounds
scenarios = qmc.scale(samples, bounds[:, 0], bounds[:, 1])

return pd.DataFrame(scenarios, columns=[
"ego_speed", "cut_in_distance", "relative_velocity", "road_curvature"
])

lhs_scenarios = generate_lhs_scenarios(1000)
print(f"Generated {len(lhs_scenarios)} LHS scenarios")
```

## Catalog Management

**Database Schema** (SQL example):

```sql
CREATE TABLE scenarios (
scenario_id VARCHAR(50) PRIMARY KEY,
logical_description TEXT,
function VARCHAR(100),
sotif_area ENUM('Area1', 'Area2', 'Area3', 'Area4'),
triggering_condition VARCHAR(255),
hazard TEXT,
severity VARCHAR(10),
mitigation TEXT
);

CREATE TABLE abstract_parameters (
scenario_id VARCHAR(50),
parameter_name VARCHAR(100),
min_value FLOAT,
max_value FLOAT,
unit VARCHAR(20),
FOREIGN KEY (scenario_id) REFERENCES scenarios(scenario_id)
);

CREATE TABLE concrete_instances (
instance_id VARCHAR(50) PRIMARY KEY,
scenario_id VARCHAR(50),
parameter_values JSON,
expected_result TEXT,
test_status ENUM('pending', 'passed', 'failed', 'blocked'),
execution_date DATE,
FOREIGN KEY (scenario_id) REFERENCES scenarios(scenario_id)
);

CREATE TABLE test_results (
result_id INT AUTO_INCREMENT PRIMARY KEY,
instance_id VARCHAR(50),
execution_platform VARCHAR(50),
actual_result TEXT,
pass_fail ENUM('pass', 'fail'),
timestamp DATETIME,
FOREIGN KEY (instance_id) REFERENCES concrete_instances(instance_id)
);
```

## Deliverables

- Scenario catalog database (1000+ scenarios for L2+ ADAS)
- OpenSCENARIO XML files for simulation execution
- Traceability matrix: Triggering condition → Scenario → Test case → Result
- Parameter coverage analysis report
- Scenario prioritization (risk-based ranking)
- Catalog versioning and change management process

## Best Practices

- Use standardized formats (OpenSCENARIO, OpenDRIVE) for interoperability
- Version control scenario catalog (treat as safety artifact)
- Link scenarios to triggering conditions and hazards (traceability)
- Use efficient sampling (LHS, DOE) to reduce test burden
- Prioritize scenarios by risk (test high-severity scenarios first)
- Update catalog continuously (add newly discovered Area 3 scenarios)
- Share catalog across projects (reuse validated scenarios)

## Tools

- **OpenSCENARIO Editor**: GUI for creating scenario files
- **esmini**: Open-source OpenSCENARIO player
- **CARLA ScenarioRunner**: Execute OpenSCENARIO in CARLA simulator
- **ASAM OSI**: Open Simulation Interface for sensor models
- **Database**: PostgreSQL, MySQL for catalog storage
- **Version control**: Git with LFS for large scenario files

## Integration with SOTIF Process

1. **Triggering Condition Analysis** → Logical scenarios
2. **Parameterization** → Abstract scenarios
3. **Test Generation** → Concrete scenarios
4. **Validation Execution** → Test results linked to scenarios
5. **Continuous Improvement** → Add newly discovered scenarios to catalog

## Common Pitfalls

- Too many scenarios (combinatorial explosion without prioritization)
- Insufficient parameterization (missing critical edge cases)
- Lack of traceability (cannot link test results back to hazards)
- Not version controlling catalog (inconsistent testing across teams)
- Ignoring scenario reuse (reinventing wheel for each project)

### sotif-sensor-insufficiency

## Core Competencies

Expert in analyzing sensor performance limitations and degraded conditions that lead to functional insufficiencies, a primary source of SOTIF hazards in ADAS/AD systems.

### Sensor Types and Limitations

**Camera (Optical)**:
- Detection range: 50-200m (limited by resolution, optics)
- Degradation: Rain, fog, snow, dirt, sun glare, darkness
- Blind spots: Direct sun (5-15° above horizon), low contrast scenes
- Failure modes: False negatives (missed detection), false classification

**Radar (77 GHz)**:
- Detection range: 150-250m (long-range), 30-80m (short-range)
- Degradation: Heavy rain (slight), metallic reflections, ground clutter
- Blind spots: Stationary objects (no Doppler), soft targets (pedestrians)
- Failure modes: Ghost objects (multipath), missed VRUs

**Lidar (905 nm / 1550 nm)**:
- Detection range: 100-200m (mechanical), 50-100m (solid-state)
- Degradation: Rain/fog/snow (severe), dirt, direct sun
- Blind spots: Transparent objects (glass), specular surfaces
- Failure modes: Point cloud sparsity, missed detections in precipitation

**Ultrasonic (40 kHz)**:
- Detection range: 0.2-5m (parking assistance)
- Degradation: Temperature, air pressure, surface texture
- Blind spots: Soft/angled surfaces (absorb ultrasound)
- Failure modes: False echoes, missed small objects

### Environmental Degradation Conditions

**Rain**:
- Camera: Water droplets on lens, reduced visibility, reflections
- Radar: Attenuation at 77 GHz (minor, ~0.5 dB/km at 25 mm/h)
- Lidar: Scattering from raindrops (severe, detection range halved at 10 mm/h)

**Fog**:
- Camera: Scattering reduces contrast (visibility < 100m in dense fog)
- Radar: Minimal impact (wavelength >> fog droplet size)
- Lidar: Severe scattering (detection range < 30m in dense fog)

**Snow**:
- Camera: Occluded by falling snow, white background, lens accumulation
- Radar: Clutter from falling snow (increased false positives)
- Lidar: Severe scattering, point cloud noise

**Sun Glare**:
- Camera: Sensor saturation, lens flare (critical at low sun angles 5-15°)
- Radar: No impact
- Lidar: Sensor saturation (905 nm more susceptible than 1550 nm)

**Darkness**:
- Camera: Reduced SNR, requires headlight illumination (range ~50m)
- Radar: No impact
- Lidar: No impact (active sensor)

**Dirt/Contamination**:
- Camera: Reduced visibility, must clean >70% lens area
- Radar: Minimal (unless heavy mud buildup)
- Lidar: Severe (dust/dirt on rotating mirror or lens)

## Sensor Performance Modeling

```python
import numpy as np

class SensorPerformanceModel:
"""Model sensor detection range under various conditions"""

def __init__(self, sensor_type):
self.sensor_type = sensor_type
self.nominal_range = self._get_nominal_range()


def _get_nominal_range(self):
"""Nominal detection range in clear conditions"""
ranges = {
"camera": 150,  # meters
"radar_lr": 250,
"lidar": 120,
"ultrasonic": 5
}
return ranges.get(self.sensor_type, 100)


def calculate_degraded_range(self, rain_mm_h=0, fog_visibility_m=1000,
sun_angle_deg=90, contamination_pct=0):
"""
Calculate effective detection range under degraded conditions

Parameters:
- rain_mm_h: Rain intensity (mm/hour)
- fog_visibility_m: Visibility distance in fog (meters)
- sun_angle_deg: Sun angle above horizon (degrees)
- contamination_pct: Sensor contamination percentage (0-100)

Returns:
- Effective detection range (meters)
"""
range_multiplier = 1.0

# Rain degradation
if self.sensor_type == "camera":
range_multiplier *= max(0.3, 1 - 0.02 * rain_mm_h)
elif self.sensor_type == "lidar":
range_multiplier *= max(0.2, 1 - 0.05 * rain_mm_h)
# Radar largely unaffected

# Fog degradation
if self.sensor_type in ["camera", "lidar"]:
if fog_visibility_m < 200:
range_multiplier *= min(1.0, fog_visibility_m / 200)

# Sun glare (camera and lidar)
if 5 <= sun_angle_deg <= 15:
if self.sensor_type == "camera":
range_multiplier *= 0.1  # Severe degradation
elif self.sensor_type == "lidar":
range_multiplier *= 0.5

# Contamination
if contamination_pct > 30:
range_multiplier *= max(0.1, (100 - contamination_pct) / 70)

effective_range = self.nominal_range * range_multiplier
return effective_range

# Example usage
camera = SensorPerformanceModel("camera")
lidar = SensorPerformanceModel("lidar")
radar = SensorPerformanceModel("radar_lr")

# Scenario: Heavy rain (20 mm/h)
print(f"Camera range in heavy rain: {camera.calculate_degraded_range(rain_mm_h=20):.1f}m")
print(f"Lidar range in heavy rain: {lidar.calculate_degraded_range(rain_mm_h=20):.1f}m")
print(f"Radar range in heavy rain: {radar.calculate_degraded_range(rain_mm_h=20):.1f}m")

# Scenario: Sun glare at 10° above horizon
print(f"Camera range in sun glare: {camera.calculate_degraded_range(sun_angle_deg=10):.1f}m")
```

## Multi-Sensor Fusion Strategy

**Complementary Strengths**:
- Camera: High resolution, classification, lane markings
- Radar: All-weather, velocity measurement (Doppler), long range
- Lidar: 3D geometry, obstacle shape, mid-range accuracy

**Fusion Architecture**:
- Early fusion: Combine raw sensor data (high complexity)
- Late fusion: Combine object lists (common approach)
- Hybrid fusion: Combine features + objects

**Degraded Condition Strategy**:

| Condition | Primary Sensor | Secondary Sensor | Fallback |
|-----------|----------------|------------------|----------|
| Clear day | Camera | Lidar | Radar |
| Night | Lidar | Radar | Camera (limited) |
| Rain | Radar | Camera | Lidar (degraded) |
| Fog | Radar | Lidar (short range) | Camera (unusable) |
| Sun glare | Radar | Lidar | Camera (blind) |

## ODD Definition Based on Sensor Limits

```python
class ODDBoundaryChecker:
"""Determine if current conditions are within ODD based on sensor performance"""

def __init__(self, required_detection_range=100):
self.required_range = required_detection_range
self.camera = SensorPerformanceModel("camera")
self.lidar = SensorPerformanceModel("lidar")
self.radar = SensorPerformanceModel("radar_lr")


def is_within_odd(self, rain_mm_h, fog_visibility_m, sun_angle_deg, contamination_pct):
"""Check if sensor performance meets requirements"""
camera_range = self.camera.calculate_degraded_range(
rain_mm_h, fog_visibility_m, sun_angle_deg, contamination_pct)
lidar_range = self.lidar.calculate_degraded_range(
rain_mm_h, fog_visibility_m, sun_angle_deg, contamination_pct)
radar_range = self.radar.calculate_degraded_range(
rain_mm_h, fog_visibility_m, sun_angle_deg, contamination_pct)

# Require at least 2 sensors meet range requirement (redundancy)
sensors_ok = sum([
camera_range >= self.required_range,
lidar_range >= self.required_range,
radar_range >= self.required_range
])

return sensors_ok >= 2

# Example: Check ODD compliance
odd_checker = ODDBoundaryChecker(required_detection_range=100)

# Scenario 1: Light rain (5 mm/h)
in_odd = odd_checker.is_within_odd(rain_mm_h=5, fog_visibility_m=500,
sun_angle_deg=45, contamination_pct=10)
print(f"Light rain - Within ODD: {in_odd}")

# Scenario 2: Heavy rain (25 mm/h) + fog
in_odd = odd_checker.is_within_odd(rain_mm_h=25, fog_visibility_m=80,
sun_angle_deg=45, contamination_pct=10)
print(f"Heavy rain + fog - Within ODD: {in_odd}")
```

## Mitigation Strategies

**Design-Based**:
- Multi-sensor redundancy (camera + radar + lidar)
- Sensor cleaning systems (washer, air jets, heating)
- Sensor placement optimization (avoid spray zones)
- Robust sensor hardware (heated lenses, hydrophobic coatings)

**Algorithm-Based**:
- Sensor quality monitoring (detect degradation)
- Dynamic sensor weighting (prioritize best sensor)
- Graceful degradation (reduce speed when sensors degrade)
- Map-based fallback (use HD maps when sensors insufficient)

**ODD-Based**:
- Exclude conditions where sensor performance insufficient
- Example: No operation in heavy rain (> 20 mm/h), dense fog (< 100m visibility)

## Deliverables

- Sensor performance envelope specification (range vs environmental conditions)
- Degraded condition impact analysis
- Multi-sensor fusion architecture requirements
- ODD boundary definition based on sensor limits
- Sensor monitoring and cleaning system requirements
- Test plan for sensor performance validation

## Best Practices

- Model sensor performance under all ODD conditions (not just nominal)
- Validate sensor models with real-world testing (rain chamber, fog chamber)
- Require multi-sensor redundancy (no single point of failure)
- Monitor sensor health in real-time (contamination, alignment, faults)
- Define quantitative ODD boundaries (not qualitative "heavy rain")
- Test sensor cleaning system effectiveness
- Plan for graceful degradation (not abrupt system shutdown)

## Common Pitfalls

- Overestimating sensor performance in degraded conditions
- Not considering combined degradation (rain + dirt + sun glare)
- Single sensor dependency (no redundancy)
- ODD boundaries too optimistic (insufficient safety margin)
- Not validating sensor models with field testing

### sotif-simulation-testing

## Core Competencies

Expert in scenario-based simulation testing for SOTIF validation, using open-source (CARLA, SUMO) and commercial (VTD, IPG CarMaker) platforms to generate billions of equivalent km.

### Simulation Platforms

**CARLA (Open-Source)**:
- Unreal Engine-based, photo-realistic rendering
- Python API for scenario control
- Supports camera, lidar, radar, GPS sensors
- ScenarioRunner for OpenSCENARIO execution
- Free, open-source, active community

**SUMO (Open-Source Traffic Simulation)**:
- Microscopic traffic simulation
- Focus on traffic flow, not perception
- Python TraCI API
- Lightweight, fast execution
- Good for large-scale traffic scenarios

**IPG CarMaker (Commercial)**:
- Industry-standard for vehicle dynamics
- High-fidelity sensor models
- Real-time capable (HIL integration)
- OpenSCENARIO support
- Expensive but widely used

**VTD (Virtual Test Drive, Commercial)**:
- Comprehensive sensor simulation
- Traffic simulation with AI agents
- Distributed simulation (multi-instance)
- OpenX standards compliant

### CARLA Scenario Execution

```python
import carla
import random
import numpy as np

class CARLAScenarioRunner:
"""Execute SOTIF scenarios in CARLA simulation"""

def __init__(self, host='localhost', port=2000):
self.client = carla.Client(host, port)
self.client.set_timeout(10.0)
self.world = self.client.get_world()
self.blueprint_library = self.world.get_blueprint_library()


def spawn_ego_vehicle(self, spawn_point):
"""Spawn ego vehicle with sensors"""
vehicle_bp = self.blueprint_library.filter('vehicle.tesla.model3')[0]
ego_vehicle = self.world.spawn_actor(vehicle_bp, spawn_point)

# Attach camera sensor
camera_bp = self.blueprint_library.find('sensor.camera.rgb')
camera_bp.set_attribute('image_size_x', '1920')
camera_bp.set_attribute('image_size_y', '1080')
camera_transform = carla.Transform(carla.Location(x=1.5, z=2.4))
camera = self.world.spawn_actor(camera_bp, camera_transform, attach_to=ego_vehicle)

# Attach lidar sensor
lidar_bp = self.blueprint_library.find('sensor.lidar.ray_cast')
lidar_bp.set_attribute('channels', '64')
lidar_bp.set_attribute('range', '100')
lidar_transform = carla.Transform(carla.Location(x=0, z=2.5))
lidar = self.world.spawn_actor(lidar_bp, lidar_transform, attach_to=ego_vehicle)

return ego_vehicle, camera, lidar


def execute_cut_in_scenario(self, ego_speed_kmh=100, cut_in_distance_m=25,
relative_velocity_kmh=-20):
"""
Execute cut-in scenario with specified parameters
"""
# Set synchronous mode for deterministic simulation
settings = self.world.get_settings()
settings.synchronous_mode = True
settings.fixed_delta_seconds = 0.05  # 20 Hz
self.world.apply_settings(settings)

# Spawn ego vehicle
spawn_points = self.world.get_map().get_spawn_points()
ego_vehicle, camera, lidar = self.spawn_ego_vehicle(spawn_points[0])

# Set ego vehicle speed
ego_vehicle.enable_constant_velocity(
carla.Vector3D(x=ego_speed_kmh / 3.6, y=0, z=0)
)

# Spawn adversary vehicle in adjacent lane
adversary_bp = self.blueprint_library.filter('vehicle.audi.a2')[0]
adversary_spawn = carla.Transform(
carla.Location(
x=spawn_points[0].location.x + cut_in_distance_m,
y=spawn_points[0].location.y - 3.5,  # Adjacent lane
z=spawn_points[0].location.z
)
)
adversary = self.world.spawn_actor(adversary_bp, adversary_spawn)

# Set adversary speed
adversary_speed = (ego_speed_kmh + relative_velocity_kmh) / 3.6
adversary.enable_constant_velocity(carla.Vector3D(x=adversary_speed, y=0, z=0))

# Execute scenario for 10 seconds
results = {
"collision": False,
"min_ttc": float('inf'),
"ego_trajectory": [],
"adversary_trajectory": []
}

for frame in range(200):  # 10 seconds at 20 Hz
self.world.tick()

ego_location = ego_vehicle.get_location()
adversary_location = adversary.get_location()

results["ego_trajectory"].append((ego_location.x, ego_location.y))
results["adversary_trajectory"].append((adversary_location.x, adversary_location.y))

# Check for collision
if ego_vehicle.get_velocity().length() < 0.1:  # Vehicle stopped (collision)
results["collision"] = True

# Calculate TTC
relative_distance = abs(ego_location.x - adversary_location.x)
relative_velocity = abs(ego_vehicle.get_velocity().x - adversary.get_velocity().x)
if relative_velocity > 0.1:
ttc = relative_distance / relative_velocity
results["min_ttc"] = min(results["min_ttc"], ttc)

# Adversary lane change at 2 seconds
if frame == 40:
adversary.set_target_velocity(carla.Vector3D(x=adversary_speed, y=1.0, z=0))

# Cleanup
camera.destroy()
lidar.destroy()
ego_vehicle.destroy()
adversary.destroy()

return results

# Example usage
runner = CARLAScenarioRunner()
result = runner.execute_cut_in_scenario(ego_speed_kmh=100, cut_in_distance_m=25,
relative_velocity_kmh=-20)
print(f"Collision: {result['collision']}, Min TTC: {result['min_ttc']:.2f}s")
```

### Parameter Variation Testing

```python
import itertools
import pandas as pd

class ParameterSweepTester:
"""Systematically vary scenario parameters to explore space"""

def __init__(self, scenario_runner):
self.runner = scenario_runner


def run_parameter_sweep(self, parameter_ranges):
"""
Execute scenario with all parameter combinations

Parameters:
- parameter_ranges: Dict of parameter names to lists of values
"""
results = []

# Generate all combinations
param_names = list(parameter_ranges.keys())
param_values = list(parameter_ranges.values())
combinations = list(itertools.product(*param_values))

for combo in combinations:
params = dict(zip(param_names, combo))

# Execute scenario
result = self.runner.execute_cut_in_scenario(
ego_speed_kmh=params['ego_speed'],
cut_in_distance_m=params['cut_in_distance'],
relative_velocity_kmh=params['relative_velocity']
)

results.append({
**params,
**result
})

return pd.DataFrame(results)


def analyze_critical_scenarios(self, results_df, ttc_threshold=2.5):
"""Identify scenarios with TTC below threshold"""
critical = results_df[results_df['min_ttc'] < ttc_threshold]
return critical

# Example usage
tester = ParameterSweepTester(CARLAScenarioRunner())

parameter_ranges = {
'ego_speed': [60, 80, 100, 120],
'cut_in_distance': [10, 20, 30, 40, 50],
'relative_velocity': [-30, -20, -10]
}

results = tester.run_parameter_sweep(parameter_ranges)
print(f"Executed {len(results)} scenario variants")

critical_scenarios = tester.analyze_critical_scenarios(results, ttc_threshold=2.5)
print(f"Found {len(critical_scenarios)} critical scenarios (TTC < 2.5s)")
```

### Corner Case Generation with ML

```python
import torch
import torch.nn as nn

class CornerCaseGenerator:
"""Use ML to generate corner cases that challenge the system"""

def __init__(self, system_under_test):
"""
Parameters:
- system_under_test: Surrogate model of ADAS system
"""
self.system = system_under_test


def optimize_for_failure(self, num_iterations=1000):
"""
Use gradient-based optimization to find challenging scenarios
"""
# Initialize scenario parameters
scenario_params = torch.tensor([
100.0,  # ego_speed
30.0,   # cut_in_distance
-15.0   # relative_velocity
], requires_grad=True)

optimizer = torch.optim.Adam([scenario_params], lr=1.0)

for iteration in range(num_iterations):
optimizer.zero_grad()

# Simulate system response
collision_probability = self.system(scenario_params)

# Maximize collision probability (find corner case)
loss = -collision_probability
loss.backward()
optimizer.step()

# Constrain to physical limits
with torch.no_grad():
scenario_params[0].clamp_(60, 130)    # ego_speed
scenario_params[1].clamp_(5, 60)      # cut_in_distance
scenario_params[2].clamp_(-40, 0)     # relative_velocity

return {
"ego_speed": scenario_params[0].item(),
"cut_in_distance": scenario_params[1].item(),
"relative_velocity": scenario_params[2].item(),
"collision_probability": collision_probability.item()
}
```

### Simulation Fidelity Validation

**Key Aspects**:
- Sensor model accuracy (compare to real sensor data)
- Physics accuracy (vehicle dynamics, tire models)
- Traffic behavior realism (AI agent decision-making)
- Environmental effects (rain, fog, lighting)

**Validation Approach**:
1. Collect real-world data (sensor recordings, vehicle telemetry)
2. Replay scenarios in simulation
3. Compare simulation output to real data (sensor images, object detections)
4. Quantify fidelity (SSIM for images, detection F1-score)

## Deliverables

- Simulation test plan with platform selection and parameter ranges
- Scenario execution scripts (Python for CARLA, MATLAB for IPG)
- Parameter sweep results (millions of scenario variants)
- Corner case catalog (challenging scenarios discovered)
- Simulation fidelity validation report
- Coverage metrics dashboard

## Best Practices

- Start with open-source (CARLA) for rapid prototyping, move to commercial for fidelity
- Use deterministic simulation (fixed random seed, synchronous mode) for reproducibility
- Validate simulation fidelity with real-world correlation studies
- Combine random sampling (coverage) with adversarial generation (corner cases)
- Use distributed simulation for scalability (cloud computing)
- Version control scenario definitions (OpenSCENARIO files)
- Automate regression testing (CI/CD integration)

## Tools

- **CARLA**: carla.org, Python API, ScenarioRunner
- **SUMO**: eclipse.dev/sumo, TraCI Python API
- **IPG CarMaker**: ipg-automotive.com, MATLAB/Simulink integration
- **VTD**: hexagon.com/products/virtual-test-drive
- **Scenic**: scenic-lang.readthedocs.io, probabilistic scenario generation
- **Cloud computing**: AWS, Azure, GCP for distributed simulation

## Common Pitfalls

- Over-reliance on simulation without field validation
- Simulation fidelity assumptions not validated
- Insufficient parameter variation (missing edge cases)
- Not accounting for simulation randomness (need multiple runs)
- Ignoring computational cost (billions of km requires optimization)

### sotif-triggering-conditions

## Core Competencies

Expert in identifying and categorizing triggering conditions — specific scenario parameters that expose functional insufficiencies or reasonably foreseeable misuse in ADAS/AD systems.

### Triggering Condition Categories

**Environmental Conditions**:
- Weather: Rain intensity, fog density, snow accumulation, ice, wind
- Lighting: Sun glare angle, nighttime illumination, shadows, backlight
- Road surface: Wet, dry, icy, gravel, potholes
- Visibility: Dust, spray from other vehicles, smoke

**Traffic/Dynamic Objects**:
- Vehicle behavior: Cut-in distance/speed, sudden braking, swerving
- VRU behavior: Pedestrian running into road, cyclist wobble, child behavior
- Object occlusion: Parked vehicles hiding pedestrians, blind corners
- Rare objects: Overturned vehicle, fallen cargo, animals

**Infrastructure**:
- Lane markings: Faded, missing, contradictory (construction), yellow vs white
- Road geometry: Sharp curves, elevation changes, tunnel entry/exit
- Traffic signs/signals: Occluded, damaged, ambiguous placement
- Road features: Merge lanes, toll booths, roundabouts, parking lot aisles

**System State**:
- Sensor degradation: Dirty camera lens, ice on radar, lidar scattering in fog
- Sensor interference: Sun blinding camera, metallic object radar reflection
- Computation load: Multiple objects, complex scene, resource saturation
- Connectivity loss: V2X link drop, map data unavailable

**Human Factors**:
- Driver inattention: Looking at phone, fatigue, distraction
- Mode confusion: Driver unaware system is active/inactive
- Delayed takeover: Insufficient lead time, driver not ready
- Overreliance: Driver removes hands from wheel (L2), reads book

### Systematic Identification Methods

**STPA (System-Theoretic Process Analysis)**:
1. Define system-level safety constraints
2. Identify unsafe control actions (UCAs)
3. Determine causal scenarios for each UCA
4. Map scenarios to triggering conditions

**FMEA (Failure Mode and Effects Analysis)**:
- Analyze each function: What if sensor fails? What if algorithm misdetects?
- Link failure modes to triggering conditions that cause them

**HAZOP (Hazard and Operability Study)**:
- Apply guide words (NO, MORE, LESS, AS WELL AS, PART OF, REVERSE) to parameters
- Example: "NO lane marking" → Triggering condition for lane keeping failure

**Expert Elicitation**:
- Workshops with domain experts (test drivers, engineers, human factors specialists)
- Structured brainstorming using morphological analysis

**Accident Database Mining**:
- Analyze NHTSA FARS, GIDAS, Euro NCAP scenarios
- Extract triggering conditions from real-world crashes

**Field Data Analysis**:
- Review fleet disengagements (ADS takeover events)
- Identify environmental/traffic patterns in edge cases

## Approach

1. **Scope Definition**: Define function and ODD boundaries
2. **Systematic Sweep**: Use STPA/FMEA/HAZOP to identify candidate conditions
3. **Parameterization**: Convert qualitative conditions to measurable parameters
4. **Combination Analysis**: Identify critical multi-factor combinations
5. **Prioritization**: Risk-based ranking (severity × exposure × controllability)
6. **Catalog Construction**: Store in structured database (OpenSCENARIO format)
7. **Test Case Generation**: Generate concrete scenarios for validation

## Example: Lane Keeping Assist (LKA)

**Function**: Keep vehicle centered in lane on highway

**Triggering Condition Analysis**:

| Category | Condition | Parameter | Critical Value |
|----------|-----------|-----------|----------------|
| Environmental | Rain intensity | mm/h | > 10 mm/h (camera degradation) |
| Environmental | Sun glare angle | deg | 5-15° above horizon (camera blindness) |
| Infrastructure | Lane marking contrast | cd/m² | < 3:1 (detection failure) |
| Infrastructure | Road curvature | 1/m | > 0.005 (sensor FOV limit) |
| Traffic | Cut-in lateral offset | m | < 0.3 (insufficient reaction time) |
| System | Camera lens contamination | % coverage | > 30% (degraded detection) |
| Human | Driver hands-off duration | s | > 15 (takeover readiness) |

**Combined Triggering Conditions** (higher risk):
- Rain (8 mm/h) + faded lane markings + curve (R=500m) → Lane departure
- Night + dirty camera + cut-in vehicle → No detection, collision
- Sun glare + construction zone (temporary lane markings) → Wrong lane tracking

## Parameterization Example

```python
# Triggering condition: Cut-in vehicle
class CutInTriggeringCondition:
def __init__(self):
self.lateral_offset = 0.5  # meters from target lane center
self.longitudinal_distance = 30  # meters ahead of ego vehicle
self.relative_velocity = -20  # m/s (cut-in vehicle slower)
self.cut_in_duration = 2.0  # seconds to complete lane change
self.ego_velocity = 30  # m/s (108 km/h)


def is_critical(self, system_reaction_time):
"""Check if triggering condition exposes functional insufficiency"""
time_to_collision = self.longitudinal_distance / abs(self.relative_velocity)
required_decel = (self.relative_velocity ** 2) / (2 * self.longitudinal_distance)


# Critical if reaction time leaves insufficient braking distance
available_distance = self.ego_velocity * system_reaction_time
return (time_to_collision < system_reaction_time + 2.0 or
required_decel > 6.0)  # 6 m/s² = 0.6g, comfort limit

# Usage in scenario generation
tc = CutInTriggeringCondition()
if tc.is_critical(system_reaction_time=0.8):
print("Critical triggering condition identified")
# Generate test scenario with these parameters
```

## Scenario Database Structure

```xml
<!-- OpenSCENARIO format for triggering condition catalog -->
<TriggeringCondition id="TC-LKA-ENV-001">
<Category>Environmental</Category>
<Function>Lane Keeping Assist</Function>
<Description>Low sun glare causing camera saturation</Description>
<Parameters>
<Parameter name="sun_angle_deg" min="5" max="15" unit="degree"/>
<Parameter name="ambient_luminance" min="80000" max="100000" unit="cd/m2"/>
</Parameters>
<ExpectedInsufficency>Camera unable to detect lane markings</ExpectedInsufficency>
<MitigationStrategy>Multi-sensor fusion with radar lane tracking</MitigationStrategy>
<Priority>High</Priority>
</TriggeringCondition>
```

## Deliverables

- Triggering condition catalog (1000+ entries for L2+ ADAS)
- Parameterized triggering condition database (OpenSCENARIO format)
- Risk-prioritized test scenario list
- Traceability matrix: Triggering condition → Hazard → Test case
- Combined triggering condition analysis (multi-factor scenarios)
- Gap analysis: ODD boundaries vs triggering condition coverage

## Best Practices

- Use multiple identification methods (STPA + FMEA + expert elicitation) for coverage
- Parameterize triggering conditions with measurable ranges (not just qualitative)
- Consider combined conditions — single factor may be benign, combination critical
- Revisit catalog after field deployment — add newly discovered conditions
- Align triggering condition parameters with sensor/actuator specifications
- Include human factors expert in identification workshops
- Version control triggering condition database (treat as safety artifact)

## Tools

- **XSTAMPP**: Open-source STPA tool for systematic UCA identification
- **CARLA ScenarioRunner**: Generate test scenarios from triggering conditions
- **OpenSCENARIO Editor**: Build scenario database with parameters
- **Python/Pandas**: Analyze field data to extract triggering condition patterns
- **Safety case tools**: Link triggering conditions to safety arguments (Medini Analyze)

## Integration with SOTIF Process

1. **ODD Definition** → Identify boundary triggering conditions (ODD exit scenarios)
2. **Known Unsafe Analysis** → Map triggering conditions to functional insufficiencies
3. **Validation Planning** → Prioritize test scenarios based on triggering condition risk
4. **Field Monitoring** → Monitor for new triggering conditions in Area 3 (unknown unsafe)

## Common Pitfalls

- Focusing only on nominal conditions, missing edge cases
- Qualitative descriptions without measurable parameters
- Ignoring combined triggering conditions (multi-factor scenarios)
- Not updating catalog based on field learnings
- Insufficient human factors analysis (misuse scenarios)

### sotif-unknown-safe-scenarios

## Core Competencies

Expert in assessing Area 4 (unknown safe) scenarios and establishing residual risk acceptance criteria for ISO 21448 SOTIF compliance.

### Area 4 Definition

**Unknown Safe**: Scenarios where:
- Scenario parameters not fully explored during validation
- No evidence of hazard, but also no proof of safety
- Represents residual uncertainty after SOTIF process
- Accepted risk based on statistical confidence and societal tolerance

**Goal**: Demonstrate that Area 4 residual risk is:
- Sufficiently low (statistically bounded)
- Acceptable per societal norms (comparable to human driver)
- Justified through comprehensive validation effort

### Residual Risk Concept

**Relationship to Four Areas**:
- Area 1 (Known Safe): No risk, verified
- Area 2 (Known Unsafe): Identified and mitigated
- Area 3 (Unknown Unsafe): Minimized through exploration, but never zero
- Area 4 (Unknown Safe): Remaining scenarios with uncertain but acceptable risk

**SOTIF Argument**:
1. Comprehensive triggering condition identification (minimize Area 3)
2. Extensive validation effort (simulation + field testing)
3. Statistical demonstration of low failure rate in validation
4. Acceptance criteria based on societal risk tolerance

## Acceptance Criteria Development

**Benchmarking to Human Driver**:
- Baseline: Human driver fatal crash rate ~ 1 per 100 million km (US 2020)
- Target: AD system should be demonstrably safer (e.g., 10x reduction)
- Metric: Exposure-adjusted crash rate per million km

**Statistical Confidence**:
- Confidence level: 99% typical for safety-critical systems
- Null hypothesis: System crash rate ≥ threshold
- Alternative hypothesis: System crash rate < threshold
- Validation mileage required: Function of target rate and confidence

**Example Calculation**:

```python
import scipy.stats as stats
import numpy as np

def calculate_required_mileage(target_crash_rate_per_million_km,
confidence_level=0.99,
max_observed_crashes=0):
"""
Calculate required validation mileage to demonstrate crash rate below target
with specified confidence level.

Parameters:
- target_crash_rate_per_million_km: Acceptable crash rate (e.g., 0.01)
- confidence_level: Statistical confidence (e.g., 0.99 for 99%)
- max_observed_crashes: Number of crashes allowed in validation (typically 0)

Returns:
- Required mileage in millions of km
"""
# Using Poisson distribution for rare events
# P(X ≤ max_crashes | λ = rate × mileage) ≥ confidence_level

# Solve for mileage: lambda such that P(X ≤ max_crashes) = confidence_level
# If max_crashes = 0: P(X = 0) = exp(-lambda) ≥ confidence_level
# Therefore: lambda ≤ -ln(1 - confidence_level)

lambda_max = -np.log(1 - confidence_level)
required_mileage_million_km = lambda_max / target_crash_rate_per_million_km

return required_mileage_million_km

# Example: Demonstrate crash rate < 0.01 per million km with 99% confidence
target_rate = 0.01  # per million km (10x better than human ~0.1)
confidence = 0.99
mileage = calculate_required_mileage(target_rate, confidence, max_observed_crashes=0)
print(f"Required validation mileage: {mileage:.1f} million km")
# Output: ~460 million km with zero crashes

# More practical: Allow 1 crash
mileage_1_crash = calculate_required_mileage(target_rate, confidence, max_observed_crashes=1)
print(f"With 1 allowed crash: {mileage_1_crash:.1f} million km")
```

**Simulation vs Field Testing**:
- Simulation: Generate billions of km, but fidelity limits confidence
- Field testing: High fidelity, but expensive and time-consuming
- Hybrid approach: Simulation for coverage, field for validation

**UN ECE R157 Example (ALKS)**:
- 60 km test track validation for basic scenarios
- Type approval requires demonstration of ODD compliance
- Ongoing field monitoring to confirm residual risk assumptions

## Risk Evaluation Framework

**Quantitative Metrics**:
- Crash rate per million km (overall safety)
- False positive rate (unnecessary interventions, mode confusion)
- Disengagement rate (system reliability)
- Takeover request frequency (driver burden)

**Qualitative Assessment**:
- Comparison to human driver performance in same ODD
- Analysis of crash severity distribution (injury vs property damage)
- Evaluation of crash preventability (unavoidable scenarios)

**Acceptable Risk Thresholds**:

| Severity | Human Baseline (US) | Target for AD | Metric |
|----------|---------------------|---------------|--------|
| Fatal | 1.1 per 100M veh-miles | < 0.5 per 100M | 2x safer |
| Injury | 60 per 100M veh-miles | < 30 per 100M | 2x safer |
| Property damage | 100 per 100M veh-miles | < 50 per 100M | 2x safer |

## Residual Risk Argumentation

**Safety Case Structure**:

1. **Claim**: System residual risk (Area 4) is acceptable
2. **Evidence**:
- Validation mileage (simulation + field)
- Observed crash/disengagement rates
- Comprehensive triggering condition catalog
3. **Argument**:
- Extensive exploration minimized Area 3
- Statistical analysis shows low failure rate
- Performance exceeds human driver baseline
4. **Rebuttals**:
- Simulation limitations acknowledged, mitigated by field testing
- ODD restrictions documented, enforced by system

**Example Argument**:
- Claim: ALKS system residual risk acceptable for highway operation 0-60 km/h
- Evidence:
- 10 billion km simulation with 150 crashes identified and mitigated
- 5 million km field testing with 2 safety driver interventions
- Intervention rate: 0.4 per million km
- Argument:
- Intervention rate << human crash rate (1 per million km)
- ODD restrictions (highway, low speed) reduce exposure
- System deactivates outside ODD (fail-safe)
- Rebuttal:
- Simulation may not capture all real-world complexity → Field testing validates
- Rare events not observed → Conservative ODD and continuous monitoring

## Statistical Methods

**Binomial Confidence Interval**:

```python
import scipy.stats as stats

def binomial_confidence_interval(num_failures, num_trials, confidence=0.99):
"""
Calculate upper bound on failure rate with specified confidence.

Parameters:
- num_failures: Observed failures (crashes, disengagements)
- num_trials: Number of scenarios tested
- confidence: Confidence level (e.g., 0.99)

Returns:
- Upper bound on failure rate
"""
# Using Wilson score interval (better for small counts)
p_hat = num_failures / num_trials
z = stats.norm.ppf((1 + confidence) / 2)

denominator = 1 + z**2 / num_trials
center = (p_hat + z**2 / (2 * num_trials)) / denominator
margin = z * np.sqrt(p_hat * (1 - p_hat) / num_trials + z**2 / (4 * num_trials**2)) / denominator

upper_bound = center + margin
return upper_bound

# Example: 2 failures in 5 million km (each km is a "trial")
failures = 2
trials = 5_000_000
upper_bound = binomial_confidence_interval(failures, trials, confidence=0.99)
print(f"Upper bound on failure rate: {upper_bound * 1e6:.2f} per million km with 99% confidence")
```

**Bayesian Approach**:
- Prior: Pessimistic assumption about failure rate
- Likelihood: Observed data (validation results)
- Posterior: Updated belief about failure rate
- Advantage: Incorporate prior knowledge, update with evidence

## Deliverables

- Residual risk assessment report
- Statistical validation plan (mileage targets, acceptance criteria)
- Validation results summary (simulation + field)
- Safety case argument for Area 4 acceptability
- Comparison to human driver baseline
- Continuous monitoring plan for post-deployment risk tracking

## Best Practices

- Define acceptance criteria early (avoid post-hoc rationalization)
- Use conservative estimates (do not overstate validation coverage)
- Benchmark to human performance in same ODD (fair comparison)
- Consider crash severity, not just frequency
- Account for ODD restrictions in risk calculation (reduced exposure)
- Plan for continuous monitoring (residual risk may emerge post-deployment)
- Document all assumptions in safety case

## Regulatory Considerations

**UN ECE R157 (ALKS)**:
- No explicit statistical mileage requirement
- Requires demonstration of ODD compliance through testing
- Ongoing monitoring and software update process expected

**ISO 21448**:
- Does not mandate specific acceptance criteria
- Requires demonstration of "sufficient" residual risk reduction
- Acceptance criteria should align with applicable regulations and societal norms

**Future Trends**:
- Moving toward statistical performance requirements (e.g., NHTSA AV framework)
- Emphasis on post-deployment monitoring and continuous improvement
- Scenario-based type approval (demonstrate performance in catalog)

## Integration with SOTIF Process

1. **ODD Definition** → Restricts exposure, reduces residual risk
2. **Area 1/2/3 Analysis** → Minimizes unknown unsafe (Area 3)
3. **Validation** → Provides statistical evidence for Area 4 assessment
4. **Residual Risk Evaluation** → Demonstrates acceptability
5. **Field Monitoring** → Confirms residual risk assumptions hold

## Common Pitfalls

- Claiming zero residual risk (impossible to prove)
- Insufficient validation mileage for statistical confidence
- Ignoring ODD restrictions in risk calculation
- Not comparing to human driver in same ODD (unfair baseline)
- Post-hoc rationalization of acceptance criteria (should be defined upfront)

### sotif-unknown-unsafe-scenarios

## Core Competencies

Expert in discovering Area 3 (unknown unsafe) scenarios — hazardous situations not identified during design but discovered through extensive testing, simulation, or field operation.

### Area 3 Definition

**Unknown Unsafe**: Scenarios where:
- Hazard exists but was not identified during analysis
- Discovered through validation activities or field deployment
- Once discovered, moved to Area 2 (known unsafe) for mitigation
- Represents residual risk in SOTIF safety case

**Goal**: Systematically reduce Area 3 through:
- Comprehensive simulation-based exploration
- Statistical field testing
- Fleet monitoring and event analysis
- Adversarial testing techniques

### Discovery Methods

**Simulation-Based Exploration**:
- Monte Carlo parameter variation (billions of scenarios)
- Adversarial scenario generation
- Rare event simulation (importance sampling)
- Search-based testing (genetic algorithms)

**Field Testing**:
- Extensive mileage accumulation (millions of km)
- Diverse geographic/environmental coverage
- Critical scenario triggering (safety driver intervention)
- Disengagement analysis

**Fleet Monitoring**:
- Continuous data collection from deployed vehicles
- Anomaly detection algorithms
- Near-miss event identification
- Shadow mode testing (parallel execution without control)

**Human-in-the-Loop**:
- Expert test drivers exploring edge cases
- Driving simulator studies
- Crowdsourced scenario reporting

## Simulation-Based Discovery

**Monte Carlo Parameter Sweep**:

```python
import numpy as np
from typing import List, Tuple

class Area3Explorer:
"""Discover unknown unsafe scenarios through simulation"""

def __init__(self, num_scenarios=1000000):
self.num_scenarios = num_scenarios
self.discovered_unsafe = []


def generate_random_scenario(self) -> dict:
"""Generate scenario with random parameters across full physical range"""
return {
"ego_speed": np.random.uniform(0, 150),  # km/h
"lead_vehicle_speed": np.random.uniform(0, 150),
"lead_vehicle_distance": np.random.uniform(5, 200),  # meters
"cut_in_lateral_offset": np.random.uniform(0, 3.5),  # meters
"cut_in_speed": np.random.uniform(-30, 30),  # relative m/s
"road_curvature": np.random.uniform(0, 0.01),  # 1/m
"rain_intensity": np.random.uniform(0, 50),  # mm/h
"visibility": np.random.uniform(10, 500),  # meters
"sun_angle": np.random.uniform(0, 90),  # degrees
"road_friction": np.random.uniform(0.3, 1.0),
}


def simulate_scenario(self, scenario: dict) -> Tuple[bool, str]:
"""
Simulate scenario and detect if unsafe
Returns (is_unsafe, failure_mode)
"""
# Placeholder: Replace with actual simulation
# Returns True if collision/lane departure/other hazard occurred
is_unsafe = False
failure_mode = ""

# Example: Time-to-collision check
relative_speed = scenario["ego_speed"]/3.6 - scenario["lead_vehicle_speed"]/3.6
if relative_speed > 0:
ttc = scenario["lead_vehicle_distance"] / relative_speed
if ttc < 1.5:  # Critical TTC threshold
is_unsafe = True
failure_mode = f"Insufficient TTC: {ttc:.2f}s"

# Example: Sensor performance check
if scenario["rain_intensity"] > 20 and scenario["visibility"] < 100:
detection_range = 50  # degraded sensor
if scenario["lead_vehicle_distance"] > detection_range:
is_unsafe = True
failure_mode = "Sensor blind in heavy rain"

return is_unsafe, failure_mode


def explore(self) -> List[dict]:
"""Run Monte Carlo exploration to discover Area 3 scenarios"""
for i in range(self.num_scenarios):
scenario = self.generate_random_scenario()
is_unsafe, failure_mode = self.simulate_scenario(scenario)

if is_unsafe:
# Unknown unsafe scenario discovered!
self.discovered_unsafe.append({
"scenario": scenario,
"failure_mode": failure_mode,
"iteration": i
})

return self.discovered_unsafe


# Usage
explorer = Area3Explorer(num_scenarios=1000000)
unsafe_scenarios = explorer.explore()
print(f"Discovered {len(unsafe_scenarios)} unknown unsafe scenarios in {explorer.num_scenarios} simulations")

# Analyze discovered scenarios to identify patterns
for scenario_data in unsafe_scenarios[:10]:
print(f"Failure: {scenario_data['failure_mode']}")
print(f"Scenario: {scenario_data['scenario']}")
```

**Adversarial Scenario Generation**:

```python
import torch
import torch.nn as nn
import torch.optim as optim

class AdversarialScenarioGenerator:
"""Generate scenarios that maximize system failure likelihood"""

def __init__(self, system_model):
self.system_model = system_model  # Black-box or surrogate model


def optimize_for_failure(self, initial_scenario, num_iterations=100):
"""
Use gradient-based optimization to find worst-case scenario
"""
# Convert scenario to tensor
scenario_params = torch.tensor([
initial_scenario["ego_speed"],
initial_scenario["lead_vehicle_distance"],
initial_scenario["cut_in_speed"],
], requires_grad=True)

optimizer = optim.Adam([scenario_params], lr=0.1)

for iteration in range(num_iterations):
optimizer.zero_grad()

# Simulate system response
collision_risk = self.system_model(scenario_params)

# Maximize collision risk (minimize negative risk)
loss = -collision_risk
loss.backward()
optimizer.step()

# Constrain parameters to physical ranges
with torch.no_grad():
scenario_params[0].clamp_(0, 150)  # speed
scenario_params[1].clamp_(5, 200)  # distance
scenario_params[2].clamp_(-30, 30)  # relative speed

# Return adversarial scenario
return {
"ego_speed": scenario_params[0].item(),
"lead_vehicle_distance": scenario_params[1].item(),
"cut_in_speed": scenario_params[2].item(),
"collision_risk": collision_risk.item()
}
```

## Field Data Analysis

**Disengagement Mining**:
- Analyze all safety driver interventions
- Cluster disengagement scenarios by similarity
- Identify common patterns (new triggering conditions)
- Investigate near-miss events (TTC < threshold)

**Shadow Mode Testing**:
- Run new algorithm version in parallel without actuation
- Compare behavior to deployed version
- Flag divergences (potential unknown unsafe in new version)

**Anomaly Detection**:

```python
from sklearn.ensemble import IsolationForest
import pandas as pd

class FieldDataAnomalyDetector:
"""Detect unusual scenarios in fleet data"""

def __init__(self):
self.model = IsolationForest(contamination=0.01, random_state=42)


def fit(self, normal_scenario_data: pd.DataFrame):
"""Train on known safe (Area 1) scenarios"""
self.model.fit(normal_scenario_data)


def detect_anomalies(self, field_data: pd.DataFrame) -> pd.DataFrame:
"""Identify scenarios that deviate from normal patterns"""
predictions = self.model.predict(field_data)

# -1 indicates anomaly, 1 indicates normal
anomalies = field_data[predictions == -1]

return anomalies

# Usage
detector = FieldDataAnomalyDetector()
detector.fit(area1_training_data)

# Analyze one day of fleet data
anomalous_scenarios = detector.detect_anomalies(fleet_data_today)
print(f"Found {len(anomalous_scenarios)} anomalous scenarios for manual review")
```

## Genetic Algorithm Search

```python
import random
from deap import base, creator, tools, algorithms

def evaluate_scenario_criticality(scenario):
"""
Fitness function: Return criticality score (higher = more critical)
"""
# Simulate scenario and return inverse of safety margin
# Example: 1 / time_to_collision
ttc = simulate_and_get_ttc(scenario)
return (1.0 / ttc,)  # Return tuple for DEAP framework

# Setup genetic algorithm
creator.create("FitnessMax", base.Fitness, weights=(1.0,))
creator.create("Individual", list, fitness=creator.FitnessMax)

toolbox = base.Toolbox()
toolbox.register("attr_speed", random.uniform, 60, 120)
toolbox.register("attr_distance", random.uniform, 10, 150)
toolbox.register("individual", tools.initCycle, creator.Individual,
(toolbox.attr_speed, toolbox.attr_distance), n=1)
toolbox.register("population", tools.initRepeat, list, toolbox.individual)
toolbox.register("evaluate", evaluate_scenario_criticality)
toolbox.register("mate", tools.cxTwoPoint)
toolbox.register("mutate", tools.mutGaussian, mu=0, sigma=10, indpb=0.2)
toolbox.register("select", tools.selTournament, tournsize=3)

# Run genetic algorithm to find critical scenarios
population = toolbox.population(n=100)
result, log = algorithms.eaSimple(population, toolbox,
cxpb=0.5, mutpb=0.2, ngen=50,
verbose=False)

# Extract most critical scenarios found
critical_scenarios = tools.selBest(result, k=10)
```

## Deliverables

- Unknown unsafe scenario discovery report (from simulation/field data)
- Scenario database updated with newly discovered Area 3 scenarios
- Root cause analysis for each discovered scenario
- Mitigation proposals (move to Area 2 with mitigations)
- Statistical estimate of remaining Area 3 (residual unknown risk)
- Continuous monitoring plan for post-deployment discovery

## Best Practices

- Combine multiple discovery methods (simulation + field + adversarial)
- Use importance sampling to focus on rare but critical events
- Investigate all safety driver disengagements (not just crashes)
- Continuously update scenario database with field learnings
- Re-run Area 3 exploration after system design changes
- Use surrogate models to accelerate search-based testing
- Validate discovered scenarios on real system before declaring unsafe

## Statistical Acceptance

To claim sufficient Area 3 reduction, demonstrate:
- X million simulation km without new critical scenario discovered
- Y million field test km with disengagement rate below threshold
- Z fleet vehicle-years with no safety-critical events

Example (UN ECE R157 ALKS):
- Simulation: 10 billion km equivalent
- Field testing: 5 million km
- Fleet monitoring: 100,000 vehicle operating hours

## Integration with SOTIF Process

1. **Discovery**: Use methods above to find unknown unsafe scenarios
2. **Classification**: Characterize scenario, determine severity
3. **Root Cause**: Analyze functional insufficiency or misuse
4. **Move to Area 2**: Add to known unsafe catalog
5. **Mitigation**: Develop countermeasures (design, ODD, HMI)
6. **Verification**: Validate mitigation effectiveness
7. **Repeat**: Continue exploration to reduce remaining Area 3

## Tools

- **CARLA**: Open-source simulator with Python API for scenario generation
- **Scenic**: Probabilistic programming language for scenario generation
- **CommonRoad**: Benchmark scenarios and motion planning verification
- **AutoFuzz**: Automated test case generation for autonomous systems
- **Baidu Apollo**: Shadow mode and field monitoring infrastructure

## Common Pitfalls

- Over-reliance on simulation (may not capture all real-world complexity)
- Insufficient parameter space coverage (missing critical combinations)
- Ignoring low-probability but high-severity scenarios
- Not investigating near-misses (only analyzing actual failures)
- Stopping exploration too early (statistical confidence insufficient)

### sotif-validation-strategy

## Core Competencies

Expert in developing comprehensive SOTIF validation strategies that combine simulation-based testing (billions of km), field testing (statistical significance), and coverage metrics to demonstrate acceptable residual risk.

### Validation Challenges

**The Validation Gap**:
- Human driver: ~1 fatal crash per 100 million miles (US baseline)
- To prove 2x safer: Need to drive 200+ million miles with zero fatalities (impractical)
- Solution: Combine simulation (scale) + field testing (realism) + coverage metrics

**Key Questions**:
- How much testing is enough?
- How to balance simulation (cheap, scalable) vs field (expensive, realistic)?
- What coverage metrics ensure sufficient exploration?
- How to extrapolate from validation to real-world performance?

### Validation Strategy Components

**1. Simulation-Based Testing** (Scale):
- Billions of km equivalent
- Systematic parameter variation (scenario catalog)
- Corner case discovery (adversarial generation)
- Regression testing for software updates

**2. Proving Ground Testing** (Control):
- Reproducible test scenarios
- Instrumented environment
- Safety drivers for critical scenarios
- Hardware-in-the-loop validation

**3. Public Road Testing** (Realism):
- Naturalistic driving conditions
- Geographic and temporal diversity
- Disengagement analysis
- Shadow mode testing (parallel execution)

**4. Coverage Metrics** (Completeness):
- Scenario coverage (catalog completeness)
- Parameter space coverage (distribution matching)
- ODD boundary testing (edge of operational domain)
- Triggering condition coverage

## Statistical Mileage Calculation

```python
import scipy.stats as stats
import numpy as np

class ValidationMileageCalculator:
"""Calculate required validation mileage for SOTIF confidence"""

def __init__(self, target_crash_rate_per_million_km=0.1,
confidence_level=0.99):
"""
Parameters:
- target_crash_rate_per_million_km: Acceptable crash rate (e.g., 0.1 = 10x better than human)
- confidence_level: Statistical confidence (e.g., 0.99 for 99%)
"""
self.target_rate = target_crash_rate_per_million_km
self.confidence = confidence_level


def calculate_mileage_zero_crash(self):
"""
Calculate mileage required with zero crashes observed

Uses Poisson distribution: P(X=0 | λ) = exp(-λ) ≥ confidence
"""
lambda_max = -np.log(1 - self.confidence)
required_mileage = lambda_max / self.target_rate
return required_mileage


def calculate_mileage_n_crashes(self, max_allowed_crashes):
"""
Calculate mileage with N allowed crashes

Uses Poisson cumulative distribution
"""
from scipy.optimize import fsolve

def equation(lambda_val):
return stats.poisson.cdf(max_allowed_crashes, lambda_val) - self.confidence

lambda_max = fsolve(equation, max_allowed_crashes + 2)[0]
required_mileage = lambda_max / self.target_rate
return required_mileage


def simulation_equivalence_factor(self, simulation_fidelity=0.8):
"""
Adjust simulation mileage based on fidelity

Lower fidelity requires more simulation miles to equal real-world mile
"""
equivalence = simulation_fidelity ** 2  # Non-linear degradation
return 1 / equivalence

# Example: Calculate mileage targets
calculator = ValidationMileageCalculator(target_crash_rate_per_million_km=0.1, confidence_level=0.99)

mileage_zero = calculator.calculate_mileage_zero_crash()
print(f"Required mileage (0 crashes): {mileage_zero:.1f} million km")

mileage_one = calculator.calculate_mileage_n_crashes(max_allowed_crashes=1)
print(f"Required mileage (1 crash allowed): {mileage_one:.1f} million km")

# Simulation equivalence
sim_factor = calculator.simulation_equivalence_factor(simulation_fidelity=0.7)
sim_mileage = mileage_zero * sim_factor
print(f"Equivalent simulation mileage (70% fidelity): {sim_mileage:.1f} million km")
```

## Hybrid Validation Approach

**Recommended Split**:
- Simulation: 95% of total mileage (e.g., 10 billion km)
- Field testing: 5% (e.g., 5 million km)

**Rationale**:
- Simulation provides scale for rare event coverage
- Field testing validates simulation assumptions and realism
- Hybrid approach balances cost and confidence

**Example Validation Plan** (L2 ADAS):

| Method | Mileage | Purpose | Duration |
|--------|---------|---------|----------|
| Simulation (CARLA) | 10 billion km | Parameter sweep, corner cases | 6 months |
| Proving ground | 100,000 km | Regression, controlled tests | 3 months |
| Public road | 5 million km | Naturalistic validation | 12 months |
| Shadow mode | 50 million km | Parallel execution, no control | Ongoing |

## Coverage Metrics

**Scenario Coverage**:

```python
class ScenarioCoverageAnalyzer:
"""Analyze coverage of scenario catalog"""

def __init__(self, scenario_catalog):
"""
Parameters:
- scenario_catalog: List of scenarios with parameters
"""
self.catalog = scenario_catalog
self.executed_scenarios = []


def add_executed_scenario(self, scenario):
"""Record scenario execution"""
self.executed_scenarios.append(scenario)


def calculate_coverage(self):
"""
Calculate percentage of catalog scenarios executed
"""
executed_ids = set(s['id'] for s in self.executed_scenarios)
catalog_ids = set(s['id'] for s in self.catalog)
coverage = len(executed_ids) / len(catalog_ids)
return coverage


def identify_gaps(self):
"""
Identify untested scenarios
"""
executed_ids = set(s['id'] for s in self.executed_scenarios)
catalog_ids = set(s['id'] for s in self.catalog)
untested = catalog_ids - executed_ids
return [s for s in self.catalog if s['id'] in untested]


def calculate_parameter_coverage(self, parameter_name):
"""
Analyze coverage of specific parameter range
"""
executed_values = [s['parameters'][parameter_name]
for s in self.executed_scenarios
if parameter_name in s['parameters']]

# Calculate histogram bins
hist, bins = np.histogram(executed_values, bins=10)

# Identify under-covered bins (< 5% of samples)
total_samples = len(executed_values)
under_covered_bins = [(bins[i], bins[i+1])
for i, count in enumerate(hist)
if count < 0.05 * total_samples]

return {
"total_samples": total_samples,
"histogram": hist,
"bins": bins,
"under_covered_bins": under_covered_bins
}

# Example usage
catalog = [
{'id': 'SOTIF-001', 'parameters': {'ego_speed': 100, 'distance': 50}},
{'id': 'SOTIF-002', 'parameters': {'ego_speed': 80, 'distance': 30}},
# ... 1000+ scenarios
]

coverage_analyzer = ScenarioCoverageAnalyzer(catalog)

# Simulate test execution
for scenario in catalog[:800]:  # Executed 800 out of 1000
coverage_analyzer.add_executed_scenario(scenario)

coverage = coverage_analyzer.calculate_coverage()
print(f"Scenario coverage: {coverage*100:.1f}%")

gaps = coverage_analyzer.identify_gaps()
print(f"Untested scenarios: {len(gaps)}")
```

**ODD Boundary Coverage**:
- Test at ODD limits (not just nominal center)
- Example: If ODD is 0-120 km/h, test at 0, 10, 110, 120 km/h
- Verify graceful transition at ODD exit

## Deliverables

- SOTIF validation plan with mileage targets
- Scenario catalog with coverage requirements
- Hybrid validation approach (simulation + field split)
- Statistical acceptance criteria
- Coverage metrics dashboard (scenario, parameter, ODD boundary)
- Validation report with results and confidence analysis
- Traceability: Scenario → Test case → Execution → Result

## Best Practices

- Define acceptance criteria before testing (avoid post-hoc rationalization)
- Use risk-based prioritization (test high-severity scenarios first)
- Combine multiple validation methods (simulation + proving ground + field)
- Monitor coverage metrics continuously (identify gaps early)
- Validate simulation fidelity with field testing correlation
- Update scenario catalog with field learnings
- Plan for continuous validation (ongoing monitoring post-deployment)
- Document all assumptions (simulation fidelity, statistical model)

## Tools

- **Simulation**: CARLA, IPG CarMaker, VTD, SUMO
- **Scenario management**: OpenSCENARIO database, custom tools
- **Coverage analysis**: Python (matplotlib, seaborn), MATLAB
- **Statistical analysis**: SciPy, R, Bayesian frameworks
- **Field data management**: Cloud platforms (AWS, Azure)
- **Reporting**: Safety case tools (Medini Analyze, ASCE)

## Regulatory Examples

**UN ECE R157 (ALKS L3)**:
- No specific mileage mandate
- Requires test scenarios covering ODD
- 60 km test track validation minimum
- Field monitoring post-deployment

**NHTSA AV Framework** (proposed):
- Performance-based metrics (crash rate targets)
- Simulation + field testing hybrid approach
- Statistical confidence requirements

**Waymo Safety Report** (industry example):
- 20+ million miles public road
- 15+ billion miles simulation
- Structured scenario-based testing

## Integration with SOTIF Process

1. **Triggering Condition Identification** → Scenario catalog
2. **Known Unsafe Mitigation** → Verification tests
3. **Unknown Unsafe Exploration** → Simulation sweeps, field testing
4. **Validation Execution** → Scenario coverage, mileage accumulation
5. **Residual Risk Evaluation** → Statistical analysis of results

## Common Pitfalls

- Insufficient mileage for statistical confidence
- Over-reliance on simulation (not validating realism)
- Testing only nominal conditions (missing ODD boundaries)
- Not tracking coverage metrics (gaps in validation)
- Post-hoc acceptance criteria (biased by results)
- Not updating catalog with field learnings
