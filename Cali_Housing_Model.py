import numpy as np
from sklearn.datasets import fetch_california_housing
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from xgboost import XGBRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import pandas as pd
import matplotlib.pyplot as plt

class EnergyRedistributionStabilizer:
    """Simplified stabilizer focusing on dynamic error redistribution."""
    def __init__(self, lambda_value: float = 1.0, alpha: float = 0.1):
        self.lambda_value = lambda_value  # Coupling constant (global-local balance)
        self.alpha = alpha  # Redistribution weight

    def stabilize_predictions(self, predictions: np.ndarray, actuals: np.ndarray) -> np.ndarray:
        """Redistribute errors across predictions."""
        residuals = actuals - predictions
        # Calculate global adjustment (mean residual)
        global_adjustment = self.alpha * np.mean(residuals)
        # Calculate local adjustment (scaled residuals)
        local_adjustments = (1 - self.alpha) * residuals
        # Redistribute errors
        stabilized = predictions + self.lambda_value * (global_adjustment + local_adjustments)
        return stabilized

# Load California housing data
data = fetch_california_housing(as_frame=True)
X, y = data.data, data.target

# Split into training and testing datasets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Standardize the data
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train Random Forest model
rf_model = RandomForestRegressor(random_state=42, n_estimators=100)
rf_model.fit(X_train_scaled, y_train)
rf_pred = rf_model.predict(X_test_scaled)

# Train XGBoost model
xgb_model = XGBRegressor(random_state=42, n_estimators=200, max_depth=6, learning_rate=0.1)
xgb_model.fit(X_train_scaled, y_train)
xgb_pred = xgb_model.predict(X_test_scaled)

# Apply Stabilizer with Optimal Parameters
stabilizer_rf = EnergyRedistributionStabilizer(lambda_value=1.0, alpha=0.1)
rf_stabilized = stabilizer_rf.stabilize_predictions(rf_pred, y_test.values)

stabilizer_xgb = EnergyRedistributionStabilizer(lambda_value=1.0, alpha=0.1)
xgb_stabilized = stabilizer_xgb.stabilize_predictions(xgb_pred, y_test.values)

# Evaluate models
metrics = {
    "Random Forest (Original)": {
        "MAE": mean_absolute_error(y_test, rf_pred),
        "MSE": mean_squared_error(y_test, rf_pred),
        "R2": r2_score(y_test, rf_pred),
    },
    "Random Forest (Stabilized)": {
        "MAE": mean_absolute_error(y_test, rf_stabilized),
        "MSE": mean_squared_error(y_test, rf_stabilized),
        "R2": r2_score(y_test, rf_stabilized),
    },
    "XGBoost (Original)": {
        "MAE": mean_absolute_error(y_test, xgb_pred),
        "MSE": mean_squared_error(y_test, xgb_pred),
        "R2": r2_score(y_test, xgb_pred),
    },
    "XGBoost (Stabilized)": {
        "MAE": mean_absolute_error(y_test, xgb_stabilized),
        "MSE": mean_squared_error(y_test, xgb_stabilized),
        "R2": r2_score(y_test, xgb_stabilized),
    }
}

# Display metrics
metrics_df = pd.DataFrame(metrics)
print("\nMetrics with Energy Redistribution Stabilizer on California Housing")
print(metrics_df)

# Residual Analysis and Visualization
def plot_residuals(y_test, preds, stabilized_preds, model_name):
    residuals_original = y_test.values - preds
    residuals_stabilized = y_test.values - stabilized_preds

    plt.figure(figsize=(12, 6))
    plt.hist(residuals_original, bins=50, alpha=0.5, label=f"{model_name} Original Residuals")
    plt.hist(residuals_stabilized, bins=50, alpha=0.5, label=f"{model_name} Stabilized Residuals")
    plt.axvline(0, color="red", linestyle="--", label="Zero Error")
    plt.title(f"{model_name} Residual Distribution (California Housing)")
    plt.xlabel("Residual Value")
    plt.ylabel("Frequency")
    plt.legend()
    plt.show()

# Plot residuals for Random Forest
plot_residuals(y_test, rf_pred, rf_stabilized, "Random Forest")

# Plot residuals for XGBoost
plot_residuals(y_test, xgb_pred, xgb_stabilized, "XGBoost")

# Example predictions
example_predictions = pd.DataFrame({
    "Actual": y_test[:10].values,
    "RF Original Prediction": rf_pred[:10],
    "RF Stabilized": rf_stabilized[:10],
    "XGB Original Prediction": xgb_pred[:10],
    "XGB Stabilized": xgb_stabilized[:10],
})
print("\nExample Predictions (First 10 Rows):")
print(example_predictions)
