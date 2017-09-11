---
layout:     post
title:      Monitoring SSL Certificate Expiry
date:       2017-09-11 16:49
type:       post
draft:      true
---

Monitoring SSL Certificate Expiry in GCP and Kubernetes

## Problem

In our GCP projects we have lots of SSL certificates, some of them are legacy certificates that are manually renewed and then updated, and some are managed by letsencrypt. All of them need to be monitored so we can be certain that none have accidentally expired without being noticed.

## Certificate Renewal

Certificates end up in up-to two places:

* The Kubernetes Secret store
* As a GCP compute SSL Certificate

In our infrastructure we use a LetsEncrypt controllers to renew certificates defined in our Kubernetes manifests. Once a certificate exists as a Kubernetes Secret, it can be referenced by other resources such as load balancers. We use two different load balancer implementations in GCP: NGiNX ingress controller, and the default GKE ingress controller.

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

<p><img src="https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/grafana-ssl-certs.png" alt="grafana ssl cert expiry dashboard" /></p>


* Grafana - provide visiblity of certificates and their expiry dates

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
  "title": "GCP SSL 2",
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



