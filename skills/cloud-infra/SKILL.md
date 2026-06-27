---
name: cloud-infra
description: Guides infrastructure decisions and provisioning for backend services. Invoked when deploying a service, choosing between AWS/Cloudflare/Hetzner, setting up IaC, designing cloud architecture, provisioning compute or storage, optimizing cloud costs, considering edge vs. regional deployment, or making infrastructure reproducible. Produces IaC-first, cost-aware, portable infrastructure.
---

# Cloud Infrastructure

Choose the platform that matches the workload, not the one with the most features. Default to IaC. Keep infra reproducible and cost-transparent.

> **Stack profile:** AWS / Cloudflare / Hetzner are the default targets. Before provisioning, read `.ai/stack-profile.md` if present (see the `stack-profile` skill). If it names a different target (GCP, Azure, Fly, self-host) or IaC tool, treat the patterns here as portable intent — research that provider's/tool's idioms first, then build to the same discipline (IaC-first, reproducible, cost-transparent). Absent or matching ⇒ use these defaults directly.

## Process

**Choose the platform by workload first.**
Resist the urge to default to AWS for everything. Each platform has a distinct cost/capability profile — match workload characteristics to platform strengths before writing a single Terraform file.

**IaC by default.**
All infrastructure is defined in code from day one — Terraform/OpenTofu preferred for AWS and Hetzner, Wrangler for Cloudflare Workers config. No click-ops resources in production. IaC means state is reviewable, reproducible, and team-auditable. Commit infra alongside application code.

**Cost + portability tradeoffs explicit.**
When recommending a platform or service, name the cost model and the lock-in cost. Managed services accelerate delivery but raise migration cost. Weigh this against team bandwidth and timeline.

---

### AWS — managed breadth, scale

**When to choose AWS.**
Large-scale stateful workloads; when you need RDS (managed Postgres/MySQL), ElastiCache, SQS/SNS, S3, ECS/EKS, or Lambda at scale; when the team needs managed databases with automated failover; when compliance or enterprise contracts require it.

**Recommended patterns.**
- Compute: ECS Fargate (containerized) or Lambda (event-driven, sub-100ms cold start). Avoid EC2 unless you need GPU, bare-metal control, or a cost profile that Fargate can't match.
- Storage: S3 for objects; RDS (Postgres) for relational; DynamoDB for high-throughput key-value if the access pattern fits. Don't use DynamoDB if your queries require flexible filtering — that's a relational problem.
- Networking: VPC with private subnets for data-plane services; ALB in front of Fargate; CloudFront for static assets and edge caching.
- IaC: Terraform (AWS provider) or CDK if the team is TypeScript-native.

**Watch for.**
Egress costs are high. Avoid cross-AZ data transfer on hot paths. Reserved instances / Savings Plans cut compute cost significantly on stable workloads — plan for them after baseline is stable.

---

### Cloudflare — edge, Workers, low-latency global

**When to choose Cloudflare.**
Latency-sensitive global APIs where responses can be served from the edge; stateless or lightly-stateful workloads; static + dynamic serving under one domain; when Cloudflare KV, Durable Objects, D1, R2, or Queues cover the data needs; when egress cost is a primary concern (R2 has no egress fees).

**Recommended patterns.**
- Compute: Workers (V8 isolates, ~0ms cold start, 50ms CPU limit per request by default). For long-running compute use Workers with streaming or offload to a durable queue.
- Storage: KV for globally replicated key-value (eventual consistency); Durable Objects for strongly consistent, co-located state (WebSocket sessions, counters, coordination); R2 for objects (S3-compatible, no egress fees); D1 for SQLite-backed relational queries at the edge.
- Config: `wrangler.toml` is the IaC entry point. Use Terraform Cloudflare provider for DNS, WAF rules, and Access policies alongside Wrangler for Workers config.

**Watch for.**
Workers CPU time limit (50ms by default, 30s with Unbound billing). No persistent TCP connections inside a Worker — database access must be over HTTP (Hyperdrive for Postgres connection pooling at the edge, or use D1/KV/Durable Objects). Bundle size matters — tree-shake aggressively.

---

### Hetzner — raw price/performance, dedicated + VPS

**When to choose Hetzner.**
CPU/memory-intensive workloads where AWS equivalent costs are prohibitive; self-managed Postgres clusters; batch processing; ML inference (GPU servers); projects where the team can manage the OS layer; EU data-residency without AWS Frankfurt pricing.

**Recommended patterns.**
- Compute: Cloud VPS (CX/CCX lines) for general workloads; dedicated servers (AX line) for heavy CPU or large RAM needs; GPU servers for ML.
- Networking: Hetzner private networks (free intra-datacenter traffic); Hetzner Load Balancer for distributing across VPS instances.
- Storage: Hetzner Volumes (block storage, attached to a single VPS) for databases; Hetzner Object Storage (S3-compatible) for objects.
- IaC: Terraform (hetznercloud provider). Provision servers, networks, load balancers, and firewalls in code. Use cloud-init for initial OS bootstrapping; Ansible or Nix for ongoing config management.

**Watch for.**
You own the OS: patching, kernel upgrades, and database tuning are your responsibility. Budget operational overhead accordingly. Hetzner has no managed Kubernetes that matches EKS feature parity — use k3s or Talos for lightweight Kubernetes, or keep it simple with Docker Compose on dedicated servers if the scale doesn't require orchestration.

---

### Cross-cutting practices

**Reproducibility.**
Every environment (dev, staging, prod) is provisioned from the same IaC with per-environment variable overrides. No manual state. Destroy and recreate staging to verify reproducibility before a major change lands in prod.

**Secrets management.**
Never commit secrets. Use AWS Secrets Manager / Parameter Store (AWS), Cloudflare Secrets (Workers), or HashiCorp Vault / Hetzner-compatible secret store for Hetzner deployments. Inject at deploy time via environment variables or a secrets provider.

**Observability from day one.**
Provision structured logging (CloudWatch, Cloudflare Logpush, or self-hosted Loki), metrics (Prometheus + Grafana or hosted equivalents), and distributed tracing (OTEL collector) alongside the service. Observability infrastructure is part of the IaC, not an afterthought.

**Cost hygiene.**
Set budget alerts before deploying to prod. Tag all resources with service + environment + owner. Review costs weekly during early scaling — surprises compound fast with managed services at scale.
