---
layout:     post
title:      Kubernetes Manifest Templating with ERB and Hiera
date:       2017-08-10 14:52
type:       post
draft: true
---

## ???

At my current workplace each team has a dev(n)-stage(n)-production(n) type deployment workflow. Application deployments are kept in git repositories and deployed by our [continuous delivery](https://en.wikipedia.org/wiki/Continuous_delivery) tooling.

It's unusual for there to be major differences between applications deployed to each of these different contexts, usually it's just a matter of tuning resource limits or when testing, deploying a different version of the deployment.

Our project matrix looks like this:

![project matrix](https://dust.cx/project-matrix.jpg)

_[GCP](http://cloud.google.com/) projects must have globally unique names so ours are prefixed with `bw-`_

Our directory structure is composed of a Names, Deployments, and Components:

* Name is the GCP Project name
* A Deployment is a logical collection of software
* A Component is a logical collection of Kubernetes manifests

For example, a monitoring deployment composed of influxdb, grafana, and prometheus might look like:

```
monitoring/prometheus/<manifests>
monitoring/influxdb/<manifests>
monitoring/grafana/<manifests>
```

To deploy this monitoring stack to each context we can simply copy the `monitoring` deployment to the relevant location in our directory tree:
```
bw-dev-teamA0/monitoring/
bw-stage-teamA0/monitoring/
bw-prod-teamA0/monitoring/
bw-dev-teamB0/monitoring/
bw-stage-teamB0/monitoring/
bw-prod-teamB0/monitoring/
```

Lets say we want to apply resource limits for the stage and prod environments and we know that teamB processes more events than teamA:

```
bw-dev-teamA0/monitoring/prometheus/    # 
bw-dev-teamA0/monitoring/influxdb/      # unchanged
bw-dev-teamA0/monitoring/grafana/       #  

bw-stage-teamA0/monitoring/prometheus/  # cpu: 1, mem: 2 
bw-stage-teamA0/monitoring/influxdb/    # cpu: 1, mem: 2 
bw-stage-teamA0/monitoring/grafana/     # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/prometheus/   # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/influxdb/     # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/grafana/      # cpu: 1, mem: 2 

bw-dev-teamB0/monitoring/prometheus/    #  
bw-dev-teamB0/monitoring/influxdb/      # unchanged
bw-dev-teamB0/monitoring/grafana/       #  

bw-stage-teamB0/monitoring/prometheus/  # cpu: 2, mem: 4 
bw-stage-teamB0/monitoring/influxdb/    # cpu: 2, mem: 4 
bw-stage-teamB0/monitoring/grafana/     # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/prometheus/   # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/influxdb/     # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/grafana/      # cpu: 2, mem: 4 
```

Now lets say we want to test a newer version of influxdb in the teamA's dev environment:

```
bw-dev-teamA0/monitoring/prometheus/    #
bw-dev-teamA0/monitoring/influxdb/      # version: 1.4
ss-dev-teamA0/monitoring/grafana/       #  

bw-stage-teamA0/monitoring/prometheus/  # cpu: 1, mem: 2 
bw-stage-teamA0/monitoring/influxdb/    # cpu: 1, mem: 2 
bw-stage-teamA0/monitoring/grafana/     # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/prometheus/   # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/influxdb/     # cpu: 1, mem: 2 
bw-prod-teamA0/monitoring/grafana/      # cpu: 1, mem: 2 

bw-dev-teamB0/monitoring/prometheus/    #  
bw-dev-teamB0/monitoring/influxdb/      # unchanged
bw-dev-teamB0/monitoring/grafana/       #  

bw-stage-teamB0/monitoring/prometheus/  # cpu: 2, mem: 4 
bw-stage-teamB0/monitoring/influxdb/    # cpu: 2, mem: 4 
bw-stage-teamB0/monitoring/grafana/     # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/prometheus/   # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/influxdb/     # cpu: 2, mem: 4 
bw-prod-teamB0/monitoring/grafana/      # cpu: 2, mem: 4 
```

At this point there are 4 unique `monitoring` deployments. When dealing with many deployments and many teams/environments, maintenance quickly becomes a problem.

The solution: templating, and versioning.

## Versioning

Our focus is on having the ability to do these two things:

0. Tune deployments based on deployment context
0. Deploy different versions of a deployment to different contexts

<diagram showing how we'd like to deploy different stuff to different places>


## Templating

`erb-hiera` started life as a tool for this specific task but then became more generic when we wanted to use it in other areas (for our gclouder shit)

<diagram showing how templating works for our manifests>

show example of deploying a deployment across environments, then across environments AND teams.. then multiple versions of the same deployment..

# Why not helm?

After trying Helm we decided that we'd like a simpler way to handle templating our manifests.

# negatives..

you end up with a large erb-hiera config

template it!

similar to r10k? is it? what does r10k do?
