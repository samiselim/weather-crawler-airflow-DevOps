# Weather Crawler on RKE2 with Airflow & MongoDB

## Overview
This project implements a Kubernetes-based weather data collection system using:

- **RKE2 Kubernetes Cluster** (1 master, 1 worker)
- **Rancher** for cluster management
- **Apache Airflow** for scheduled execution
- **MongoDB** for data storage
- **Python Crawler** that fetches weather data from 3 sources

---

## 🏗 Infrastructure Setup

### 1. Provision RKE2 Cluster (Locally on CentOS 9)
- One VM as **master**, one as **worker**
- Installed `rke2-server` on master, `rke2-agent` on worker
- Configured systemd services and token authentication manually

### 2. Install Rancher
- Used Terraform + Helm to install Rancher on RKE2
- Used cert-manager and Helm chart to deploy Rancher

### 3. Deploy Core Services Using Terraform and Helm
- **MongoDB** deployed via Bitnami Helm chart with persistence and insecure auth enabled
- **Apache Airflow** deployed via official Helm chart
  - Mounted DAGs using `hostPath`
  - Custom Docker image for Airflow with KubernetesPodOperator support

---

## 🐍 Python Crawler

### Crawler Logic
- Pulls weather data from:
  1. https://wttr.in/London?format=3
  2. https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current_weather=true
  3. https://www.weatherapi.com/ (with API key)
- Stores output in MongoDB under `weather.data`

### Docker Image
- Built and pushed to Docker Hub as `samiselim/weather-crawler:latest`
- Requires environment variables:
  - `MONGO_URL` (e.g. `mongodb://mongodb.mongodb.svc.cluster.local:27017/`)
  - `WEATHERAPI_KEY`

---

## 🌀 Airflow DAG

### DAG Location
Mounted into `/opt/airflow/dags` using hostPath and visible in UI.

### DAG Definition (`weather_dag.py`)
- Schedules every 5 minutes (`*/5 * * * *`)
- Executes a KubernetesPodOperator to launch the crawler image

### DAG Config Snippet
```python
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from datetime import datetime, timedelta

default_args = {
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

with DAG('weather_crawler_dag',
         default_args=default_args,
         schedule_interval='*/5 * * * *',
         start_date=datetime(2024, 1, 1),
         catchup=False) as dag:

    run_crawler = KubernetesPodOperator(
        namespace='airflow',
        image='samiselim/weather-crawler:latest',
        name='weather-crawler-job',
        task_id='run_weather_crawler',
        env_vars={
            'MONGO_URL': 'mongodb://mongodb.mongodb.svc.cluster.local:27017/',
            'WEATHERAPI_KEY': '<your_key>'
        },
        is_delete_operator_pod=True,
        get_logs=True,
    )
```

---

## ✅ Verification

### Logs
- View Airflow task logs for crawler output

### MongoDB
Use `mongosh` to verify data:
```bash
kubectl run -it mongo-client --rm --image=mongodb/mongodb-shell:latest -n mongodb \
  --command -- mongosh "mongodb://mongodb.mongodb.svc.cluster.local:27017/weather"
```
```js
db.data.find().pretty()
```

## MongoDB Check
```bash
kubectl run -it mongo-client --rm --image=mongodb/mongodb-shell:latest -n mongodb \
  --command -- mongosh "mongodb://mongodb.mongodb.svc.cluster.local:27017/weather"
```
```js
db.data.find().pretty()
```

## Author
[@samiselim](https://github.com/samiselim)
```

Let me know if you want this written into your repo or need a GitHub push setup 🚀

