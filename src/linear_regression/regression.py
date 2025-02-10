
import re
from itertools import combinations
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

sample_data = open("src/linear_regression/summary.txt").read()


#  we should add two other dimensions to cover the lower bound and upper bound of partition result
#  lower bound = len(privilege_nodes) / len(full_function) -> ?
#  upper bound = len(full_function) / len(full_function) -> 1
df = pd.DataFrame(
    columns=['edit_dist', 'global_ratio_priv_codebase', 'local_ratio_priv_codebase', 'similarity_score'])
# Regex pattern
pattern = r"[-+]?\d*\.\d+"

# Find all matches
for row in sample_data.strip().split('\n'):
    floats = re.findall(pattern, row.strip())
    print(floats)
    if len(floats) == 4:
        edit_dist = float(floats[0])
        global_ratio_priv_codebase = float(floats[1])
        local_ratio_priv_codebase = float(floats[2])
        similarity_score = float(floats[3])
        new_row = pd.DataFrame({'edit_dist': [edit_dist], 'global_ratio_priv_codebase': [global_ratio_priv_codebase], 'local_ratio_priv_codebase': [local_ratio_priv_codebase],
                                "similarity_score": [similarity_score]})
        df = pd.concat([new_row, df], ignore_index=True)


df['global_ratio_priv_codebase'] = df['global_ratio_priv_codebase'].apply(
    lambda x: min(x, 1.0))
df['local_ratio_priv_codebase'] = df['local_ratio_priv_codebase'].apply(
    lambda x: min(x, 1.0))
print(df)

# 目标变量
y = df["similarity_score"]

# 函数：计算给定特征组合的性能


def evaluate_feature_set(features):
    X_subset = df[list(features)]
    X_train, X_test, y_train, y_test = train_test_split(
        X_subset, y, test_size=0.3, random_state=30)
    model = LinearRegression()
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    mse = mean_squared_error(y_test, y_pred)
    rmse = np.sqrt(mse)
    r2 = r2_score(y_test, y_pred)
    mape = np.mean(np.abs((y_test - y_pred) / y_test)) * 100
    mde = np.mean(y_test - y_pred)
    adj_r2 = 1 - (1-r2)*(len(y_test)-1)/(len(y_test)-X_subset.shape[1]-1)

    # 归一化权重系数
    # print("Unnormalized coefficients: " + str(model.coef_))
    normalized_coefficients = model.coef_ / sum(model.coef_)
    return mae, mse, rmse, r2, mape, mde, adj_r2, normalized_coefficients


mae, mse, rmse, r2, mape, mde, adj_r2, normalized_coefficients = evaluate_feature_set(
    ["edit_dist", "global_ratio_priv_codebase", "local_ratio_priv_codebase"])

print(f"  Mean Absolute Error (MAE): {mae}")
print(f"  Mean Squared Error (MSE): {mse}")
print(f"  Root Mean Squared Error (RMSE): {rmse}")
print(f"  Coefficient of Determination (R²): {r2}")
print(f"  Mean Absolute Percentage Error (MAPE): {mape}")
print(f"  Mean Deviation Error (MDE): {mde}")
print(f"  Adjusted R²: {adj_r2}")
print(f"  Normalized Weight Coefficients: {normalized_coefficients}\n")


mae, mse, rmse, r2, mape, mde, adj_r2, normalized_coefficients = evaluate_feature_set(
    ["edit_dist", "global_ratio_priv_codebase"])

print(f"  Mean Absolute Error (MAE): {mae}")
print(f"  Mean Squared Error (MSE): {mse}")
print(f"  Root Mean Squared Error (RMSE): {rmse}")
print(f"  Coefficient of Determination (R²): {r2}")
print(f"  Mean Absolute Percentage Error (MAPE): {mape}")
print(f"  Mean Deviation Error (MDE): {mde}")
print(f"  Adjusted R²: {adj_r2}")
print(f"  Normalized Weight Coefficients: {normalized_coefficients}\n")


mae, mse, rmse, r2, mape, mde, adj_r2, normalized_coefficients = evaluate_feature_set(
    ["edit_dist", "local_ratio_priv_codebase"])

print(f"  Mean Absolute Error (MAE): {mae}")
print(f"  Mean Squared Error (MSE): {mse}")
print(f"  Root Mean Squared Error (RMSE): {rmse}")
print(f"  Coefficient of Determination (R²): {r2}")
print(f"  Mean Absolute Percentage Error (MAPE): {mape}")
print(f"  Mean Deviation Error (MDE): {mde}")
print(f"  Adjusted R²: {adj_r2}")
print(f"  Normalized Weight Coefficients: {normalized_coefficients}\n")
