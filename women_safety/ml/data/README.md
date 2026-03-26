This folder contains training data for AI danger prediction.

Files
- danger_training_schema.csv: header/schema reference
- sample_training_data.csv: tiny synthetic sample for script validation only
- raw_incidents_template.csv: input template for real incident logs
- realtime_training_data.csv: generated model-ready dataset (created by build script)

Important
- Replace sample data with real labeled data before training production models.
- Keep feature definitions aligned with lib/services/ai_danger_prediction_service.dart.
- Use build_realtime_training_data.py to transform incident logs into the model feature schema.
