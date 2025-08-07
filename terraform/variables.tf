# terraform/variables.tf

variable "gcp_project_id" {
    description = "The GCP project ID where resources will be created."
    type        = string
}

variable "gcp_region" {
    description = "The GCP region where resources will be deployed."
    type        = string
    default     = "us-central1"
}

variable bucket_name {
    description = "The name of the GCS bucket to be created."
    type        = string
}

