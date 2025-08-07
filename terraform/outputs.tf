# terraform/outputs.tf

output "gcs_source_bucket_name" {
  description = "Name of the GCS bucket to upload your file to."
  value       = google_storage_bucket.source_file_bucket.name
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic."
  value       = google_pubsub_topic.data_stream_topic.name
}

output "function_name" {
  description = "Name of the deployed Cloud Function."
  value       = google_cloudfunctions2_function.file_reader_function.name
}