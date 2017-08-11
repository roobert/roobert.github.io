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

## Solution

Our focus is on having the ability to do two things:

* Tune deployments based on deployment context (using logic and variables)
* Deploy different versions of a deployment to different contexts (versioning)

## Versioning

Let's say we want to have the following:

```
bw-dev-teamA0/monitoring/prometheus/    #
bw-dev-teamA0/monitoring/influxdb/      # version: 1.4
bw-dev-teamA0/monitoring/grafana/       #

bw-stage-teamA0/monitoring/prometheus/  #
bw-stage-teamA0/monitoring/influxdb/    # version: 1.3
bw-stage-teamA0/monitoring/grafana/     #

bw-prod-teamA0/monitoring/prometheus/   #
bw-prod-teamA0/monitoring/influxdb/     # version: 1.3
bw-prod-teamA0/monitoring/grafana/      #

bw-dev-teamB0/monitoring/prometheus/    #
bw-dev-teamB0/monitoring/influxdb/      # version: 1.4
bw-dev-teamB0/monitoring/grafana/       #

bw-stage-teamB0/monitoring/prometheus/  #
bw-stage-teamB0/monitoring/influxdb/    # version: 1.3
bw-stage-teamB0/monitoring/grafana/     #

bw-prod-teamB0/monitoring/prometheus/   #
bw-prod-teamB0/monitoring/influxdb/     # version: 1.3
bw-prod-teamB0/monitoring/grafana/      #
```

We could achieve this quite simply with symlinking:

```
bw-dev-teamA0/monitoring/   -> /manifests/monitoring/0.0.2
bw-stage-teamA0/monitoring/ -> /manifests/monitoring/0.0.1
bw-prod-teamA0/monitoring/  -> /manifests/monitoring/0.0.1

bw-dev-teamB0/monitoring/   -> /manifests/monitoring/0.0.2
bw-stage-teamB0/monitoring/ -> /manifests/monitoring/0.0.1
bw-prod-teamB0/monitoring/  -> /manifests/monitoring/0.0.1
```

In the above example, we've versioned our monitoring deployment and updated influxdb to version 1.4 in the 0.0.2 release.

Although this solves the versioning problem, this doesn't help us with customizing the deployments, which is where templating comes in.

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
