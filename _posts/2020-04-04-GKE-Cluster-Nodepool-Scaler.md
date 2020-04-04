---
draft:      true
layout:     post
title:      GKE Cluster Nodepool Scaler
date:       2020-04-04 13:20
type:       post
---

<p align="center">
<img src="" class="img-header-600" />
</p>

## Problem

At my current job we have chosen to separate our concerns by running many small GKE clusters. This means we run a lot of clusters.

As a cost cutting measure we spin down our dev and test clusters each weekday night for a period of about 8 hours a day, and over the weekend we leave them shutdown altogether. This allows our teams in multiple timezones to have access to the clusters when they need them, but saves the compute running cost for the nodes in the node pools when they are not needed. In total this saves 88 out of 168 hours a week of run time, or about 52% of the nodepool cost.

## Solution

I wrote a simple GCP function called [gke-cluster-nodepool-scaler](https://github.com/roobert/gke-cluster-nodepool-scaler) that can be used in conjunction with GCP Scheduler and a PubSub topic to scale cluster nodepools up and down.

## Deployment

An example Terraform module manifest can be found here: https://github.com/roobert/gke-cluster-nodepool-scaler/blob/master/gke-cluster-nodepool-scaler.tf

## Testing

There are several ways which the service can be tested.

It's possible to directly execute the GCP function:
<p align="center">
<img src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_test.png"/>
</p>
<p align="center">
<img src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_test_log.png"/>
</p>

Once the function works, test publishing a message onto the pubsub queue:
<p align="center">
<img src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/pubsub_test.png"/>
</p>

Then test the scheduler publishing is functioning:
<p align="center">
<img src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/scheduler_test.png"/>
</p>

Finally, check the function log to see if the function executed at the correct times:
<p align="center">
<img src="https://github.com/roobert/roobert.github.io/raw/master/images/gke_scaler/gcp_function_log.png"/>
</p>


## Circumventing the Schedule

If a developer wants to work out of hours and needs to circumvent the usual triggers, they can trigger the scale-up function to scale up each node pool:
```
cat >> ~/bin/gke_scale_nodepool.sh << EOF
#!/bin/bash
PROJECTS="project0 project1 project2"
NODE_COUNT="${1}"
TOPIC="gke-cluster-nodepool-scaler"

for project in "${PROJECTS}"; do
  gcloud --project "${PROJECT}" pubsub topics publish "${TOPIC}" --message '{"nodes":${NODE_COUNT}}'
done
EOF

chmod +x ~/bin/gke_scale_nodepool.sh

# scale nodepool up
~/bin/gke_scale_nodepool.sh 1
```

Equally, once they are done, it's possible to manually trigger a scale down of all services.
```
# scale nodepool down
~/bin/gke_scale_nodepool.sh 0
```

## Conclusion

Along with several other cost cutting measures such as using preemptive instances, using two-node clusters (to enable testing concurrency, but to keep the number of cluster nodes to a minimum), and by using the smallest possible instances for our apps, it was possible to significantly reduce the running cost of our non-production environments.
