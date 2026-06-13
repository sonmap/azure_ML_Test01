variable "subscription_id" {
  description = "Azure subscription ID. Optional when ARM_SUBSCRIPTION_ID is already exported."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region. Korea Central is recommended for local testing in Korea."
  type        = string
  default     = "koreacentral"
}

variable "location_short" {
  description = "Short location code used in names."
  type        = string
  default     = "krc"
}

variable "name_prefix" {
  description = "Short prefix for resource names. Use lowercase letters, numbers, and hyphen."
  type        = string
  default     = "ins-mlops"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,16}$", var.name_prefix))
    error_message = "name_prefix must be 3-16 chars: lowercase letters, numbers, and hyphen only."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "storage_replication_type" {
  description = "Storage replication type. LRS is enough for lab cost control."
  type        = string
  default     = "LRS"
}

variable "enable_container_registry" {
  description = "Create Azure Container Registry for custom Azure ML environments/images."
  type        = bool
  default     = true
}

variable "container_registry_sku" {
  description = "ACR SKU. Basic is enough for lab. Use Premium for private endpoint scenarios."
  type        = string
  default     = "Basic"
}

variable "enable_compute_instance" {
  description = "Create Azure ML Compute Instance for notebook development. It creates VM cost while running."
  type        = bool
  default     = true
}

variable "compute_instance_name" {
  description = "Azure ML compute instance name. Keep it short and lowercase."
  type        = string
  default     = "ci-ins-dev"
}

variable "compute_instance_vm_size" {
  description = "VM size for Azure ML compute instance. Standard_DS3_v2 is enough for Kaggle insurance EDA."
  type        = string
  default     = "Standard_DS3_v2"
}

variable "developer_object_id" {
  description = "Microsoft Entra object ID to assign the compute instance. Empty means current az login identity. If Terraform runs as service principal, set the real user's object ID."
  type        = string
  default     = ""
}

variable "enable_cpu_cluster" {
  description = "Create autoscaling CPU cluster for Azure ML jobs/pipelines."
  type        = bool
  default     = true
}

variable "cpu_cluster_name" {
  description = "Azure ML CPU cluster name."
  type        = string
  default     = "cpu-cluster"
}

variable "cpu_cluster_vm_size" {
  description = "VM size for Azure ML CPU cluster."
  type        = string
  default     = "Standard_DS3_v2"
}

variable "cpu_cluster_vm_priority" {
  description = "Dedicated or LowPriority. LowPriority reduces cost but may be evicted."
  type        = string
  default     = "LowPriority"

  validation {
    condition     = contains(["Dedicated", "LowPriority"], var.cpu_cluster_vm_priority)
    error_message = "cpu_cluster_vm_priority must be Dedicated or LowPriority."
  }
}

variable "cpu_cluster_min_nodes" {
  description = "Minimum nodes. Keep 0 for cost control."
  type        = number
  default     = 0
}

variable "cpu_cluster_max_nodes" {
  description = "Maximum nodes for job/pipeline execution."
  type        = number
  default     = 2
}

variable "cpu_cluster_idle_duration" {
  description = "ISO-8601 duration before scale down after idle."
  type        = string
  default     = "PT15M"
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
