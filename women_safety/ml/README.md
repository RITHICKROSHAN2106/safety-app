AI Danger Prediction Training Starter

This folder contains a starter pipeline for training and exporting the model used by:
- lib/services/ai_danger_prediction_service.dart

Contents
- requirements.txt: Python dependencies
- data/danger_training_schema.csv: required CSV header
- data/sample_training_data.csv: tiny synthetic sample
- data/raw_incidents_template.csv: template for real incident logs
- build_realtime_training_data.py: builds model-ready dataset from real incident logs
- train_danger_model.py: train + evaluate + export TFLite
- validate_feature_order.py: verifies runtime feature order alignment

Runtime feature order (must match exactly)
1. hour
2. isNight
3. isWeekend
4. latitude
5. longitude
6. incidentHistory
7. populationDensity
8. lighting

Target
- danger_score in range 0..10
- training script scales target to 0..1 for sigmoid output, then app scales back to 0..10

Quick start
1) Create environment and install deps
   pip install -r requirements.txt

2) Validate feature order against app runtime code
   python validate_feature_order.py

3) (Recommended) Build real-time aligned training dataset from incidents CSV
   python build_realtime_training_data.py --input data/raw_incidents_template.csv --output data/realtime_training_data.csv --use-sun-api

4) Train model and export TFLite
   python train_danger_model.py --data data/realtime_training_data.csv

Alternative quick test with synthetic sample
   python train_danger_model.py --data data/sample_training_data.csv

Default outputs
- Keras model: artifacts/danger_model.keras
- TFLite model: ../assets/models/danger_prediction_model.tflite

Production notes
- Replace sample data with real labeled safety data.
- Keep training feature engineering consistent with app runtime.
- Avoid using random or synthetic proxies for production quality metrics.
- Evaluate city-wise calibration and false-negative rate for high-risk zones.

Real-time dataset builder notes
- Input CSV requires: timestamp, latitude, longitude.
- Optional columns supported: incident_type, severity, danger_score.
- If danger_score is absent, labels are derived from severity or incident_type mapping.
- Lighting can be enriched using Open-Meteo sunrise/sunset API with --use-sun-api.
