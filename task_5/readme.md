# Task 5 — Observability (low-cost / easy setup)

This folder captures the observability plan I prepared for the assignment with a bias toward tools that are inexpensive (or free), lightweight to install, and easy to operate.

## What we observe

- **Metrics** – expose service health (requests, latency, errors) via OpenTelemetry or Prometheus exporters.
- **Logs** – capture structured app logs via Loki/Promtail or plain `stdout` + `tail` when you need a quick fallback.
- **Tracing** – add basic OpenTelemetry spans for long-running workflows (optional but nice for debugging complex flows).

## Tooling overview

| Concern | Tool | Why it fits low-cost/easy setup |
| --- | --- | --- |
| Metric collection | Prometheus (kube-prometheus-stack or simple binary) | Open source, single binary, works with service discovery or static scrape configs. |
| Visualization | Grafana OSS (self-hosted) | Hooks directly into Prometheus/Loki; free forever. |
| Logging | Loki + Promtail | Bundled with Grafana Labs stack, stores logs cost-effectively; Promtail tails files or listens on Docker/containers. |
| Tracing | OpenTelemetry Collector + Jaeger (optional) | Configurable pipeline that can export to Grafana Tempo or console (no vendor lock-in). |
| Observability platform | OpenObserve (OSS alternative to Grafana Cloud) | Walks through ingestion of metrics/logs/traces, uses ClickHouse/Zipkin, lightweight daemonized. |
| Full-stack variant | ELK Stack + Grafana + Prometheus | Use Beats for logs, Prometheus for metrics, Grafana for dashboards; many Helm charts available for kube-state-metrics + kube-prometheus-stack. |

## Quickstart (local or dev cluster)

1. **Metrics** – fire up Prometheus with a simple `prometheus.yml` that scrapes the backend (`localhost:8080/metrics` works if the FastAPI app exposes OpenTelemetry Prometheus metrics).
2. **Logs** – run Loki (it can be the standalone binary) and pair it with Promtail that tails the backend log file or `stdout`.
3. **Dashboard** – start Grafana, wire in Prometheus + Loki data sources, and import FastAPI/Next.js dashboards.
4. **Trace (optional)** – add OpenTelemetry SDK spans to the backend and send them to a local collector that forwards to Jaeger or Grafana Tempo.
5. **ELK + kube-stack** – deploy kube-state-metrics plus the `kube-prometheus-stack`, turn on Alertmanager, and use Filebeat/Metricbeat or Fluent Bit to push logs into Elasticsearch while Grafana or Kibana renders them.
6. **OpenObserve path** – grab the operator bundle or Docker image, point it at your Prometheus scrape configs/log endpoints/traces, and let its ClickHouse-powered UI (or Grafana) show everything in one place.

## Observability stack comparison

| Stack | Ease of setup | Cost | Maintenance |
| --- | --- | --- | --- |
| `kube-prometheus-stack` (metrics + Alertmanager) | Helm chart makes it quick on Kubernetes but needs Prometheus familiarity. | Free; runs on existing nodes, scales with metric volume. | Moderate; monitor Prometheus compaction/retention and keep Alertmanager rules updated. |
| Self-hosted OpenObserve (non-HA) | Very simple Docker/Helm install, single service for metrics/logs/traces. | Open source; resource usage driven by ClickHouse retention. | Low; mostly ClickHouse/Zipkin upkeep if retention stays reasonable. |
| ELK Stack + Grafana + Prometheus | Harder setup—Elasticsearch, Beats, Kibana + Grafana/Prometheus. Needs config for each. | Highest resource/storage requirements among the three due to Elasticsearch. | Highest; Elasticsearch indices, heap tuning, Kibana dashboards, Beats upgrades. |

## Must-have dashboards

- **Cluster/Control plane heatmap** – include panels showing node CPU/memory usage, pod capacity, and kube-apiserver latency (from `kube-state-metrics`) so you can quickly spot saturated nodes or control-plane slowness in the EKS cluster.
- **Workload health** – a backend dashboard with FastAPI request rate, P95/P99 latency, success/error counts, MongoDB connection usage, and pod restarts.
- **Alert view** – surfaces Alertmanager silences and firing alerts (OOMKilled, CrashLoopBackOff, high latency) so the reviewer can see how notifications would behave.
- **Log+trace correlation** – dashboards that link Grafana Loki (or OpenObserve logs) with Tempo/OpenObserve traces showing slow endpoints plus the associated log lines for rapid debugging.

## Future scope

- For multi-environment or multi-cluster setups, centralize telemetry by pushing logs, metrics, and traces to a shared observability gateway running inside the EKS cluster.
- Use remote write/remote read for Prometheus, remote storage for traces, and a log-forwarder (Fluent Bit/Logstash) that ships to Elasticsearch or Loki that lives alongside the gateway.
- Maintain separate Grafana dashboards per environment/cluster but drive them from the same central data sources so alerts and histories stay cohesive while still providing per-namespace context.
