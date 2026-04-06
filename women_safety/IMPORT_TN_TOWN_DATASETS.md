# Import All Tamil Nadu Town Datasets

This guide imports town-level safety datasets into Firestore so ML danger prediction can cover all Tamil Nadu towns by GPS.

## Files added

- data/tn_town_safety_dataset_template.json
- tools/import_tn_town_datasets.js

## 1. Prepare your dataset

Edit:

- data/tn_town_safety_dataset_template.json

Add one object per town.

Required fields per town:

- town
- latitude
- longitude
- riskyAreas[]
- policeStations[]

Optional:

- governmentSources[]

## 2. Install importer dependency

From women_safety folder:

```powershell
npm init -y
npm install firebase-admin
```

## 3. Set Firebase service account auth

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

## 4. Run bulk import

```powershell
node tools/import_tn_town_datasets.js data/tn_town_safety_dataset_template.json
```

## 5. Firestore target collection

The importer writes to:

- tn_town_safety_datasets

Each document id is normalized from the town name.

## 6. Validate in app

- Open ML Danger Prediction screen.
- App uses current GPS.
- It auto-resolves nearest town dataset.
- Hotspot warnings and route insights should now reflect imported town data.

## Notes

- Existing built-in city snapshots remain as fallback.
- Imported town datasets override/extend fallback behavior automatically.
- Keep source provenance in governmentSources for traceability.
