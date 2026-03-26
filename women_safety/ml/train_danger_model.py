import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split

FEATURE_COLUMNS = [
    "hour",
    "is_night",
    "is_weekend",
    "latitude_norm",
    "longitude_norm",
    "incident_history",
    "population_density",
    "lighting",
]
TARGET_COLUMN = "danger_score"


def load_dataset(csv_path: Path) -> tuple[np.ndarray, np.ndarray]:
    df = pd.read_csv(csv_path)

    missing = [col for col in FEATURE_COLUMNS + [TARGET_COLUMN] if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    df = df[FEATURE_COLUMNS + [TARGET_COLUMN]].dropna().copy()
    if df.empty:
        raise ValueError("No rows available after removing missing values")

    y = df[TARGET_COLUMN].astype(np.float32).clip(0.0, 10.0).to_numpy() / 10.0
    x = df[FEATURE_COLUMNS].astype(np.float32).to_numpy()
    return x, y


def build_model() -> tf.keras.Model:
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(len(FEATURE_COLUMNS),)),
            tf.keras.layers.Dense(32, activation="relu"),
            tf.keras.layers.Dense(16, activation="relu"),
            tf.keras.layers.Dense(1, activation="sigmoid"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss=tf.keras.losses.MeanSquaredError(),
        metrics=[tf.keras.metrics.MeanAbsoluteError(name="mae")],
    )
    return model


def convert_to_tflite(model: tf.keras.Model, out_path: Path) -> None:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(tflite_model)


def main() -> None:
    parser = argparse.ArgumentParser(description="Train AI danger prediction model")
    parser.add_argument(
        "--data",
        type=Path,
        default=Path("data/sample_training_data.csv"),
        help="Path to CSV training data",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=80,
        help="Maximum training epochs",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=32,
        help="Training batch size",
    )
    parser.add_argument(
        "--model-out",
        type=Path,
        default=Path("artifacts/danger_model.keras"),
        help="Path to save Keras model",
    )
    parser.add_argument(
        "--tflite-out",
        type=Path,
        default=Path("../assets/models/danger_prediction_model.tflite"),
        help="Path to save TFLite model for the Flutter app",
    )

    args = parser.parse_args()

    x, y = load_dataset(args.data)
    x_train, x_temp, y_train, y_temp = train_test_split(x, y, test_size=0.30, random_state=42)
    x_val, x_test, y_val, y_test = train_test_split(x_temp, y_temp, test_size=0.50, random_state=42)

    model = build_model()
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=8, restore_best_weights=True
        )
    ]

    model.fit(
        x_train,
        y_train,
        validation_data=(x_val, y_val),
        epochs=args.epochs,
        batch_size=args.batch_size,
        callbacks=callbacks,
        verbose=1,
    )

    test_loss, test_mae = model.evaluate(x_test, y_test, verbose=0)
    print(f"Test loss: {test_loss:.4f}")
    print(f"Test MAE (0-1): {test_mae:.4f}")
    print(f"Test MAE (0-10 score): {test_mae * 10:.4f}")

    args.model_out.parent.mkdir(parents=True, exist_ok=True)
    model.save(args.model_out)
    convert_to_tflite(model, args.tflite_out)

    print(f"Saved Keras model to: {args.model_out}")
    print(f"Saved TFLite model to: {args.tflite_out}")


if __name__ == "__main__":
    main()
