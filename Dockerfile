# FROM python:3.12-slim

# # Set working directory
# WORKDIR /app

# # Copy your Python script into the container
# COPY weather_crawler.py .

# # Install dependencies
# RUN pip install requests pymongo

# # Set environment variables (override at runtime if needed)
# ENV MONGO_URL=mongodb://mongodb.mongodb.svc.cluster.local:27017/
# ENV WEATHERAPI_KEY=e8c8fbdbbbc94662b95120359250304

# # Run the script
# CMD ["python", "weather_crawler.py"]


FROM apache/airflow:2.7.3-python3.10

USER airflow
RUN pip install --no-cache-dir apache-airflow-providers-cncf-kubernetes
