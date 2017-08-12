---
layout:     post
title:      Kubernetes Manifest Templating with ERB and Hiera
date:       2017-08-10 14:52
type:       post
draft: true
---

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

bw-stage-teamA0/monitoring/prometheus/  # cpu: 1, mem: 256Mi 
bw-stage-teamA0/monitoring/influxdb/    # cpu: 1, mem: 256Mi 
bw-stage-teamA0/monitoring/grafana/     # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/prometheus/   # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/influxdb/     # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/grafana/      # cpu: 1, mem: 256Mi 

bw-dev-teamB0/monitoring/prometheus/    #  
bw-dev-teamB0/monitoring/influxdb/      # unchanged
bw-dev-teamB0/monitoring/grafana/       #  

bw-stage-teamB0/monitoring/prometheus/  # cpu: 1, mem: 256Mi 
bw-stage-teamB0/monitoring/influxdb/    # cpu: 1, mem: 256Mi 
bw-stage-teamB0/monitoring/grafana/     # cpu: 1, mem: 256Mi 

bw-prod-teamB0/monitoring/prometheus/   # cpu: 2, mem: 512Mi
bw-prod-teamB0/monitoring/influxdb/     # cpu: 2, mem: 512Mi
bw-prod-teamB0/monitoring/grafana/      # cpu: 2, mem: 512Mi
```

Now lets say we want to test a newer version of influxdb in the teamA's dev environment:

```
bw-dev-teamA0/monitoring/prometheus/    #
bw-dev-teamA0/monitoring/influxdb/      # version: 1.4
ss-dev-teamA0/monitoring/grafana/       #  

bw-stage-teamA0/monitoring/prometheus/  # cpu: 1, mem: 256Mi 
bw-stage-teamA0/monitoring/influxdb/    # cpu: 1, mem: 256Mi 
bw-stage-teamA0/monitoring/grafana/     # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/prometheus/   # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/influxdb/     # cpu: 1, mem: 256Mi 
bw-prod-teamA0/monitoring/grafana/      # cpu: 1, mem: 256Mi 

bw-dev-teamB0/monitoring/prometheus/    #  
bw-dev-teamB0/monitoring/influxdb/      # unchanged
bw-dev-teamB0/monitoring/grafana/       #  

bw-stage-teamB0/monitoring/prometheus/  # cpu: 1, mem: 256Mi
bw-stage-teamB0/monitoring/influxdb/    # cpu: 1, mem: 256Mi 
bw-stage-teamB0/monitoring/grafana/     # cpu: 1, mem: 256Mi 

bw-prod-teamB0/monitoring/prometheus/   # cpu: 2, mem: 512Mi
bw-prod-teamB0/monitoring/influxdb/     # cpu: 2, mem: 512Mi
bw-prod-teamB0/monitoring/grafana/      # cpu: 2, mem: 512Mi
```

At this point there are 5 unique `monitoring` deployments. When dealing with many deployments and many teams/environments, maintenance quickly becomes a problem.

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
bw-dev-teamB0/monitoring/influxdb/      # version: 1.3
bw-dev-teamB0/monitoring/grafana/       #

bw-stage-teamB0/monitoring/prometheus/  #
bw-stage-teamB0/monitoring/influxdb/    # version: 1.3
bw-stage-teamB0/monitoring/grafana/     #

bw-prod-teamB0/monitoring/prometheus/   #
bw-prod-teamB0/monitoring/influxdb/     # version: 1.3
bw-prod-teamB0/monitoring/grafana/      #
```

We can achieve this by creating directories for each set of versions of our deployments:

```
/manifests/monitoring/0.1.0/           # contains influxdb version 1.3
/manifests/monitoring/0.2.0/           # contains influxdb version 1.4
/manifests/monitoring/latest -> 0.2.0  # symlink to latest version (used by dev environments)
```

And then by quite simply symlinking the deployment to the version we wish to deploy:

```
bw-dev-teamA0/monitoring/   -> /manifests/monitoring/latest  # deployment version 0.2.0
bw-stage-teamA0/monitoring/ -> /manifests/monitoring/0.1.0
bw-prod-teamA0/monitoring/  -> /manifests/monitoring/0.1.0

bw-dev-teamB0/monitoring/   -> /manifests/monitoring/0.1.0
bw-stage-teamB0/monitoring/ -> /manifests/monitoring/0.1.0
bw-prod-teamB0/monitoring/  -> /manifests/monitoring/0.1.0
```

