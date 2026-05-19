# GCP IoT Platform Module (Pub/Sub + Dataflow)
# Cloud IoT Core is deprecated - using Pub/Sub directly with Dataflow for processing

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Enable required APIs
resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dataflow" {
  service            = "dataflow.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  count              = var.enable_bigquery ? 1 : 0
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}

# Pub/Sub Topic for Vehicle Telemetry
resource "google_pubsub_topic" "telemetry" {
  name    = "${var.project_name}-telemetry"
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  # Message storage policy for multi-region
  dynamic "message_storage_policy" {
    for_each = length(var.allowed_persistence_regions) > 0 ? [1] : []
    content {
      allowed_persistence_regions = var.allowed_persistence_regions
    }
  }

  # Schema validation
  dynamic "schema_settings" {
    for_each = var.telemetry_schema_id != "" ? [1] : []
    content {
      schema   = var.telemetry_schema_id
      encoding = "JSON"
    }
  }

  depends_on = [google_project_service.pubsub]
}

# Pub/Sub Topic for Device Commands (C2D)
resource "google_pubsub_topic" "commands" {
  name    = "${var.project_name}-commands"
  project = var.project_id

  message_retention_duration = "86400s" # 1 day

  depends_on = [google_project_service.pubsub]
}

# Pub/Sub Topic for Device State
resource "google_pubsub_topic" "device_state" {
  name    = "${var.project_name}-device-state"
  project = var.project_id

  message_retention_duration = "604800s" # 7 days

  depends_on = [google_project_service.pubsub]
}

# Dead Letter Topic for failed messages
resource "google_pubsub_topic" "dead_letter" {
  name    = "${var.project_name}-dead-letter"
  project = var.project_id

  message_retention_duration = "2592000s" # 30 days

  depends_on = [google_project_service.pubsub]
}

# Subscriptions
resource "google_pubsub_subscription" "telemetry_dataflow" {
  name    = "${var.project_name}-telemetry-dataflow"
  project = var.project_id
  topic   = google_pubsub_topic.telemetry.name

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration
  retain_acked_messages      = false

  expiration_policy {
    ttl = "" # Never expire
  }

  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # Filter for specific message attributes if needed
  filter = var.telemetry_subscription_filter
}

resource "google_pubsub_subscription" "telemetry_analytics" {
  name    = "${var.project_name}-telemetry-analytics"
  project = var.project_id
  topic   = google_pubsub_topic.telemetry.name

  ack_deadline_seconds       = 60
  message_retention_duration = var.message_retention_duration

  expiration_policy {
    ttl = ""
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
}

resource "google_pubsub_subscription" "commands" {
  name    = "${var.project_name}-commands-sub"
  project = var.project_id
  topic   = google_pubsub_topic.commands.name

  ack_deadline_seconds = 30

  expiration_policy {
    ttl = ""
  }
}

# Cloud Storage bucket for Dataflow temp and staging
resource "google_storage_bucket" "dataflow" {
  name          = "${var.project_name}-dataflow-${var.project_id}"
  project       = var.project_id
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = false
  }
}

# Cloud Storage bucket for telemetry archive
resource "google_storage_bucket" "telemetry_archive" {
  count         = var.enable_telemetry_archive ? 1 : 0
  name          = "${var.project_name}-telemetry-archive-${var.project_id}"
  project       = var.project_id
  location      = var.region
  storage_class = "NEARLINE"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  versioning {
    enabled = false
  }
}

# BigQuery Dataset for analytics
resource "google_bigquery_dataset" "telemetry" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = replace("${var.project_name}_telemetry", "-", "_")
  project     = var.project_id
  location    = var.bigquery_location
  description = "Vehicle telemetry data for analytics"

  default_table_expiration_ms = var.bigquery_table_expiration_ms

  access {
    role          = "OWNER"
    user_by_email = var.bigquery_owner_email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  depends_on = [google_project_service.bigquery]
}

# BigQuery Table for telemetry
resource "google_bigquery_table" "telemetry" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = google_bigquery_dataset.telemetry[0].dataset_id
  table_id    = "vehicle_telemetry"
  project     = var.project_id
  description = "Vehicle telemetry time-series data"

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["vehicle_id", "device_id"]

  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Telemetry timestamp"
    },
    {
      name        = "vehicle_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Vehicle identifier"
    },
    {
      name        = "device_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Device identifier"
    },
    {
      name        = "latitude"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "GPS latitude"
    },
    {
      name        = "longitude"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "GPS longitude"
    },
    {
      name        = "speed"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Vehicle speed in km/h"
    },
    {
      name        = "battery_level"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Battery state of charge (%)"
    },
    {
      name        = "battery_voltage"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Battery voltage (V)"
    },
    {
      name        = "battery_current"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Battery current (A)"
    },
    {
      name        = "battery_temperature"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Battery temperature (°C)"
    },
    {
      name        = "odometer"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Odometer reading (km)"
    },
    {
      name        = "payload"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Full telemetry payload"
    }
  ])
}

# Service Account for Dataflow
resource "google_service_account" "dataflow" {
  account_id   = "${var.project_name}-dataflow"
  project      = var.project_id
  display_name = "Dataflow Service Account"
  description  = "Service account for Dataflow telemetry processing"
}

# IAM permissions for Dataflow service account
resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_compute" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_storage_bucket_iam_member" "dataflow_storage" {
  bucket = google_storage_bucket.dataflow.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.telemetry_dataflow.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_bigquery_dataset_iam_member" "dataflow_bigquery" {
  count      = var.enable_bigquery ? 1 : 0
  project    = var.project_id
  dataset_id = google_bigquery_dataset.telemetry[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow.email}"
}

# Monitoring - Alerting Policy for message backlog
resource "google_monitoring_alert_policy" "pubsub_backlog" {
  display_name = "${var.project_name} - Pub/Sub Message Backlog"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Telemetry subscription backlog > 10000"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${google_pubsub_subscription.telemetry_dataflow.name}\" AND metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10000

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }
}

# Monitoring - Alerting Policy for dead letter messages
resource "google_monitoring_alert_policy" "dead_letter" {
  display_name = "${var.project_name} - Dead Letter Messages"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Messages in dead letter topic"

    condition_threshold {
      filter          = "resource.type = \"pubsub_topic\" AND resource.labels.topic_id = \"${google_pubsub_topic.dead_letter.name}\" AND metric.type = \"pubsub.googleapis.com/topic/num_unacked_messages_by_region\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "3600s"
  }
}
