
Azure Machine Learning MLOps Test Environment

This repository provides a Terraform-based Azure Machine Learning test environment for learning how to use Azure ML with a simple insurance data analysis scenario.

The main goal of this project is to compare a local Linux-based machine learning test environment with an Azure Machine Learning-based managed environment, and to test how data can be stored, analyzed, tracked, and later extended into MLOps workflows.


<img width="1672" height="941" alt="ChatGPT Image Jun 13, 2026, 03_09_01 PM" src="https://github.com/user-attachments/assets/c20a83f9-618d-4d25-99db-35ddfb192ea7" />


<img width="1672" height="941" alt="ChatGPT Image Jun 13, 2026, 03_09_18 PM" src="https://github.com/user-attachments/assets/c7d9b152-45d3-4da5-8143-743a4142b479" />


<img width="1672" height="941" alt="ChatGPT Image Jun 13, 2026, 03_09_25 PM" src="https://github.com/user-attachments/assets/805054af-259e-42fd-9182-165f899c5545" />


1. Project Purpose

This project was created to test the following Azure Machine Learning capabilities:

Azure Machine Learning Workspace
Compute Instance for Notebook-based analysis
Azure Storage Account for data storage
Blob containers for input and output data
Key Vault for secret management
Application Insights and Log Analytics for monitoring
Azure Container Registry for future custom ML environments
Role assignments for Azure ML and Storage access
Basic data analysis using Python, pandas, and scikit-learn
Future extension to AutoML, MLflow, Model Registry, Pipeline, and Endpoint deployment

The first test scenario is based on a motor insurance dataset, such as a Kaggle non-life motor insurance analysis dataset.

2. Architecture Overview

The initial test architecture is simple and cost-conscious.

User / Developer
        |
        v
Azure Machine Learning Studio
        |
        v
Compute Instance
        |
        v
Notebook / Terminal
        |
        v
Azure Storage Account
        |
        v
insurance-data / ml-outputs containers

The environment is designed for the following workflow:

1. Upload CSV data to Azure Storage
2. Start Azure ML Compute Instance only when analysis is needed
3. Open Notebook or Terminal in Azure ML Studio
4. Download or access CSV data from Storage
5. Analyze data using pandas / scikit-learn
6. Save summary files, charts, and results
7. Upload analysis outputs to the ml-outputs container
8. Stop Compute Instance to reduce cost
3. Created Azure Resources

The Terraform configuration creates the following resources:

Resource Type	Example Name
Resource Group	rg-ins-mlops-dev-krc
Azure ML Workspace	mlw-ins-mlops-dev-krc
Compute Instance	ci-ins-dev
Storage Account	stinsmlops6n1381
Input Container	insurance-data
Output Container	ml-outputs
Key Vault	kv-insmlops-6n1381
Azure Container Registry	acrinsmlops6n1381
Application Insights	appi-ins-mlops-dev-krc
Log Analytics Workspace	log-ins-mlops-dev-krc
4. Repository Structure
```text
.
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── foundation.tf
├── aml_workspace.tf
├── compute.tf
├── role_assignments.tf
├── outputs.tf
├── terraform.tfvars.example
├── scripts/
│   ├── register_providers.sh
│   ├── apply.sh
│   ├── destroy.sh
│   └── import_existing_role_assignments.sh
└── aml-jobs/
    ├── train-job.yml
    ├── environments/
    │   └── conda.yml
    └── src/
        └── train.py
        ```text
5. Prerequisites

Before running this project, install the following tools:

Azure CLI
Terraform
Azure ML CLI extension
Python 3.x
Kaggle API, if using Kaggle datasets

Login to Azure:

az login
az account set --subscription "<SUBSCRIPTION_ID>"

Install or update the Azure ML CLI extension:

az extension add --name ml -y
az extension update --name ml

Register required Azure resource providers:

