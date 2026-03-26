import argparse
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd
import requests

REQUIRED_INPUT_COLUMNS = ["timestamp", "latitude", "longitude"]
OUTPUT_COLUMNS = [
    "hour",
    "is_night",
    "is_weekend",
    "latitude_norm",
    "longitude_norm",
    "incident_history",
    "population_density",
    "lighting",
    "danger_score",
]

SEVERITY_MAP = {
    "harassment": 7.0,
    "stalking": 7.5,
    "assault": 9.0,
    "snatching": 6.5,
    "unsafe": 5.5,
    "suspicious": 5.0,
    "theft": 5.8,
    "verbal_abuse": 6.2,
    "eve_teasing": 6.8,
    "other": 5.2,
}


def _normalize_lat(lat: float) -> float:
    return float(np.clip(lat / 90.0, -1.0, 1.0))


def _normalize_lng(lng: float) -> float:
    return float(np.clip(lng / 180.0, -1.0, 1.0))


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    dlat = np.radians(lat2 - lat1)
    dlon = np.radians(lon2 - lon1)
    a = np.sin(dlat / 2) ** 2 + np.cos(np.radians(lat1)) * np.cos(np.radians(lat2)) * np.sin(dlon / 2) ** 2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    return float(r * c)


def _parse_timestamp(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["timestamp"] = pd.to_datetime(out["timestamp"], utc=True, errors="coerce")
    out = out.dropna(subset=["timestamp"])
    return out


def _fetch_sunrise_sunset(lat: float, lon: float, date_yyyy_mm_dd: str, cache: dict) -> tuple[Optional[pd.Timestamp], Optional[pd.Timestamp]]:
    key = (round(lat, 2), round(lon, 2), date_yyyy_mm_dd)
    if key in cache:
        return cache[key]

    url = (
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat:.4f}&longitude={lon:.4f}&daily=sunrise,sunset&timezone=UTC&start_date={date_yyyy_mm_dd}&end_date={date_yyyy_mm_dd}"
    )
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        sunrise_str = data.get("daily", {}).get("sunrise", [None])[0]
        sunset_str = data.get("daily", {}).get("sunset", [None])[0]
        sunrise = pd.to_datetime(sunrise_str, utc=True) if sunrise_str else None
        sunset = pd.to_datetime(sunset_str, utc=True) if sunset_str else None
        cache[key] = (sunrise, sunset)
        return sunrise, sunset
    except Exception:
        cache[key] = (None, None)
        return None, None


def _derive_lighting(ts: pd.Timestamp, lat: float, lon: float, use_api: bool, sun_cache: dict) -> float:
    if use_api:
        date_key = ts.strftime("%Y-%m-%d")
        sunrise, sunset = _fetch_sunrise_sunset(lat, lon, date_key, sun_cache)
        if sunrise is not None and sunset is not None:
            if ts < sunrise or ts > sunset:
                return 0.3
            return 1.0

    hour = ts.hour
    if hour >= 20 or hour <= 5:
        return 0.3
    if hour <= 7 or hour >= 18:
        return 0.6
    return 1.0


def _incident_history_feature(df: pd.DataFrame, radius_km: float = 1.0, window_hours: int = 24) -> pd.Series:
    counts = []
    timestamps = df["timestamp"].tolist()
    lats = df["latitude"].astype(float).tolist()
    lngs = df["longitude"].astype(float).tolist()

    for i in range(len(df)):
        current_ts = timestamps[i]
        c = 0
        for j in range(len(df)):
            if i == j:
                continue
            if timestamps[j] > current_ts:
                continue
            dt_hours = (current_ts - timestamps[j]).total_seconds() / 3600.0
            if dt_hours > window_hours:
                continue
            dist = _haversine_km(lats[i], lngs[i], lats[j], lngs[j])
            if dist <= radius_km:
                c += 1
        counts.append(c)

    max_count = max(counts) if counts else 1
    max_count = max(max_count, 1)
    normalized = [min(1.0, c / max_count) for c in counts]
    return pd.Series(normalized, index=df.index)


def _population_density_proxy(df: pd.DataFrame, radius_km: float = 2.0) -> pd.Series:
    lats = df["latitude"].astype(float).tolist()
    lngs = df["longitude"].astype(float).tolist()
    densities = []

    for i in range(len(df)):
        neighbors = 0
        for j in range(len(df)):
            if i == j:
                continue
            if _haversine_km(lats[i], lngs[i], lats[j], lngs[j]) <= radius_km:
                neighbors += 1
        densities.append(neighbors)

    max_density = max(densities) if densities else 1
    max_density = max(max_density, 1)
    return pd.Series([d / max_density for d in densities], index=df.index)


def _danger_score(df: pd.DataFrame) -> pd.Series:
    if "danger_score" in df.columns:
        return df["danger_score"].astype(float).clip(0.0, 10.0)

    if "severity" in df.columns:
        return df["severity"].astype(float).clip(0.0, 10.0)

    if "incident_type" in df.columns:
        mapped = (
            df["incident_type"]
            .astype(str)
            .str.lower()
            .map(SEVERITY_MAP)
            .fillna(SEVERITY_MAP["other"])
        )
        return mapped.astype(float).clip(0.0, 10.0)

    return pd.Series([5.0] * len(df), index=df.index)


def build_training_dataset(input_csv: Path, out_csv: Path, use_sun_api: bool) -> None:
    df = pd.read_csv(input_csv)

    missing = [c for c in REQUIRED_INPUT_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required input columns: {missing}")

    df = _parse_timestamp(df)
    if df.empty:
        raise ValueError("No valid rows after timestamp parsing")

    df = df.sort_values("timestamp").reset_index(drop=True)

    sun_cache: dict = {}

    out = pd.DataFrame()
    out["hour"] = df["timestamp"].dt.hour.astype(float)
    out["is_night"] = ((df["timestamp"].dt.hour >= 20) | (df["timestamp"].dt.hour <= 6)).astype(float)
    out["is_weekend"] = (df["timestamp"].dt.dayofweek >= 5).astype(float)
    out["latitude_norm"] = df["latitude"].astype(float).map(_normalize_lat)
    out["longitude_norm"] = df["longitude"].astype(float).map(_normalize_lng)

    out["incident_history"] = _incident_history_feature(df)
    out["population_density"] = _population_density_proxy(df)

    out["lighting"] = [
        _derive_lighting(ts, lat, lon, use_sun_api, sun_cache)
        for ts, lat, lon in zip(df["timestamp"], df["latitude"], df["longitude"])
    ]

    out["danger_score"] = _danger_score(df)

    out = out[OUTPUT_COLUMNS].dropna().copy()
    out["danger_score"] = out["danger_score"].clip(0.0, 10.0)

    out_csv.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(out_csv, index=False)

    print(f"Built training dataset: {out_csv}")
    print(f"Rows: {len(out)}")
    print(f"Columns: {list(out.columns)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build real-time aligned training CSV for danger model")
    parser.add_argument(
        "--input",
        type=Path,
        required=True,
        help="Path to raw incidents CSV (requires: timestamp, latitude, longitude)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/realtime_training_data.csv"),
        help="Path to output model-ready CSV",
    )
    parser.add_argument(
        "--use-sun-api",
        action="store_true",
        help="Use Open-Meteo sunrise/sunset API for lighting feature",
    )

    args = parser.parse_args()
    build_training_dataset(args.input, args.output, args.use_sun_api)


if __name__ == "__main__":
    main()
