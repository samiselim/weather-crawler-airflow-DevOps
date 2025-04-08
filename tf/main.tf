provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/rke2/rke2.yaml"
  }
}
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }
   set {
    name  = "startupapicheck.enabled"
    value = "false"
  }
  timeout = 600
}

resource "helm_release" "rancher" {
  name       = "rancher"
  namespace  = "cattle-system"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  create_namespace = true

  set {
    name  = "hostname"
    value = "rancher.localhost"
  }

  set {
    name  = "replicas"
    value = "1"
  }
}
resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mongodb"
  version    = "16.4.12" 
  namespace  = "mongodb"
  create_namespace = true

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  set {
    name  = "image.repository"
    value = "samiselim/custom-mongodb"
  }

  set {
    name  = "image.tag"
    value = "7.0.5"
  }  
  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }

  timeout = 600
}
resource "helm_release" "airflow" {
  name             = "airflow"
  repository       = "https://airflow.apache.org/"
  chart            = "airflow"
  namespace        = "airflow"
  create_namespace = true

  set {
    name  = "auth.username"
    value = "admin"
  }

  set {
    name  = "auth.password"
    value = "admin"
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "service.nodePorts.http"
    value = "30080"
  }

  # Enable PostgreSQL
  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  # PostgreSQL credentials
  set {
    name  = "postgresql.auth.postgresPassword"
    value = "postgres"
  }

  set {
    name  = "postgresql.auth.username"
    value = "postgres"
  }

  set {
    name  = "postgresql.auth.password"
    value = "postgres"
  }

  set {
    name  = "postgresql.auth.database"
    value = "airflow"
  }

  # Airflow Database connection string (critical)
  set {
    name  = "data.metadataConnection.protocol"
    value = "postgresql"
  }

  set {
    name  = "data.metadataConnection.host"
    value = "airflow-postgresql.airflow.svc.cluster.local"
  }

  set {
    name  = "data.metadataConnection.port"
    value = "5432"
  }

  set {
    name  = "data.metadataConnection.db"
    value = "airflow"
  }

  set {
    name  = "data.metadataConnection.user"
    value = "postgres"
  }

  set {
    name  = "data.metadataConnection.pass"
    value = "postgres"
  }

  set {
    name  = "data.metadataConnection.sslmode"
    value = "disable"
  }
  set {
    name  = "env[0].name"
    value = "AIRFLOW__CORE__SQL_ALCHEMY_CONN"
  }

  set {
    name  = "env[0].value"
    value = "postgresql+psycopg2://postgres:postgres@airflow-postgresql.airflow.svc.cluster.local:5432/airflow"
  }
  set {
    name  = "migrations.enabled"
    value = "true"
  }

}

