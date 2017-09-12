---
layout:     post
title:      Monitoring SSL Certificate Expiry in GCP and Kubernetes
date:       2017-09-11 16:49
type:       post
draft:      true
---

*diagram showing all the components we're going to use*

## Problem

At my current job we use Google Cloud Platform. Each team has a set of GCP projects and within the projects there can be multiple clusters. The majority of services that our teams write expose some kind of HTTP API or web interface, so what does this mean? A lot of SSL certificates since naturally everything we expose to the internet is encrypted with SSL.

Each of our GCP projects is built using our CI/CD tooling, all GCP resources are defined in git, and all of our Kubernetes application manifests are also defined in git. We have a standard set of stacks which we deploy to each cluster using our *templating*. One of the stacks is Prometheus, Influxdb, and Grafana. In this article I'll explain how we leverage this stack to automatically monitor SSL certificates in use by GCP and Kubernetes.

## Certificate Renewal

To enable teams to expose services with minimal effort, we rely on deploying a Kubernetes LetsEncrypt controller to each of our clusters. The LetsEncrypt controller automatically provisions certificates for Kubernetes resources that require them, indicated by annotations on the resources, e.g:

```
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
  annotations:
    acme/certificate: frontend.analytics-prod.gcp0.example.com
    acme/secretName: frontend-analytics-certificate
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: frontend
```

This certificate can now be consumed by an NGiNX ingress controller like so:


```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: frontend
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
    - secretName: frontend-analytics-certificate
      hosts:
        - frontend.analytics-prod.gcp0.example.com

  rules:
    - host: frontend.analytics-prod.gcp0.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: frontend
              servicePort: 3000
```

When using GCP to load balance traffic, simply create a service with `type: LoadBalancer`, this will create a load balancer in GCP and make a copy of the secret created by LetsEncrypt in GCP as an SSL Certificate resource which the GCP load balancer can then refer to:

```
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
  annotations:
    acme/certificate: frontend.analytics-prod.gcp0.example.com
    acme/secretName: frontend-analytics-certificate
spec:
  type: LoadBalancer
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: frontend
```


Of course, this isn't the only method for deploying ssl certificates for services in GCP and/or Kubernetes. In our case we also have many legacy certificates that are manually renewed by humans, stored encrypted in our repositories, and deployed as secrets to Kubernetes or SSL Certificate resources to GCP.

Regardless of how the certificates end up in either GCP or Kubernetes, we can monitor them with Prometheus.

In either case, certificates end up in up-to two places:

* The Kubernetes Secret store
* As a GCP compute SSL Certificate


of them are legacy certificates that are manually renewed and then updated, and some are managed by letsencrypt. All of them need to be monitored so we can be certain that none have accidentally expired without being noticed.

Certificates end up in up-to two places:

* The Kubernetes Secret store
* As a GCP compute SSL Certificate

In our infrastructure we use a LetsEncrypt controllers to renew certificates defined in our Kubernetes manifests. Once a certificate exists as a Kubernetes Secret, it can be referenced by other resources such as load balancers. We use two different load balancer implementations in GCP: NGiNX ingress controller, and the default GKE ingress controller.

*diagram showing*:
*read from mainfest, add to store*

The NGiNX ingress controller works by mounting the Kubernetes Secret into the controller as a file.

The GKE ingress controller makes a copy of the secret as a Compute SSL Certificate. This means that certificates used in the default GKE Kubernetes load balancers are stored in two separate locations: the Kubernetes cluster, as a secret, and in GCP, as a Certificate resource.

The following commands will show certificates:

* Kubernetes Secrets (`kubectl get secret`)
* GCP compute ssl-certificates (`gcloud compute ssl-certificates`)

## Monitoring

In order to ensure that our certificates are being renewed properly, we want to check the certificates which are being served up by the load balancers. To check the certificates we need to do the following:

0. Fetch a list of FQDNs to check from the appropriate API (GCP or GKE/Kubernetes)
0. Connect to each FQDN and retrieve the certificate
0. Check the Valid To field for the certificate to ensure it isn't in the past

To do the first two parts of this process we'll use a couple of controllers I've written:

*docker urls*

https://github.com/roobert/prometheus-gcp-ssl-certs
https://github.com/roobert/prometheus-gke-letsencrypt-certs

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: prometheus-gke-letsencrypt-certs
  namespace: system-monitoring
  labels:
    k8s-app: prometheus-gke-letsencrypt-certs
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: prometheus-gke-letsencrypt-certs
  template:
    metadata:
      labels:
        k8s-app: prometheus-gke-letsencrypt-certs
      annotations:
        prometheus_io_port: '9292'
        prometheus_io_scrape_metricz: 'true'
    spec:
      containers:
      - name: prometheus-gke-letsencrypt-certs
        image: roobert/prometheus-gke-letsencrypt-certs:v0.0.4
        ports:
          - containerPort: 9292
