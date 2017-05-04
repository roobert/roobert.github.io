---
layout:     post
title:      Prometheus - First Impressions / Monitoring Kubernetes
date:       2017-05-04 14:52
type:       post
draft: true
---

## Introduction

My first real introduction to [Prometheus](https://prometheus.io) was seeing [Brian Brazil](https://www.robustperception.io/blog/) talk[1,2,3](https://www.youtube.com/watch?v=uV_sh7_lVw8) at [CloudNative/KubeCon Europe](https://www.cncf.io/event/cloudnativecon-europe-2017/).

Although I'm a fan of Sensu, Brians talks made me want to look into Prometheus further, especially since I liked the idea of the built-in service discovery which fits well with what I've spent the majority of my time working with recently: Kubernetes.

In this article I'll explain the steps I took to create a simple Prometheus/InfluxDB/Grafana (PIG?) stack to get insight into a Kubernetes platform.

## Prometheus

Instead of trying to explain Prometheus here, I'll instead link to the excellent documentation:

* https://prometheus.io/docs/introduction/overview/ - the architecture is described here, a good place to start
* https://prometheus.io/docs/introduction/getting_started/ - getting started guide explains everything you need to know to get going 
* https://prometheus.io/docs/introduction/faq/ - the FAQ is worth a read for some extra general knowledge
* https://prometheus.io/docs/operating/configuration/#<kubernetes_sd_config> - primary reference for kubernetes service discovery config
* https://prometheus.io/docs/operating/configuration/#<relabel_config> - primary reference for label rewriting

I'd also recommend following the Robust Perception blog since it's a goldmine for tips on using Prometheus, I'd especially recommend the following, in no particular order:

* https://www.robustperception.io/common-query-patterns-in-promql/
* https://www.robustperception.io/how-does-a-prometheus-gauge-work/
* https://www.robustperception.io/how-does-a-prometheus-counter-work/
* https://www.robustperception.io/whats-up-doc/
* https://www.robustperception.io/who-wants-seconds/
* https://www.robustperception.io/life-of-a-label/
* https://www.robustperception.io/undoing-the-benefits-of-labels/
* https://www.robustperception.io/controlling-the-instance-label/
* https://www.robustperception.io/on-the-naming-of-things/
* https://www.robustperception.io/target-labels-are-for-life-not-just-for-christmas/
* https://www.robustperception.io/prometheus-and-alertmanager-architecture/
* https://www.robustperception.io/prometheus-security-authentication-authorization-and-encryption/
* https://www.robustperception.io/rate-then-sum-never-sum-then-rate/
* https://www.robustperception.io/relabel_configs-vs-metric_relabel_configs/
* https://www.robustperception.io/booleans-logic-and-math/
* https://www.robustperception.io/translating-between-monitoring-languages/
* https://www.robustperception.io/how-much-ram-does-my-prometheus-need-for-ingestion/
* https://www.robustperception.io/checking-if-ssh-is-responding-with-prometheus/
* https://www.robustperception.io/which-targets-have-the-most-samples/
* https://www.robustperception.io/alertmanager-notification-templating-with-slack/

## Kubernetes




## Remote Read

https://www.robustperception.io/using-the-remote-write-path/
https://prometheus.io/docs/operating/configuration/#remote_read



https://www.cncf.io/wp-content/uploads/sites/2/2016/09/image00.png
