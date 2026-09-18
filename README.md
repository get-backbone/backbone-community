# Backbone

**Enterprise foundations. Startup speed.**

Backbone is an opinionated production platform for building SaaS on AWS.

It gives a small team the operational foundations that normally take months or years to build — identity, security, audit,
infrastructure, CI/CD, observability, resilience, data services, and governance — so you launch earlier and spend runway on
product, not undifferentiated infrastructure.

**Build your product. We already built the platform under it.**

[Website](https://backbonehq.io/) · [Docs](https://docs.backbonehq.io/docs/welcome) · [Features](https://docs.backbonehq.io/docs/features)

---

## Why Backbone?

**Year 3 platform maturity on Day 1.**

Backbone collapses the work of building a production foundation:

* **Ship earlier** — build domain services from day one, and skip months of software foundations and platform engineering
* **Protect runway** — avoid a comparable in-house platform build; keep senior engineers focused on your product domain and services
* **Proven scale** — published ECS/Fargate load results support hundreds of concurrent users/requests with no evident
  ceiling ([benchmarks](https://docs.backbonehq.io/docs/performance))
* **Enterprise-grade security** — Cognito, service auth, least-privilege IAM, OIDC deployment identity, WAF, private
  networking, encryption ([security](https://docs.backbonehq.io/docs/security))
* **Comprehensive compliance footing** — audit trails, control mapping, and shared-responsibility evidence for SOC 2 /
  GDPR / HIPAA-aligned objectives ([compliance](https://docs.backbonehq.io/docs/compliance))
* **De-risk due diligence** — architecture, infrastructure, and controls already exist, documented and inspectable
* **Massive engineering leverage** — years of platform engineering, already built and integrated

Not a framework. Not a hosted PaaS.

**Your AWS. Your GitHub. Your code. Your data.**

---

## Community: build the product first

**Community is the free local development gateway to Backbone.**

It gives you the scaffolding and golden path to build your own domain services on top of the Backbone platform.

The Community edition deliberately **doesn't** open-source the production platform itself; you are unable to extend core
features (such as auth) or deploy it to production until licenced.

### Includes

* Local Floci / Postgres / Redis
* Pre-built native platform services — auth, actor, notification, document
* BFF + stateless reference UI in Quarkus dev mode
* scaffold and run domain services immediately with auth, throttling, logging, and metrics all baked-in
* Open SDK surface and development tooling

### Does not include

* Backbone core service or library source
* AWS deployment, CDK/IaC, or production infrastructure
* Full production CI/CD workflows
* Production observability, governance, and scaling
* Commercial licence entitlements

Community's core runtime is distributed as **protected native images, not source code**.

Audit is a production platform capability and is not included in Community.

---

## Upgrade when you need the cloud

The path is deliberately simple:

1. **Build locally** and develop your domain services on Community
2. **Prove the product** – your domain code is built against the Backbone platform
3. **Licence and deploy** to your AWS account when you're ready
4. **Choose the commercial tier you need** — Foundation, Growth, or Enterprise progressively unlock production capabilities

Your domain code carries forward. You don't rebuild the platform when you go to production.

[Features](https://docs.backbonehq.io/docs/features) · [Pricing](https://backbonehq.io/#pricing)

---

## Quick Start

Approx. 10 minutes.

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

### 2. Start the local platform

```bash
task docker:start -- floci-ce postgres-ce redis-ce jaeger-ce
task dev:floci
task seed:floci
mert start
```

### 3. Scaffold a domain service

```bash
task dev:scaffold -- quote-engine
# optional RDS:
task dev:scaffold -- search-service --with-rds
```

**You're building product, not platform.**

[Development guide](https://docs.backbonehq.io/docs/development) ·
[Cheatsheet](https://docs.backbonehq.io/docs/cheatsheet) ·
[Runbook](https://docs.backbonehq.io/docs/runbook)

---

**Backbone** — *Enterprise foundations. Startup speed.*
