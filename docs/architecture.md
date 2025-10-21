# Airbyte Architecture

## Overview

This document describes the architecture of our Airbyte deployment on Kubernetes.

## Components

### Core Components

1. **Webapp (UI)**
   - User interface for Airbyte
   - React-based single-page application
   - Communicates with Server API

2. **Server (API)**
   - REST API backend
   - Handles business logic and orchestration
   - Manages connector configurations

3. **Worker**
   - Executes sync jobs
   - Runs connectors in isolated containers
   - Can be scaled horizontally

4. **Scheduler (Temporal)**
   - Manages job scheduling and orchestration
   - Ensures reliable job execution
   - Provides workflow durability

### Data Stores

1. **PostgreSQL**
   - Stores Airbyte configuration
   - Connection metadata
   - Job history and logs

2. **Minio (S3-compatible)**
   - Stores connector logs
   - Intermediate state files
   - Large payloads

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      Ingress / Load Balancer             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │    Airbyte Webapp     │
         │        (UI)           │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │    Airbyte Server     │
         │       (API)           │
         └───────────┬───────────┘
                     │
        ┏━━━━━━━━━━━━┻━━━━━━━━━━━━┓
        ▼                          ▼
┌───────────────┐          ┌──────────────┐
│   Temporal    │          │  PostgreSQL  │
│  (Scheduler)  │          │  (Metadata)  │
└───────┬───────┘          └──────────────┘
        │
        ▼
┌───────────────────────┐
│   Airbyte Workers     │
│   (Sync Execution)    │
└───────┬───────────────┘
        │
        ▼
┌───────────────┐
│    Minio      │
│  (S3 Storage) │
└───────────────┘
```

## Data Flow

1. User configures connection in Webapp
2. Configuration stored in PostgreSQL via Server API
3. Temporal schedules sync jobs
4. Worker pods execute connector sync
5. Sync data flows through worker
6. Logs and state written to Minio
7. Job status updated in PostgreSQL

## Scaling Strategy

### Horizontal Scaling

- **Workers**: Primary scaling target
  - Scale based on job queue depth
  - Each worker handles multiple jobs
  - Configure HPA based on CPU/memory

- **Server**: Can be scaled for HA
  - Stateless, safe to scale
  - Multiple replicas for reliability

### Vertical Scaling

- **PostgreSQL**: Scale based on data volume
- **Minio**: Add storage as needed
- **Temporal**: Scale for job throughput

## High Availability

Production deployments should include:

1. Multiple replicas of stateless components
2. Pod anti-affinity rules
3. Pod disruption budgets
4. Database replication
5. Backup and recovery procedures

## Security

1. **Network Policies**: Restrict pod-to-pod communication
2. **RBAC**: Limit service account permissions
3. **Secrets Management**: Use SOPS or Sealed Secrets
4. **TLS**: Encrypt ingress traffic
5. **Pod Security**: Use security contexts and policies

## Monitoring

Key metrics to monitor:

- Job success/failure rates
- Job duration
- Worker CPU/memory usage
- Database connections and performance
- Storage usage
- API latency

## Backup and Recovery

Critical data:

1. PostgreSQL database (contains all configurations)
2. Minio bucket (contains logs and state)

See [disaster-recovery.md](runbooks/disaster-recovery.md) for procedures.