Although this solves the versioning problem, this doesn't help us with customizing the deployments, which is where templating comes in.

## ERB and Hiera


![erb-hiera](https://dust.cx/erb-hiera.png)

_Understanding [ERB](http://www.stuartellis.name/articles/erb/#writing-templates) and [Hiera](https://docs.puppet.com/hiera/) is beyond the scope of this article but this diagram should give some clue as to how they work._

## Templating

`erb-hiera` started life as a tool that was dedicated to generating Kubernetes manifests from our templates, it contained some logic which interpreted our directory structures and pulled out information from the directory structure to use as the lookup scope when searching hiera for data. This was fine, but soon we wanted to use `erb-hiera` in other places where we have similar use cases, e.g: our infrastructure as code repository.

`erb-hiera` turned into a generic templating tool, here's an example of what a config to deploy various versions of a deployment to different contexts looks like:

```
- scope:
    environment: dev
    project: bw-dev-teamA0
  dir:
    input: /manifests/monitoring/latest/manifest
    output: /output/bw-dev-teamA0/cluster0/monitoring/

- scope:
    environment: stage
    project: bw-stage-teamA0
  dir:
    input: /manifests/monitoring/0.1.0/manifest
    output: /output/bw-stage-teamA0/cluster0/monitoring/

- scope:
    environment: prod
    project: bw-prod-teamA0
  dir:
    input: /manifests/monitoring/0.1.0/manifest
    output: /output/bw-prod-teamA0/cluster0/monitoring/

- scope:
    environment: dev
    project: bw-dev-teamB0
  dir:
    input: /manifests/monitoring/0.1.0/manifest
    output: /output/bw-dev-teamA0/cluster0/monitoring/

- scope:
    environment: stage
    project: bw-stage-teamB0
  dir:
    input: /manifests/monitoring/0.1.0/manifest
    output: /output/bw-stage-teamB0/cluster0/monitoring/

- scope:
    environment: prod
    project: bw-prod-teamB0
  dir:
    input: /manifests/monitoring/0.1.0/manifest
    output: /output/bw-prod-teamB0/cluster0/monitoring/
```

_note that instead of having a complex and difficult to manage directory structure of symlinks, we define the input directory in each block, in this example the input deployments are a tree of versioned deployments as discussed in the Versioning section_

Example hiera config:
```
:backends:
  - yaml
:yaml:
  :datadir: "hiera"
:hierarchy:
  - "project/%{project}/deployment/%{deployment}"
  - "deployment/%{deployment}/environment/%{environment}"
  - "common"
```

Now we can configure some default resource limits for each environment, we assume stage and prod require roughly the same amount of resources by default:

`deployment/monitoring/environment/stage.yaml`:
```
limits::cpu: 1
limits::mem: 256Mi
```

`deployment/monitoring/environment/prod.yaml`:
```
limits::cpu: 1
limits::mem: 256Mi
```

Then override team B's production environment to increase the resource limits, since we know it needs more resources than other environments:
`project/%{project}/deployment/monitoring.yaml`:
```
limits::cpu: 2
limits::mem: 512Mi
```

One more change is necessary in order for this configuration to work, we need to wrap the limits config in a condition since we don't want to apply any limits for the dev environment:
```
<%- if hiera("environment") =~ /stage|production/ -%>
apiVersion: v1
kind: LimitRange
metadata:
  name: limits
spec:
  limits:
  - default:
      cpu: <%= hiera("limits::cpu") %>
      memory: <%= hiera("limits::mem") %>
...
<% else %>
# no limits set for this environment
<% end %>
```

The result is that with a simple erb-hiera config, hiera config, hiera lookup tree, and versioned manifests, we end up with our original desired configuration, less duplicated code, and more flexibility.

## Best Practice

This example has included versioning manifests (which you may or may not want to use), performing hiera lookups to retrieve values from hiera given a scope, and conditional logic in the templates.

In our first example, we created a new version of our monitoring deployment which included a newer version of influxdb, this is probably overkill and we only really create new versions of our deployments when we're breaking backwards compatibility or performing major changes to the deployments. Usually something like tuning the deployed version of a component would be done per-environment using a hiera lookup, if you're familiar with [Puppet](https://docs.puppet.com/puppet/) then this pattern will be familiar to you.

## TODO

* pros and cons section
* why not helm section
* change hand drawn diagram to draw.io diagram
* consider best practices section
* any other sections?

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
* [erb-hiera](https://github.com/roobert/erb-hiera)
