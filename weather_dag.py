from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from datetime import datetime, timedelta
from airflow.utils.dates import days_ago

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}

with DAG(
    dag_id="weather_k8s_dag",
    default_args=default_args,
    schedule_interval="*/5 * * * *",
    start_date=days_ago(1),
    catchup=False,
    tags=["weather", "k8s"],
) as dag:

    run_weather_crawler = KubernetesPodOperator(
        task_id="run_weather_crawler_pod",
        name="weather-crawler-job",
        namespace="airflow",
        image="samiselim/weather-crawler:latest",
        env_vars={
            "MONGO_URL": "mongodb://mongodb.mongodb.svc.cluster.local:27017/",
            "WEATHERAPI_KEY": "<your-key-here>"
        },
        get_logs=True,
        is_delete_operator_pod=True,
    )