chmod +x scripts/*.sh
./scripts/register_providers.sh
6. Terraform Configuration

Create a Terraform variable file:

cp terraform.tfvars.example terraform.tfvars

Example configuration:

location       = "koreacentral"
location_short = "krc"
name_prefix    = "ins-mlops"
environment    = "dev"

enable_compute_instance  = true
compute_instance_name    = "ci-ins-dev"
compute_instance_vm_size = "Standard_DS3_v2"

# CPU Cluster is disabled by default if Azure ML compute quota is not available.
enable_cpu_cluster        = false
cpu_cluster_name          = "cpu-cluster"
cpu_cluster_vm_size       = "Standard_DS3_v2"
cpu_cluster_vm_priority   = "LowPriority"
cpu_cluster_min_nodes     = 0
cpu_cluster_max_nodes     = 1
cpu_cluster_idle_duration = "PT15M"

enable_container_registry = true
container_registry_sku    = "Basic"

storage_replication_type = "LRS"

tags = {
  owner = "sonmap"
  cost  = "lab"
}
7. Deploy the Environment

Initialize Terraform:

terraform init

Validate the configuration:

terraform validate

Create a plan:

terraform plan -out tfplan

Apply the deployment:

terraform apply tfplan

After deployment, Terraform will output resource names such as:

azure_ml_workspace_name = "mlw-ins-mlops-dev-krc"
compute_instance_name   = "ci-ins-dev"
storage_account_name    = "stinsmlops6n1381"
insurance_data_container = "insurance-data"
ml_outputs_container     = "ml-outputs"
8. Import Existing Role Assignments

If Terraform fails with a RoleAssignmentExists error, run the helper script:

chmod +x scripts/import_existing_role_assignments.sh
./scripts/import_existing_role_assignments.sh

Then run Terraform again:

rm -f tfplan
terraform plan -out tfplan
terraform apply tfplan

This script checks existing Azure role assignments and imports them into the Terraform state.

9. Upload Data to Azure Storage

Upload CSV data to the insurance-data container:

az storage blob upload-batch \
  --account-name stinsmlops6n1381 \
  --destination insurance-data \
  --source ./data \
  --auth-mode login \
  --overwrite

Check uploaded files:

az storage blob list \
  --account-name stinsmlops6n1381 \
  --container-name insurance-data \
  --auth-mode login \
  -o table
10. Start the Compute Instance

Start the Azure ML Compute Instance only when analysis is needed:

az ml compute start \
  --name ci-ins-dev \
  --resource-group rg-ins-mlops-dev-krc \
  --workspace-name mlw-ins-mlops-dev-krc

Check the compute status:

az ml compute show \
  --name ci-ins-dev \
  --resource-group rg-ins-mlops-dev-krc \
  --workspace-name mlw-ins-mlops-dev-krc \
  -o table
11. Open Azure ML Studio

Open Azure ML Studio:

https://ml.azure.com

Select:

Workspace: mlw-ins-mlops-dev-krc
Compute Instance: ci-ins-dev

Then open:

Notebooks → Terminal

or create a new Notebook.

12. Download Data Inside the Compute Instance

In the Azure ML Compute Instance terminal:

mkdir -p ~/cloudfiles/code/Users/$USER/insurance-test/data
cd ~/cloudfiles/code/Users/$USER/insurance-test

Download data from Azure Storage:

az storage blob download-batch \
  --account-name stinsmlops6n1381 \
  --source insurance-data \
  --destination ./data \
  --auth-mode login

Check downloaded files:

find ./data -type f
13. Basic Data Analysis Example

Create a simple Python test script:

cat > check_data.py <<'PY'
import glob
import pandas as pd

csv_files = glob.glob("./data/**/*.csv", recursive=True)

print("CSV files:", csv_files)

if not csv_files:
    raise FileNotFoundError("No CSV files found in ./data")

csv = csv_files[0]
df = pd.read_csv(csv, sep=None, engine="python")

print("\n=== File ===")
print(csv)

print("\n=== Shape ===")
print(df.shape)

print("\n=== Columns ===")
print(df.columns.tolist())

print("\n=== Head ===")
print(df.head())

print("\n=== Data Types ===")
print(df.dtypes)

print("\n=== Missing Values ===")
print(df.isnull().sum().sort_values(ascending=False).head(20))

print("\n=== Summary Statistics ===")
print(df.describe(include="all"))

df.describe(include="all").transpose().to_csv("summary.csv")
print("\nSaved summary.csv")
PY

Run the analysis:

python check_data.py
14. Upload Analysis Results

Upload analysis results to the ml-outputs container:

mkdir -p outputs
mv summary.csv outputs/ 2>/dev/null || true

az storage blob upload-batch \
  --account-name stinsmlops6n1381 \
  --destination ml-outputs \
  --source outputs \
  --auth-mode login \
  --overwrite

Check uploaded outputs:

az storage blob list \
  --account-name stinsmlops6n1381 \
  --container-name ml-outputs \
  --auth-mode login \
  -o table
15. Using MLflow Tracking

Azure ML supports MLflow tracking for recording experiments, parameters, metrics, and model artifacts.

Example:

import mlflow
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

mlflow.set_experiment("insurance-basic-test")

with mlflow.start_run():
    numeric_df = df.select_dtypes(include="number").dropna()

    target_col = numeric_df.columns[-1]
    X = numeric_df.drop(columns=[target_col])
    y = numeric_df[target_col]

    y = (y > y.median()).astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model = RandomForestClassifier(n_estimators=50, random_state=42)
    model.fit(X_train, y_train)

    pred = model.predict(X_test)
    acc = accuracy_score(y_test, pred)

    mlflow.log_param("model_type", "RandomForestClassifier")
    mlflow.log_metric("accuracy", acc)
    mlflow.sklearn.log_model(model, "model")

    print("accuracy:", acc)

You can view experiment results in:

Azure ML Studio → Jobs → Experiments
16. Future Extensions

This project can be extended to test additional Azure ML features:

Feature	Purpose
Data Asset	Register datasets in Azure ML
MLflow	Track experiments and metrics
AutoML	Automatically test multiple ML algorithms
Designer	Build ML pipelines with drag-and-drop
Model Registry	Manage model versions
Batch Endpoint	Run large-scale batch prediction
Online Endpoint	Serve real-time prediction APIs
Model Monitoring	Monitor data drift and model quality
17. Important Notes
Compute Instance Cost

