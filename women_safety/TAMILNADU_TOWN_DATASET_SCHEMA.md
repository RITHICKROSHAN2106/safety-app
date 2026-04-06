# Tamil Nadu Town Safety Dataset Schema

This app now reads town safety datasets from Firestore collection:

- `tn_town_safety_datasets`

Each document should represent one town.

## Document ID

- Use normalized town name (example: `coimbatore`, `tiruppur`, `kumbakonam`)

## Required fields

```json
{
  "town": "Kumbakonam",
  "center": {"_type": "GeoPoint", "latitude": 10.9601, "longitude": 79.3774},
  "riskyAreas": [
    {
      "name": "Bus Stand Rear Access",
      "latitude": 10.9634,
      "longitude": 79.3759,
      "risk": "HIGH",
      "reason": "Low lighting and isolated movement after late evening"
    }
  ],
  "policeStations": [
    {
      "name": "Kumbakonam East Police Station",
      "latitude": 10.9598,
      "longitude": 79.3790,
      "type": "Police Station",
      "contact": "+91 100"
    }
  ],
  "governmentSources": [
    {
      "name": "Tamil Nadu Police",
      "url": "https://eservices.tnpolice.gov.in",
      "dataset": "Station and jurisdiction data",
      "integrationMode": "curated_snapshot"
    },
    {
      "name": "Open Government Data (India)",
      "url": "https://data.gov.in",
      "dataset": "District/town public safety records",
      "integrationMode": "curated_snapshot"
    }
  ]
}
```

## Supported field alternatives

- Instead of `center` GeoPoint, you can provide:
  - `latitude`
  - `longitude`

## Notes

- `risk` values should be one of: `LOW`, `MEDIUM`, `HIGH`.
- Use real official references while curating.
- Keep coordinates accurate; hotspot warning depends on distance calculations.
- The app merges this collection with built-in fallback city datasets.

## Minimum bulk import target

To cover all Tamil Nadu towns, add one document per town in `tn_town_safety_datasets`.
The app automatically uses nearest town dataset from current GPS location.
