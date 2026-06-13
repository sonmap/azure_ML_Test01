import argparse
from pathlib import Path
import json

import joblib
import mlflow
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier


def infer_target(df: pd.DataFrame) -> str:
    candidates = [
        "claim", "claims", "claim_yn", "has_claim", "claim_flag", "nclaims", "num_claims"
    ]
    lowered = {c.lower(): c for c in df.columns}
    for c in candidates:
        if c in lowered:
            return lowered[c]
    # Kaggle notebook variations may have different names. Fallback: use last column.
    return df.columns[-1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_csv", type=str, required=True)
    parser.add_argument("--model_output", type=str, required=True)
    args = parser.parse_args()

    input_path = Path(args.input_csv)
    if input_path.is_dir():
        csv_files = list(input_path.glob("*.csv"))
        if not csv_files:
            raise FileNotFoundError(f"No CSV found under {input_path}")
        input_path = csv_files[0]

    # Kaggle motor insurance CSV often uses semicolon delimiter.
    try:
        df = pd.read_csv(input_path, sep=";")
        if df.shape[1] == 1:
            df = pd.read_csv(input_path)
    except Exception:
        df = pd.read_csv(input_path)

    target = infer_target(df)
    y_raw = df[target]
    X = df.drop(columns=[target])

    # Convert target to binary if possible. This is a PoC scaffold.
    if y_raw.dtype == "object":
        y = y_raw.astype(str).str.lower().isin(["1", "true", "yes", "y", "claim", "claimed"]).astype(int)
    else:
        y = (pd.to_numeric(y_raw, errors="coerce").fillna(0) > 0).astype(int)

    numeric_features = X.select_dtypes(include=["number", "bool"]).columns.tolist()
    categorical_features = [c for c in X.columns if c not in numeric_features]

    numeric_pipeline = Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
    ])

    categorical_pipeline = Pipeline([
        ("imputer", SimpleImputer(strategy="most_frequent")),
        ("onehot", OneHotEncoder(handle_unknown="ignore")),
    ])

    preprocessor = ColumnTransformer([
        ("num", numeric_pipeline, numeric_features),
        ("cat", categorical_pipeline, categorical_features),
    ])

    model = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
    pipeline = Pipeline([
        ("preprocess", preprocessor),
        ("model", model),
    ])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y if y.nunique() == 2 else None
    )

    mlflow.sklearn.autolog()
    with mlflow.start_run():
        mlflow.log_param("target_column", target)
        mlflow.log_param("row_count", len(df))
        mlflow.log_param("feature_count", X.shape[1])
        pipeline.fit(X_train, y_train)
        preds = pipeline.predict(X_test)
        mlflow.log_metric("accuracy", accuracy_score(y_test, preds))
        mlflow.log_metric("f1", f1_score(y_test, preds, zero_division=0))
        if hasattr(pipeline[-1], "predict_proba") and y_test.nunique() == 2:
            proba = pipeline.predict_proba(X_test)[:, 1]
            mlflow.log_metric("roc_auc", roc_auc_score(y_test, proba))

        out_dir = Path(args.model_output)
        out_dir.mkdir(parents=True, exist_ok=True)
        joblib.dump(pipeline, out_dir / "model.joblib")
        with open(out_dir / "metadata.json", "w", encoding="utf-8") as f:
            json.dump({"target_column": target, "rows": len(df), "features": X.shape[1]}, f, ensure_ascii=False, indent=2)
        mlflow.log_artifacts(str(out_dir), artifact_path="model_artifacts")


if __name__ == "__main__":
    main()
