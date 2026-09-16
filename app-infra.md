<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# ‏I want to build an app using ai that will have the core elements of a production software development process, including git repository multi platform support, microservices orchestration as a part of both the build and running operation, and testing

You’re describing an **AI-native software delivery platform**: a system that turns a product request into Git changes, builds and runs multi-service applications, executes tests, and creates a controlled deployment workflow. The best approach is to build it as an **orchestration layer over established primitives**, rather than implementing Git, containers, Kubernetes, and CI from scratch.

## Recommended architecture

```text
Web app / CLI
     |
     v
AI control plane
  - Planner
  - Coding agents
  - Test agent
  - Review agent
  - Deployment agent
     |
     v
Workflow orchestrator
  - Jobs
  - approvals
  - retries
  - artifacts
  - audit logs
     |
     +--> Git provider
     +--> Build runners
     +--> Container registry
     +--> Kubernetes / Docker Compose
     +--> Test infrastructure
     +--> Observability
```

Use Kubernetes as the runtime abstraction because it provides deployment, scaling, and management of containerized applications. [^1_1] For source control and CI, GitHub provides repository events, hosted or self-hosted runners, matrix testing, and multi-container workflows. [^1_2][^1_3]

## Core product modules

### 1. Project and repository management

Support a provider-independent repository interface:

```typescript
interface GitProvider {
  createBranch(input: CreateBranchInput): Promise<Branch>;
  readFiles(input: ReadFilesInput): Promise<File[]>;
  commit(input: CommitInput): Promise<Commit>;
  createPullRequest(input: PullRequestInput): Promise<PullRequest>;
  getChecks(commitId: string): Promise<Check[]>;
  mergePullRequest(id: string): Promise<void>;
}
```

Start with:

- GitHub
- GitLab
- Bitbucket
- Local Git repositories

Internally, normalize all providers into common concepts:

- Repository
- Branch
- Commit
- Pull request or merge request
- Check
- Review
- Webhook event

For AI agents working in parallel, use isolated Git worktrees or temporary clones. This prevents agents from overwriting each other’s files and makes each task independently reviewable.

### 2. AI development agents

Do not begin with one autonomous agent that controls everything. Use specialized agents with explicit permissions:


| Agent | Responsibility | Default permissions |
| :-- | :-- | :-- |
| Planner | Converts requirements into tasks and architecture changes | Read repository |
| Implementer | Modifies code in an isolated branch | Read/write branch |
| Test agent | Generates or improves tests | Read/write tests |
| Reviewer | Finds defects and risks | Read-only |
| Debugger | Investigates failed builds or tests | Read logs, write branch |
| Deployment agent | Produces deployment configuration | Limited write |
| Security agent | Runs dependency and code-security checks | Read-only |

The AI should operate through tools rather than unrestricted shell access:

- `read_file`
- `search_code`
- `apply_patch`
- `run_unit_tests`
- `run_linter`
- `build_container`
- `inspect_logs`
- `create_pull_request`

Every action should be recorded as an event:

```json
{
  "run_id": "run_123",
  "agent": "implementer",
  "tool": "apply_patch",
  "repository": "acme/shop",
  "branch": "feature/payment-retry",
  "input_hash": "…",
  "timestamp": "…",
  "result": "success"
}
```

This gives you reproducibility, auditability, and the ability to stop or approve agents.

## Build and runtime orchestration

### Local development

Use Docker Compose or an equivalent local environment for the first version:

```yaml
services:
  api:
    build: ./services/api
    ports:
      - "8080:8080"
    depends_on:
      - postgres

  worker:
    build: ./services/worker
    depends_on:
      - redis

  postgres:
    image: postgres:16

  redis:
    image: redis:7
```

Your platform should infer or generate:

- Dockerfiles
- Compose files
- Environment-variable schemas
- Service dependencies
- Health checks
- Local test commands


### Remote environments

Represent environments explicitly:

```text
development
preview/<pull-request>
staging
production
```

For Kubernetes, map each preview environment to an isolated namespace. A pull request can trigger:

1. Build service images.
2. Push images to a registry.
3. Create a namespace.
4. Deploy all services.
5. Run integration and end-to-end tests.
6. Return a preview URL.
7. Destroy the namespace when the pull request closes.

This pattern is already compatible with GitHub Actions and Kubernetes workflows, including isolated preview namespaces for pull requests. [^1_4]

Use Helm or Kustomize as your deployment representation. The AI can generate these files, but deployment should validate them deterministically before applying them.

## Testing model

Testing should be a first-class pipeline, not an afterthought.

### Required test layers

