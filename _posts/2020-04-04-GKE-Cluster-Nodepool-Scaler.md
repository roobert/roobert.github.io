---
layout:     post
title:      GKE Cluster Nodepool Scaler
date:       2020-04-04 13:20
type:       post
---

<p align="center">
<img  src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gke_cluster_nodepool_scaler.png"/>
</p>

## Problem

At my current job we have chosen to separate our concerns by running many small GKE clusters. This means we run a lot of clusters.

As a cost cutting measure we spin down our dev and test clusters each weekday night for a period of about 8 hours a day, and over the weekend we leave them shutdown altogether. This allows our teams in multiple timezones to have access to the clusters when they need them, but saves the compute running cost for the nodes in the node pools when they are not needed. In total this saves 88 out of 168 hours a week of run time, or about 52% of the nodepool cost.

## Solution

I've written a simple GCP function called [gke-cluster-nodepool-scaler](https://github.com/roobert/gke-cluster-nodepool-scaler) that can be used in conjunction with the GCP Scheduler and a PubSub topic to scale cluster nodepools up and down.

## Deployment

Note that if Terraform is run during the out-of-hours time period where the cluster has been scaled down to zero, it will attempt to change the nodepool state back to whatever it was provisioned with.

Example Terraform module:
```terraform
variable company_name {}
variable project_id {}
variable zone {}
variable cluster {}
variable nodepool {}
variable app_version {}
variable min_nodes {}
variable max_nodes {}

resource "google_cloudfunctions_function" "gke-cluster-nodepool-scaler" {
  name                  = "gke-cluster-nodepool-scaler"
  source_archive_bucket = google_storage_bucket.gke-cluster-nodepool-scaler.name
  source_archive_object = "app-${local.app_version}.zip"
  available_memory_mb   = 128
  timeout               = 60
  runtime               = "python37"
  entry_point           = "main"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${local.project_id}/topics/gke-cluster-nodepool-scaler"
  }

  environment_variables = {
    PROJECT_ID = var.project_id
    ZONE       = var.zone
    CLUSTER    = var.cluster
    NODEPOOL   = var.nodepool
  }
}

resource "google_storage_bucket" "gke-cluster-nodepool-scaler" {
  name = "${var.company_name}-gke-cluster-nodepool-scaler"
}

resource "google_pubsub_topic" "gke-cluster-nodepool-scaler" {
  name = "gke-cluster-nodepool-scaler"
}

# scale the cluster down every week-day night
resource "google_cloud_scheduler_job" "gke-cluster-nodepool-scaler-scale-down" {
  name     = "gke-cluster-nodepool-scaler-scale-down"
  schedule = "0 0 * * 2,3,4,5,6"

  pubsub_target {
    topic_name = google_pubsub_topic.gke-cluster-nodepool-scaler.id
    data       = base64encode(jsonencode({ "nodes" = var.min_nodes }))
  }
}

# scale the cluster up every week-day morning
resource "google_cloud_scheduler_job" "gke-cluster-nodepool-scaler-scale-up" {
  name     = "gke-cluster-nodepool-scaler-scale-up"
  schedule = "0 8 * * 1,2,3,4,5"

  pubsub_target {
    topic_name = google_pubsub_topic.gke-cluster-nodepool-scaler.id
    data       = base64encode(jsonencode({ "nodes" = var.max_nodes }))
  }
}
```

  _Note: A copy of the manifest can be found [here](https://github.com/roobert/gke-cluster-nodepool-scaler/blob/master/gke-cluster-nodepool-scaler.tf)._

## Caveats

I found when auto-scaling was enabled that sometimes the cluster size could end up above what I was expecting when triggering a resize. I believe this is due to the cluster auto-scaler. In my case auto-scaling is unnecessary in our dev and test environments so I've set the max nodes to 1 for each zone to prevent unwanted node creation.

## Testing

There are several ways which the service can be tested.

It's possible to directly execute the GCP function:
<p align="center">
<img class="gcp-border" src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_test.png"/>
<img class="gcp-border" src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_test_log.png"/>
</p>

Once the function works, test publishing a message onto the pubsub queue:
<p align="center">
<img class="gcp-border" src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/pubsub_test.png"/>
</p>

Then test the scheduler publishing is functioning:
<p align="center">
<img class="gcp-border" src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/scheduler_test.png"/>
</p>

Finally, check the function log to see if the function executed at the correct times:
<p align="center">
<img class="gcp-border" src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_log.png"/>
</p>


## Circumventing the Schedule

If a developer wants to work out of hours and needs to circumvent the usual triggers, they can trigger the scale-up function to scale up each node pool:
```bash
cat >> ~/bin/gke_scale_nodepool.sh << EOF
#!/usr/bin/env bash
NODE_COUNT="${1}"
PROJECTS="${2}"
TOPIC="gke-cluster-nodepool-scaler"

set -euo pipefail

if [[ $# != 2 ]]; then
  echo "usage: $0 <node count> \"<project> ...\""
  exit 1
fi

for project in ${PROJECTS}; do
  gcloud --project "${PROJECT}" pubsub topics publish "${TOPIC}" --message "{\"nodes\":${NODE_COUNT}}"
done
EOF

chmod +x ~/bin/gke_scale_nodepool.sh

# scale nodepool up
~/bin/gke_scale_nodepool.sh 1
```

Equally, once they are done, it's possible to manually trigger a scale down of all services.
```bash
# scale nodepool down
~/bin/gke_scale_nodepool.sh 0
```

## Conclusion

Along with several other cost cutting measures such as using preemptive instances, using two-node clusters (to enable testing concurrency, but to keep the number of cluster nodes to a minimum), and by using the smallest possible instances for our apps, it has been possible to significantly reduce the running cost of our non-production environments.