The Compute Instance generates cost while it is running.

Stop it after testing:

az ml compute stop \
  --name ci-ins-dev \
  --resource-group rg-ins-mlops-dev-krc \
  --workspace-name mlw-ins-mlops-dev-krc
CPU Cluster Quota

If the subscription has zero Azure ML managed compute quota in the region, Compute Cluster creation will fail with an error similar to:

ClusterMinNodesExceedCoreQuota
total vCPU quota of 0

In that case, disable the CPU cluster:

enable_cpu_cluster = false

To use AutoML, Pipeline, Batch Endpoint, or managed training jobs, request Azure ML compute quota for the target region.

18. Destroy the Environment

To remove all resources using Terraform:

terraform plan -destroy -out destroyplan
terraform apply destroyplan

If this is a temporary lab environment and Terraform destroy fails, delete the resource group directly:

az group delete \
  --name rg-ins-mlops-dev-krc \
  --yes \
  --no-wait

Check whether the resource group still exists:

az group exists \
  --name rg-ins-mlops-dev-krc

If the result is false, the resource group has been deleted.

19. Summary

This repository provides a basic Azure Machine Learning test environment for:

Storing data in Azure Storage
Analyzing CSV data in Azure ML Compute Instance
Testing Notebook-based data analysis
Tracking experiments with MLflow
Preparing for future MLOps expansion

This is a beginner-friendly Azure ML lab environment focused on understanding the difference between local Linux-based ML testing and Azure-managed ML operations.
# Azure Insurance MLOps Terraform Lab

Kaggle `3-year non-life motor insurance analysis` 같은 보험 데이터 분석을 Azure에서 단순 Notebook 실행이 아니라 **MLOps 운영 확장 환경**으로 테스트하기 위한 Terraform 예제입니다.

## 생성되는 리소스

- Resource Group
- Azure Machine Learning Workspace
- Azure ML Compute Instance: Notebook 개발용
- Azure ML Compute Cluster: Job/Pipeline 실행용, `min_node_count = 0`
- Storage Account + Blob Container: `insurance-data`, `ml-outputs`
- Key Vault: Kaggle API Key, DB 접속정보 등 Secret 저장용
- Log Analytics + Application Insights: Job/Endpoint 관측 기반
- Azure Container Registry: 커스텀 환경 이미지 빌드용
- 기본 RBAC Role Assignment

> 의도적으로 Azure Firewall, AKS, Private Endpoint, GPU는 제외했습니다. 개인 PoC 비용을 줄이기 위한 구성입니다.

## 사전 준비

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
./scripts/register_providers.sh
```

Microsoft 공식 문서도 Azure ML Workspace를 Terraform으로 만들 때 Storage, Key Vault, Application Insights, ACR 같은 종속 리소스가 필요하다고 설명합니다.

## 배포

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## 비용 주의

- Compute Instance는 켜져 있는 동안 VM 비용이 발생합니다. Notebook 사용 후 Azure ML Studio에서 반드시 **Stop** 하세요.
- Compute Cluster는 `min_node_count = 0`으로 설정되어 Job이 없을 때 0대로 내려갑니다.
- ACR Basic, Storage LRS, Log Analytics 30일 보관 기준으로 테스트 비용을 낮췄습니다.

## Kaggle 데이터 등록 예시

Kaggle CSV를 다운로드한 뒤 Azure ML Data Asset으로 등록합니다.

```bash
az extension add -n ml -y

RG=$(terraform output -raw resource_group_name)
WS=$(terraform output -raw azure_ml_workspace_name)

az ml data create \
  --name motor-insurance-csv \
  --version 1 \
  --type uri_file \
  --path ./data/Motor_vehicle_insurance_data.csv \
  --resource-group $RG \
  --workspace-name $WS
```

## 샘플 학습 Job 실행

```bash
cd aml-jobs
RG=$(terraform -chdir=.. output -raw resource_group_name)
WS=$(terraform -chdir=.. output -raw azure_ml_workspace_name)

az ml job create \
  --file train-job.yml \
  --resource-group $RG \
  --workspace-name $WS
```

## Azure에서 로컬 Linux와 달라지는 부분

| 항목 | 로컬 Linux | Azure MLOps |
|---|---|---|
| 분석 | Jupyter 직접 실행 | Compute Instance에서 개발 |
| 학습 실행 | python 수동 실행 | Azure ML Job/Pipeline |
| 실험 이력 | 파일/노트북 관리 | MLflow Experiment Tracking |
| 모델 관리 | model.pkl 수동 관리 | Model Registry 버전 관리 |
| 대량 예측 | 스크립트 직접 실행 | Batch Endpoint 확장 가능 |
| 보안 | Linux 계정 중심 | Entra ID/RBAC/Key Vault |
| 운영 감시 | 직접 구현 | Monitor/Log/Job History 기반 |

## 정리

Terraform은 **MLOps 인프라 생성**까지 담당합니다. AutoML Job, 모델 등록, Batch Endpoint, Responsible AI Dashboard 구성은 Azure ML CLI 또는 Python SDK로 이어서 구성하는 방식이 일반적입니다.
