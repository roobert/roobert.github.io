---
draft:      true
layout:     post
title:      GCP Service Account Key Cleaner
date:       2020-02-25 20:27
type:       post
---

# GCP Service Account Key Cleaner

## Overview


We use [Vault](https://www.vaultproject.io/) to issue temporary access credentials to our GCP projects, this includes issuing credentials to our build Terraform and Kubernetes deployment pipeline. The [docs](https://www.vaultproject.io/docs/secrets/gcp/index.html#things-to-note) mention that the secrets engine can be configured to issue OAUTH tokens or service account keys. The advantage of OAUTH tokens is that you can issue as many as you like, and they have a fixed life of 1hr. Terraform can use OAUTH to connect to GCP and deploy your infrastructure, however, it is not possible to use OAUTH with `gcloud(1)` to configure access to your Kubernetes clusters.

The solution is to configure Vault to issue service account keys. Service account keys have one major disadvantage: you are limited to 10 keys per service account. This means that if Something Bad happens and you fail to revoke the service account key after it's been used, you could run out of available key slots.

[GCP Service Account Key Cleaner](https://github.com/roobert/gcp-service-account-key-cleaner) is a small python app which can be run locally or periodically as a [GCP Function](https://cloud.google.com/functions) to delete keys after a TTL is reached.

After running `package.sh` and uploading the code to a bucket named `<company_name>-gcp-service-account-key-cleaner`, you can use something like the following Terraform code to deploy the function:
```
locals {
  company_name          = "example"
  project_id            = var.project_id
  service_account_email = var.vault_service_account
  app_version           = "0.0.1"
}

resource "google_pubsub_topic" "gcp-service-account-key-cleaner" {
  name = "gcp-service-account-key-cleaner"
}

resource "google_cloud_scheduler_job" "gcp-service-account-key-cleaner" {
  name     = "gcp-service-account-key-cleaner"
  schedule = "* * * * *"

  pubsub_target {
    topic_name = google_pubsub_topic.gcp-service-account-key-cleaner.id
    data       = base64encode("ping")
  }
}

resource "google_storage_bucket" "gcp-service-account-key-cleaner" {
  name = "${local.company_name}-gcp-service-account-key-cleaner"
}

resource "google_cloudfunctions_function" "gcp-service-account-key-cleaner" {
  name                  = "gcp-service-account-key-cleaner"
  source_archive_bucket = google_storage_bucket.gcp-service-account-key-cleaner.name
  source_archive_object = "app-${local.app_version}.zip"
  available_memory_mb   = 128
  timeout               = 60
  runtime               = "python37"
  entry_point           = "main"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${local.project_id}/topics/gcp-service-account-key-cleaner"
  }

  environment_variables = {
    SERVICE_ACCOUNT_EMAIL = local.service_account_email
    EXPIRE_AFTER_MINUTES  = 20
  }
}
```
