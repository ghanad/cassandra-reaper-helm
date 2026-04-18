# Cassandra Reaper Helm Chart

This repository contains a minimal Helm chart for deploying [Cassandra Reaper](https://cassandra-reaper.io/) on Kubernetes. The chart is designed for GitOps-friendly workflows and uses Cassandra as the default backend.

## Project Structure

```text
.
├── cassandra-reaper/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── LICENSE
```

## Features

- Deploys `Cassandra Reaper` as a Kubernetes `Deployment`
- Supports `cassandra` as the storage backend
- Uses a `ConfigMap` for non-sensitive configuration
- Uses a `Secret` for sensitive values
- Supports `Service`, `Ingress`, and `ServiceAccount`
- Optionally exposes the admin port and a dedicated admin service
- Supports `extraEnv` and `extraSecretEnv`

## Prerequisites

- Kubernetes
- Helm 3
- A Cassandra cluster reachable from inside the Kubernetes cluster

## Versions

- Chart version: `0.1.0`
- App version: `4.0.1`
- Docker image: `thelastpickle/cassandra-reaper:4.0.1`

## Installation

From the repository root:

```bash
helm install reaper ./cassandra-reaper
```

Install with a custom values file:

```bash
helm install reaper ./cassandra-reaper -f my-values.yaml
```

Upgrade an existing release:

```bash
helm upgrade reaper ./cassandra-reaper -f my-values.yaml
```

Uninstall:

```bash
helm uninstall reaper
```

## Initial Configuration

The default values in `cassandra-reaper/values.yaml` intentionally use placeholders and should be updated before deploying to a real environment, especially:

- `reaper.auth.username`
- `reaper.auth.password`
- `reaper.auth.jwtSecret`
- `reaper.cassandra.clusterName`
- `reaper.cassandra.contactPoints`
- `reaper.cassandra.localDc`
- `reaper.cassandra.auth.username`
- `reaper.cassandra.auth.password`

Minimal example:

```yaml
replicaCount: 1

image:
  repository: thelastpickle/cassandra-reaper
  tag: 4.0.1

service:
  type: ClusterIP
  port: 8080

reaper:
  storageType: cassandra
  auth:
    enabled: true
    username: admin
    password: strong-password
    jwtSecret: replace-with-long-random-secret
  cassandra:
    clusterName: production-cassandra
    contactPoints:
      - host: cassandra.default.svc.cluster.local
        port: 9042
    keyspace: reaper_db
    localDc: dc1
    auth:
      enabled: true
      username: cassandra-user
      password: cassandra-password
```

## Authentication Values

The chart has two separate authentication sections:

- `reaper.auth` configures authentication for the Reaper web UI and HTTP API.
- `reaper.cassandra.auth` configures the credentials that Reaper uses to connect to Cassandra.

They are intentionally separate. Changing `reaper.auth.username` and `reaper.auth.password` changes the login credentials for Reaper itself; it does not change the Cassandra user. Changing `reaper.cassandra.auth.username` and `reaper.cassandra.auth.password` changes only the Cassandra credentials used by Reaper.

Example:

```yaml
reaper:
  auth:
    enabled: true
    username: admin
    password: strong-reaper-password
    jwtSecret: long-random-jwt-secret
    readOnly:
      username: viewer
      password: strong-readonly-password
  cassandra:
    auth:
      enabled: true
      username: cassandra-reaper-user
      password: strong-cassandra-password
```

## How the Chart Works

This chart splits configuration into two main resources:

- `ConfigMap` for non-sensitive values such as:
  - `REAPER_STORAGE_TYPE`
  - `REAPER_CASS_CLUSTER_NAME`
  - `REAPER_CASS_CONTACT_POINTS`
  - `REAPER_CASS_KEYSPACE`
  - `REAPER_CASS_LOCAL_DC`
- `Secret` for sensitive values such as:
  - `REAPER_AUTH_USER`
  - `REAPER_AUTH_PASSWORD`
  - `JWT_SECRET`
  - `REAPER_CASS_AUTH_USERNAME`
  - `REAPER_CASS_AUTH_PASSWORD`

The container consumes both through `envFrom`.

## Environment Variables

The chart renders the following environment variables from `values.yaml`.

| Value | Environment variable | Resource | Purpose |
| --- | --- | --- | --- |
| `reaper.storageType` | `REAPER_STORAGE_TYPE` | `ConfigMap` | Reaper storage backend. Defaults to `cassandra`. |
| `reaper.auth.enabled` | `REAPER_AUTH_ENABLED` | `ConfigMap` | Enables or disables Reaper UI/API authentication. |
| `reaper.auth.username` | `REAPER_AUTH_USER` | `Secret` | Admin username for the Reaper UI/API. |
| `reaper.auth.password` | `REAPER_AUTH_PASSWORD` | `Secret` | Admin password for the Reaper UI/API. |
| `reaper.auth.jwtSecret` | `JWT_SECRET` | `Secret` | Secret used by Reaper for JWT signing. Set this to a long random value in production. |
| `reaper.auth.readOnly.username` | `REAPER_READ_USER` | `Secret` | Optional read-only username for the Reaper UI/API. |
| `reaper.auth.readOnly.password` | `REAPER_READ_USER_PASSWORD` | `Secret` | Optional read-only password for the Reaper UI/API. |
| `reaper.cassandra.clusterName` | `REAPER_CASS_CLUSTER_NAME` | `ConfigMap` | Cassandra cluster name known to Reaper. |
| `reaper.cassandra.contactPoints` | `REAPER_CASS_CONTACT_POINTS` | `ConfigMap` | Cassandra contact points rendered as JSON. |
| `reaper.cassandra.keyspace` | `REAPER_CASS_KEYSPACE` | `ConfigMap` | Cassandra keyspace used by Reaper. |
| `reaper.cassandra.localDc` | `REAPER_CASS_LOCAL_DC` | `ConfigMap` | Local Cassandra datacenter used by Reaper. |
| `reaper.cassandra.auth.enabled` | `REAPER_CASS_AUTH_ENABLED` | `ConfigMap` | Enables or disables Cassandra authentication for Reaper's Cassandra connection. |
| `reaper.cassandra.auth.username` | `REAPER_CASS_AUTH_USERNAME` | `Secret` | Cassandra username used by Reaper. |
| `reaper.cassandra.auth.password` | `REAPER_CASS_AUTH_PASSWORD` | `Secret` | Cassandra password used by Reaper. |

`extraEnv` entries are added to the `ConfigMap` and consumed as additional non-sensitive environment variables. `extraSecretEnv` entries are added to the `Secret` and consumed as additional sensitive environment variables.

## Ingress

Ingress is disabled by default. To enable it:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "16m"
  hosts:
    - host: reaper.example.com
      paths:
        - path: /
          pathType: Prefix
```

To enable TLS:

```yaml
ingress:
  enabled: true
  tls:
    - secretName: reaper-tls
      hosts:
        - reaper.example.com
```

## Admin Port

If you need the Reaper admin port, enable it like this:

```yaml
admin:
  enabled: true
  port: 8081
  service:
    enabled: true
    type: ClusterIP
```

If `admin.enabled` is set, the admin container port is exposed. If `admin.service.enabled` is also set, the chart creates a dedicated Service for it.

## Probes

The chart defines all three health probes:

- `startupProbe`
- `readinessProbe`
- `livenessProbe`

By default, all three use the `/ping` endpoint on the main HTTP port. You can tune their timings under `probes`.

## ServiceAccount

By default, the chart creates a `ServiceAccount`:

```yaml
serviceAccount:
  create: true
  name: ""
  annotations: {}
```

To use an existing ServiceAccount:

```yaml
serviceAccount:
  create: false
  name: existing-service-account
```

## Extensibility

To add extra non-sensitive environment variables:

```yaml
extraEnv:
  JAVA_OPTS: -Xms512m -Xmx512m
```

To add extra sensitive environment variables:

```yaml
extraSecretEnv:
  CUSTOM_TOKEN: secret-value
```

The chart also supports:

- `resources`
- `nodeSelector`
- `tolerations`
- `affinity`
- `podAnnotations`
- `podLabels`
- `deploymentAnnotations`
- `extraLabels`
- `extraAnnotations`

## Security Notes

- The default credentials are placeholders and must not be used in production.
- `jwtSecret` should be set to a long, random secret.
- Production values files should be stored in a secure secret-management system or a private repository.

## Rendering and Validation

Render manifests before deploying:

```bash
helm template reaper ./cassandra-reaper -f my-values.yaml
```

Lint the chart:

```bash
helm lint ./cassandra-reaper
```

## License

This project is distributed under the [LICENSE](./LICENSE).
