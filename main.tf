terraform {
  backend "s3" {
    bucket = "challenge-statefile-bucket"
    key = "challenge-statefile"
    region = "eu-west-1"
  }
}

# resource "kubectl_manifest" "cert_manager_crds" {
#   for_each = {
#     for idx, file in fileset("${path.module}/cert-manager-crds", "*.yaml") :
#     file => file
#   }
#   yaml_body = file("${path.module}/cert-manager-crds/${each.value}")
# }
resource "helm_release" "cert_manager" {
  # depends_on = [kubectl_manifest.cert_manager_crds]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.11.0"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true" # We already installed them with kubectl
  }
}

resource "helm_release" "rancher" {
  depends_on = [helm_release.cert_manager]

  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  # version    = "2.8.2" # Specify your desired version
  namespace  = "cattle-system"
  create_namespace = true

  set {
    name  = "hostname"
    value = "rancher.localhost"
  }

  set {
    name  = "bootstrapPassword"
    value = "admin"
  }

  set {
    name  = "replicas"
    value = "1"
  }

  set {
    name  = "ingress.tls.source"
    value = "rancher"
  }
  set {
    name  = "global.cattle.psp.enabled"
    value = "false"
  }
}
resource "kubectl_manifest" "letsencrypt_issuer" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: samiselim75@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
YAML
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.14.0"
    }
  }
}
provider "kubernetes" {
  config_path = "/etc/rancher/rke2/rke2.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/rke2/rke2.yaml"
  }
}

provider "kubectl" {
  config_path = "/etc/rancher/rke2/rke2.yaml"
}

# provider "helm" {
#   kubernetes {
#     config_path = "/etc/rancher/rke2/rke2.yaml"
#   }
# }
# resource "helm_release" "cert_manager" {
#   name             = "cert-manager"
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   create_namespace = true

#   set {
#     name  = "crds.enabled"
#     value = "true"
#   }
#    set {
#     name  = "startupapicheck.enabled"
#     value = "false"
#   }
#   timeout = 600
# }

# resource "helm_release" "rancher" {
#   name       = "rancher"
#   namespace  = "cattle-system"
#   repository = "https://releases.rancher.com/server-charts/latest"
#   chart      = "rancher"
#   create_namespace = true

#   set {
#     name  = "hostname"
#     value = "rancher.localhost"
#   }

#   set {
#     name  = "replicas"
#     value = "1"
#   }
# }


## createing storage class t
# kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

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
    name  = "persistence.storageClass"
    value = "local-path"
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
  set {
    name  = "triggerer.persistence.storageClassName"
    value = "local-path"
  }
  set {
    name  = "persistence.storageClass"
    value = "local-path"
  }
  timeout = 600
}

## kubectl create configmap airflow-dags --from-file=weather_dag.py=weather_dag.py -n airflow

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
  name  = "persistence.storageClass"
  value = "local-path"
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
# PostgreSQL persistence fix
  set {
    name  = "postgresql.primary.persistence.storageClass"
    value = "local-path"
  }
  set {
    name  = "triggerer.persistence.enabled"
    value = "true"
  }  
  set {
    name  = "triggerer.persistence.storageClassName"
    value = "local-path"
  }
    set {
    name  = "workers.persistence.enabled"
    value = "true"
  }  
  set {
    name  = "workers.persistence.storageClassName"
    value = "local-path"
  }
    set {
    name  = "redis.persistence.enabled"
    value = "true"
  }  
  set {
    name  = "redis.persistence.storageClassName"
    value = "local-path"
  }
}

