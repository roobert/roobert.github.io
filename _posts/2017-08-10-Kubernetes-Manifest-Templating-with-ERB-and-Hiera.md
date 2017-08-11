---
layout:     post
title:      Kubernetes Manifest Templating with ERB and Hiera
date:       2017-08-10 14:52
type:       post
draft: true
---

## Introduction

similar to r10k? is it? what does r10k do?

At my current workplace each team has a dev(n)-stage(n)-production(n) deployment workflow. Application deployments are kept in git repositories and deployed by CD tooling. It's unusual for there to be major differences between applications deployed to each of these different contexts, usually it's just a matter of tuning resource limits or, when testing, deploying a different version of the deployment.

[project matrix]: https://dust.cx/project-matrix.jpg "project matrix"

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
