# terraform/main.tf

# 1. Configure the Terraform provider for Google Cloud
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

# 2. Create the Pub/Sub topic to act as our stream
resource "google_pubsub_topic" "data_stream_topic" {
  name = "file-data-stream"
}

# 3. Create the GCS bucket to hold our input file
resource "google_storage_bucket" "source_file_bucket" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true # Allows easy cleanup for a hobby project
}

# 4. Create a zip archive of our Cloud Function source code
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "../function_source"
  output_path = "/tmp/function_source.zip"
}

# 5. Create a bucket to store the function's code
resource "google_storage_bucket" "function_code_bucket" {
  name          = "${var.bucket_name}-cf-code"
  location      = var.region
  force_destroy = true
}

# 6. Upload the zipped source code to the code bucket
resource "google_storage_bucket_object" "archive" {
  name   = "source.zip"
  bucket = google_storage_bucket.function_code_bucket.name
  source = data.archive_file.function_source.output_path
}

# 7. Create the Cloud Function
resource "google_cloudfunctions2_function" "file_reader_function" {
  name     = "file-to-pubsub-streamer"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "read_and_publish" # The name of the Python function to run
    source {
      storage_source {
        bucket = google_storage_bucket.function_code_bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    environment_variables = {
      PROJECT_ID  = var.gcp_project_id
      PUBSUB_TOPIC = google_pubsub_topic.data_stream_topic.name
    }
    event_trigger {
      trigger_region = var.region
      event_type     = "google.cloud.storage.object.v1.finalized"
      retry_policy   = "RETRY_POLICY_RETRY"
      service_account_email = "your-service-account@your-project-id.iam.gserviceaccount.com" # Replace with your project's default compute service account or a dedicated one
      pubsub_topic   = google_pubsub_topic.data_stream_topic.id
      event_filters {
        attribute = "bucket"
        value     = google_storage_bucket.source_file_bucket.name
      }
    }
  }

  depends_on = [
    google_project_iam_member.invoker,
    google_project_iam_member.event_receiver
  ]
}

# 8. Permissions for the Cloud Function
# Allow Eventarc to trigger the function
resource "google_project_iam_member" "event_receiver" {
  project = var.gcp_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com" # Use the same service account
}

# Allow Pub/Sub to create authentication tokens for the function
resource "google_project_iam_member" "invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-${var.gcp_project_id}@gcp-sa-pubsub.iam.gserviceaccount.com"
}