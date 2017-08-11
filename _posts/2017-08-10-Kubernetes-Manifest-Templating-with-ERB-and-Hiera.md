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

* Deploy different versions of a deployment to different contexts (versioning)
* Tune deployments using logic and variables based on deployment context (templating)

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

(clarify this - show transition from normal layout to versioned manifest dir layout)

Although this solves the versioning problem, this doesn't help us with customizing the deployments, which is where templating comes in.

## Templating

_Understanding [ERB](http://www.stuartellis.name/articles/erb/#writing-templates) and [Hiera](https://docs.puppet.com/hiera/) is beyond the scope of this article._

`erb-hiera` started life as a tool that was dedicated to generating Kubernetes manifests from our templates, it contained some logic which interpreted our directory structures and pulled out information from the directory structure to use as the lookup scope when searching hiera for data. This was fine, but soon we wanted to use `erb-hiera` in other places where we have similar use cases, e.g: our infrastructure as code repository.

`erb-hiera` turned into a generic templating tool, here's an example of what a config to deploy various versions of a deployment to different contexts looks like:

```
- scope:
    environment: dev
    project: bw-dev-analytics0
    team: analytics
    class: analytics0
    cluster: cluster0
    deployment: monitoring
    deployment_version: latest
  dir:
    input: conf/monitoring/latest/manifest
    output: ../conf/bw-dev-analytics0/cluster0/monitoring/

- scope:
    environment: stage
    project: bw-stage-analytics0
    team: analytics
    class: analytics0
    cluster: cluster0
    deployment: monitoring
    deployment_version: latest
  dir:
    input: conf/monitoring/0.0.0/manifest
    output: ../conf/bw-stage-analytics0/cluster0/monitoring/

- scope:
    environment: prod
    project: bw-prod-analytics0
    team: analytics
    class: analytics0
    cluster: cluster0
    deployment: monitoring
    deployment_version: latest
  dir:
    input: conf/monitoring/0.0.0/manifest
    output: ../conf/bw-prod-analytics0/cluster0/monitoring/
```

_note that instead of having a complex and difficult to manage directory structure of symlinks, we define the input directory in each block, in this example the input deployments are a tree of versioned deployments as discussed in the Versioning section_

Example hiera config:
```
:backends:
  - yaml
:yaml:
  :datadir: "hiera"
:hierarchy:
  - "project/%{project}/deployment/%{deployment}/%{deployment_version}/environment/%{environment}"
  - "project/%{project}/environment/%{environment}"
  - "project/%{project}"
  - "class/%{class}/deployment/%{deployment}/%{deployment_version}/environment/%{environment}"
  - "class/%{class}/environment/%{environment}"
  - "class/%{class}"
  - "deployment/%{deployment}/%{deployment_version}/environment/%{environment}"
  - "environment/%{environment}"
  - "common"
```

Now we can set the versions like so:
```

```

It's also possible to use logic in templates like so:
```
if else logic to test to see if something is dev environment..

```

<diagram showing how templating works for our manifests>

## Why not helm?

After trying Helm we decided that we'd like a simpler way to handle templating our manifests.

## Pros and Cons

less deployments to manage
everything in once place
flexible
easy to back out of (unlike helm)
easy to track changes

you end up with a large erb-hiera config

template it!

similar to r10k? is it? what does r10k do?

## References

* [ERB](http://www.stuartellis.name/articles/erb/#writing-templates)
* [Hiera](https://docs.puppet.com/hiera/)
