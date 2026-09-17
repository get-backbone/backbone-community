# Backbone Community

Backbone is an opinionated, zero-trust microservices platform built on **Quarkus**.

Community is the development-only Backbone edition: pre-baked platform services (auth, users, notifications, documents),
Floci-backed AWS emulation, and enough of the platform to build and run your own domain services in development.  
Production-grade **AWS** environment deployments, full release pipelines, infrastructure automation, hardened security,
scale and compliance features are all available as licenced upgrade paths.

**TBC** You will need a **(free) development licence** to enable bootstrap and local development.

Full Backbone platform
docs: [Features](https://docs.backbonehq.io/docs/features) · [Development](https://docs.backbonehq.io/docs/development)

---

## Getting started

### 1. Bootstrap

```bash
brew install go-task
task bootstrap:toolchain
task bootstrap:mvn
task lefthook:install
task bootstrap:licence-install
task bootstrap:licence-secure
task bootstrap:dotenvrc
```

### 2. Local run

```bash
# backing infra
task docker:start -- floci-ce postgres-ce redis-ce
task dev:floci
task seed:floci

# platform services (native images) + BFF / UI
mert start
```

`mert start` brings up auth, actor, notification, and document from GHCR, plus `actor-bff` and `web-actor` in Quarkus
dev mode.  
Audit is **off** in Community (no `audit-service` image); it is a backing concern, not a product feature, and turns on
seamlessly when you upgrade licence tier.

### 3. Scaffold your own service

```bash
task dev:scaffold -- quote-engine
# optional RDS: task dev:scaffold -- search-service --with-rds
```

Scaffolded services get the platform goodies baked in (auth, throttling, logging, metrics, and the rest of the SDK
surface).

---

## What Community includes

| In                                           | Out (full platform / licence upgrade)                            |
|----------------------------------------------|------------------------------------------------------------------|
| auth, actor, notification, document (native) | audit-service and source code of all core services and libraries |
| actor-bff + web-actor (dev mode)             | IaC; GHA release pipelines; AWS deployment path                  |
| Floci + Postgres + Redis                     | Prometheus / Grafana stack                                       |
| `dev:scaffold` domain services               | —                                                                |
