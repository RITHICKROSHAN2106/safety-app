import re
from pathlib import Path

EXPECTED_ORDER = [
    "hour",
    "isNight",
    "isWeekend",
    "latitude",
    "longitude",
    "incidentHistory",
    "populationDensity",
    "lighting",
]

DEFAULT_DART_FILE = Path("../lib/services/ai_danger_prediction_service.dart")


def extract_runtime_order(dart_source: str) -> list[str]:
    block_match = re.search(
        r"Float32List\.fromList\s*\(\s*\[(.*?)\]\s*\)",
        dart_source,
        flags=re.S,
    )
    if not block_match:
        raise ValueError("Could not find Float32List.fromList(...) feature block")

    block = block_match.group(1)
    return re.findall(r"features\['([A-Za-z0-9_]+)'\]!", block)


def main() -> None:
    dart_path = DEFAULT_DART_FILE
    if not dart_path.exists():
        raise FileNotFoundError(f"Dart file not found: {dart_path}")

    runtime_order = extract_runtime_order(dart_path.read_text(encoding="utf-8"))

    print("Expected order:", EXPECTED_ORDER)
    print("Runtime order :", runtime_order)

    if runtime_order != EXPECTED_ORDER:
        raise SystemExit(
            "Feature order mismatch. Update training pipeline or app runtime feature mapping."
        )

    print("✅ Feature order matches runtime inference order")


if __name__ == "__main__":
    main()
