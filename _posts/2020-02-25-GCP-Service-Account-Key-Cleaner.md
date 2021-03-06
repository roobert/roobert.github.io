---
draft:      true
layout:     post
title:      GCP Service Account Key Cleaner
date:       2020-02-25 20:27
type:       post
---

<p align="center">
<img src="https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/gcp-heart-vault.png" class="img-header-600" />
</p>

## NOTE:

Do not do what is described in this article - managing Vault managed resources outside of Vault is a bad idea!

## Problem

At my current job we use [Vault](https://www.vaultproject.io/) to issue temporary access credentials to our GCP projects. GCP has a limit of ten access keys per Service Account.

We attempt to keep a sanitised environment by revoking keys after use, having short key TTLs, and by trapping process failures so we can perform key-revokes, however, there are still instances where keys can fail to be removed and so we end up with stale keys.

Our primary Terraform and Kubernetes deployment pipeline uses Vault to access our projects. Stale keys using up all ten key slots can cause deployment failure since no more key allocations can happen.

## Vault GCP Secrets Backend: OAuth2 Vs. Service Accounts

The GCP [docs](https://www.vaultproject.io/docs/secrets/gcp/index.html#things-to-note) mention that the secrets engine can be configured to issue OAuth tokens or service account keys. The [official advice](https://www.vaultproject.io/docs/secrets/gcp/index.html#service-account-keys-quota-limits) states _"Where possible, use OAuth2 access tokens instead of Service Account keys"_.

So why use Service Accounts keys over OAuth2 tokens? Many applications (Terraform included) can use OAuth to connect to GCP APIs, equally though, a lot of software does not support OAuth - `gcloud(1)` being a primary example.

Since we want to use `gcloud(1)` to configure access to our GCP Kubernetes clusters, we need to issue Service Accounts keys rather than OAuth tokens. In general service account keys are [more flexible](https://www.vaultproject.io/docs/secrets/gcp/#access-tokens-vs-service-account-keys), their usage must be balanced against the corresponding risk that comes with that flexibility



## Reclaiming Service Account Key Slots

[GCP Service Account Key Cleaner](https://github.com/roobert/gcp-service-account-key-cleaner) is a small python app I have written which deletes keys after a TTL has been reached. The app can be either run [locally](https://github.com/roobert/gcp-service-account-key-cleaner/blob/master/README.md#example), or periodically as a [GCP Function](https://cloud.google.com/functions):

![gcp-sakc](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sakc.png)

## Deployment

[The repository](https://github.com/roobert/gcp-service-account-key-cleaner) includes a [`package.sh`](https://github.com/roobert/gcp-service-account-key-cleaner/blob/master/package.sh) which can be used to create a distributable asset in the form of a zip file. Internally we run this script and upload the asset to a GCP storage bucket as part of the project build pipeline.

The bucket is defined in the following Terraform config, along with the GCP Function definition, and associated scheduler resources:
```terraform
locals {
  company_name          = "example"
  project_id            = var.project_id
  app_version           = "0.0.1"
  service_account_email = var.vault_service_account
  time_to_live_minutes  = 20
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
    TIME_TO_LIVE_MINUTES  = local.time_to_live_minutes
  }
}

resource "google_storage_bucket" "gcp-service-account-key-cleaner" {
  name = "${local.company_name}-gcp-service-account-key-cleaner"
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
```