```

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: prometheus-gcp-ssl-certs
  namespace: system-monitoring
  labels:
    k8s-app: prometheus-gcp-ssl-certs
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: prometheus-gcp-ssl-certs
  template:
    metadata:
      labels:
        k8s-app: prometheus-gcp-ssl-certs
      annotations:
        prometheus_io_port: '9292'
        prometheus_io_scrape_metricz: 'true'
    spec:
      containers:
      - name: prometheus-gcp-ssl-certs
        image: roobert/prometheus-gcp-ssl-certs:v0.0.4
        ports:
          - containerPort: 9292
```

Once these controllers have been deployed, Prometheus should start scraping them for metrics.




### Exposing Certificate Expiry

* use controllers to expose metrics from the APIS

### Visibility

Each of our projects has a Grafana instance automatically deployed to it and preloaded with some useful dashboards, one of queries Prometheus for data about the SSL certs. When a certificate has less than 7 days until it runs out it turns orange, when it's expired, if it expires then it turns red.

<p><img src="https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/grafana-ssl-certs.png" alt="Grafana SSL cert expiry dashboard" /></p>

Here's the Grafana JSON for the dashboard:

```
{
  "__inputs": [],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "4.4.1"
    },
    {
      "type": "panel",
      "id": "table",
      "name": "Table",
      "version": ""
    }
  ],
  "annotations": {
    "list": []
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "hideControls": false,
  "id": null,
  "links": [],
  "refresh": false,
  "rows": [
    {
      "collapse": false,
      "height": "250px",
      "panels": [
        {
          "columns": [
            {
              "text": "Current",
              "value": "current"
            }
          ],
          "fontSize": "100%",
          "id": 1,
          "links": [],
          "pageSize": null,
          "scroll": true,
          "showHeader": true,
          "sort": {
            "col": 1,
            "desc": false
          },
          "span": 12,
          "styles": [
            {
              "alias": "TTL",
              "colorMode": "cell",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 0,
              "pattern": "Current",
              "thresholds": [
                "0",
                "691200"
              ],
              "type": "number",
              "unit": "s"
            }
          ],
          "targets": [
            {
              "expr": "gcp_ssl_cert_expiration - time()",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{certificate_name}}",
              "metric": "gcp_ssl_cert_expiration",
              "refId": "A",
              "step": 1
            }
          ],
          "timeFrom": null,
          "title": "GCP SSL Certs",
          "transform": "timeseries_aggregations",
          "type": "table"
        }
      ],
      "repeat": null,
      "repeatIteration": null,
      "repeatRowId": null,
      "showTitle": false,
      "title": "Dashboard Row",
      "titleSize": "h6"
    },
    {
      "collapse": false,
      "height": 250,
      "panels": [
        {
          "columns": [
            {
              "text": "Current",
              "value": "current"
            }
          ],
          "fontSize": "100%",
          "height": "1024",
          "id": 2,
          "links": [],
          "pageSize": null,
          "scroll": true,
          "showHeader": true,
          "sort": {
            "col": 1,
            "desc": false
          },
          "span": 12,
          "styles": [
            {
              "alias": "Time",
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "pattern": "Time",
              "type": "date"
            },
            {
              "alias": "TTL",
              "colorMode": "cell",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 0,
              "pattern": "Current",
              "thresholds": [
                "0",
                "691200"
              ],
              "type": "number",
              "unit": "s"
            },
            {
              "alias": "",
              "colorMode": null,
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "decimals": 2,
              "pattern": "/.*/",
              "thresholds": [],
              "type": "number",
              "unit": "short"
            }
          ],
          "targets": [
            {
              "expr": "gke_letsencrypt_cert_expiration - time()",
              "format": "time_series",
              "intervalFactor": 1,
              "legendFormat": "{{certificate_name}}",
              "metric": "gke_letsencrypt_cert_expiration",
              "refId": "A",
              "step": 1
            }
          ],
          "title": "GKE LetsEncrypt SSL Certs",
          "transform": "timeseries_aggregations",
          "type": "table"
        }
      ],
      "repeat": null,
      "repeatIteration": null,
      "repeatRowId": null,
      "showTitle": false,
      "title": "Dashboard Row",
      "titleSize": "h6"
    }
  ],
  "schemaVersion": 14,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-5m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "SSL Certificate Expiry",
  "version": 8
}
```

### Alerting

pre-req: writing kubernetes events to elasticsearch

make sure that these are good, within the last 5 minutes..

* elastalert: ensure the letsencrypt/renewal controllers are running (i.e: not stalled)

* prometheus: ensure the controllers are running (started)
* prometheus: ensure the controllers are up      (responding) (aka: not 500'ing due to)
* prometheus: ensure the controllers are responding? (aka: not 500'ing due to)
* prometheus: ensure the expiry dates haven't been hit (ok)



