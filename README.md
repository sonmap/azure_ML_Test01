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