- **Static checks:** formatting, linting, type checking.
- **Unit tests:** individual functions and modules.
- **Component tests:** one service with its dependencies.
- **Integration tests:** service-to-service and database behavior.
- **Contract tests:** API compatibility between microservices.
- **End-to-end tests:** user journeys through the deployed application.
- **Security checks:** dependency, secret, container, and static-analysis scans.
- **Smoke tests:** basic health checks after deployment.

A useful pipeline is:

```text
Plan
  -> implement
  -> format/lint/type-check
  -> unit tests
  -> build images
  -> integration environment
  -> contract tests
  -> deploy preview
  -> end-to-end tests
  -> AI review
  -> human approval
```

The AI can generate missing tests, but it should not be allowed to declare success based only on tests it created. Require independent checks, coverage thresholds, mutation testing for critical code, and human approval for production changes.

## Workflow engine

You need durable workflows because builds and deployments can last minutes or hours and may fail temporarily. A workflow record could look like:

```json
{
  "workflow": "pull_request",
  "steps": [
    "checkout",
    "install_dependencies",
    "lint",
    "unit_test",
    "build_images",
    "deploy_preview",
    "integration_test",
    "e2e_test",
    "ai_review"
  ],
  "approval_required": false
}
```

Each step should support:

- Timeout
- Retry policy
- Logs
- Artifacts
- Secrets
- Dependency relationships
- Manual approval
- Cancellation
- Idempotent reruns

For the first implementation, you can use a queue plus database-backed state. Later, adopt a durable workflow engine such as Temporal, or integrate with an existing CI engine instead of recreating every execution feature.

## Suggested technology stack

| Layer | Initial choice |
| :-- | :-- |
| Web application | Next.js or React |
| API/control plane | TypeScript with NestJS, Fastify, or Python FastAPI |
| Database | PostgreSQL |
| Job queue | Redis plus BullMQ, or a durable workflow engine |
| Git integration | GitHub App first, then GitLab and Bitbucket |
| Build isolation | Kubernetes Jobs or isolated VMs |
| Containers | Docker or BuildKit |
| Registry | GitHub Container Registry, ECR, GCR, or an S3-compatible registry |
| Runtime | Kubernetes |
| Local orchestration | Docker Compose |
| Deployment format | Helm or Kustomize |
| Tests | Playwright, pytest/Jest, contract-testing framework |
| Observability | OpenTelemetry, Prometheus, Grafana, centralized logs |
| Secrets | Cloud secret manager or Vault |

Existing platforms demonstrate the value of combining Git, CI, continuous delivery, release orchestration, and AI-assisted testing, but your differentiation should be the AI control plane and the coherent experience across the entire development lifecycle. [^1_5]

## MVP scope

Build the smallest useful version around one complete path:

1. User connects a GitHub repository.
2. User describes a feature.
3. AI creates a plan.
4. User approves the plan.
5. An isolated agent branch is created.
6. The agent changes code and adds tests.
7. CI runs linting, unit tests, and a container build.
8. A pull request is opened.
9. A preview environment is deployed.
10. Integration and end-to-end tests run.
11. The user receives a review report and preview URL.

Initially support:

- GitHub only.
- One language, such as TypeScript.
- Docker Compose locally.
- Kubernetes for preview deployments.
- One AI model provider.
- Human approval before merging and production deployment.

Avoid initially building:

- Your own Git hosting service.
- A general-purpose cloud provider.
- Fully autonomous production deployment.
- Support for every programming language.
- A custom container scheduler.
- A universal code-generation benchmark.


## Important safety boundaries

The platform should enforce these rules:

- Production credentials are never exposed to coding agents.
- Agents run in isolated sandboxes with resource limits.
- Pull requests are required for changes to protected branches.
- Deployment manifests undergo schema and policy validation.
- Secrets are injected at runtime, never committed to Git.
- Network access is denied by default and allowlisted per job.
- Destructive operations require explicit approval.
- Every AI-generated change has provenance and an audit trail.
- Failed tests cannot be bypassed by the same agent that wrote the code.

A strong product position would be: **“An AI software factory that creates tested pull requests and disposable microservice environments, while keeping humans in control of merges and production.”**
<span style="display:none">[^1_10][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://kubernetes.io/docs/home/

[^1_2]: https://github.com/kubernetes/.github/actions

[^1_3]: https://docs.github.com/en/actions/get-started/continuous-integration

[^1_4]: https://www.youtube.com/watch?v=79zVyoxnuWY

[^1_5]: https://developer.harness.io/docs/platform/

[^1_6]: https://microservices.io/post/architecture/2026/03/17/overview-i2code-implement-agent-orchestrator.html

[^1_7]: https://docs.cloud.google.com/kubernetes-engine/docs

[^1_8]: https://www.kubernetes.ltd/docs/

[^1_9]: https://github.com/marketplace/actions/kubernetes-action

[^1_10]: https://www.youtube.com/watch?v=vhycjTCjiC4

