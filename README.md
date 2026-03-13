# Senior DevOps Engineer - Technical Assessment

## Overview

This assessment evaluates your ability to containerize an application, build a CI/CD pipeline, and structure a Helm chart for Kubernetes deployment. You have **5 days** to complete it, though we expect it to take roughly **1 day** of focused work.

## What You Need to Do

1. Create a **public** GitHub repository on your own GitHub account
2. Use the contents of this zip as your starting point
3. Complete the tasks below
4. Send us the link to your repository when you're done

---

## Task 1: Dockerfile

A simple Go "Hello World" web server is provided in the `app/` directory.

Write a **production-ready Dockerfile** for this application. Place it at the root of the repository.

Things we look for:
- Multi-stage build
- Minimal final image
- Runs as a non-root user
- Proper use of build cache

---

## Task 2: GitHub Actions Pipeline

Create a GitHub Actions workflow (`.github/workflows/ci.yml`) that triggers on pushes to `main` and on pull requests.

The pipeline should have **3 jobs**:

**Job 1 - Lint Helm Chart:**
- Build the lib-common dependency (`helm dependency build`)
- Lint the chart (`helm lint`)
- Render the chart (`helm template`) to verify it produces valid output

**Job 2 - Lint Dockerfile:**
- Lint the Dockerfile using [hadolint](https://github.com/hadolint/hadolint)

**Job 3 - Build Docker Image:**
- Should only run after the linting jobs pass
- Build the Docker image using Docker Buildx
- Tag the image with the **git short SHA**
- The image does not need to be pushed to a registry

---

## Task 3: Helm Chart

Create a Helm chart in `helm/hello-world/` that deploys the application to Kubernetes.

Your chart **must** use the provided library chart located in `helm/lib-common/` as a dependency. The library chart provides common templates for Deployments and Services that you should reference in your chart's templates.

Your chart should include:
- `Chart.yaml` (with lib-common as a local dependency)
- `values.yaml` with sensible defaults
- Templates for a Deployment and a Service (using the library helpers)
- Resource requests and limits
- Health check probes (the app exposes `/healthz`)

> **Note:** Review the library chart carefully. If you find any issues, fix them and document what you changed and why in your README.

---

## Deliverables

Your submitted repository should contain:

```
.
├── Dockerfile
├── .github/
│   └── workflows/
│       └── ci.yml
├── app/
│   ├── main.go
│   └── go.mod
├── helm/
│   ├── hello-world/          (you create this)
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       └── service.yaml
│   └── lib-common/           (provided - fix any issues you find)
│       ├── Chart.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── _deployment.tpl
│           └── _service.tpl
└── README.md                 (your notes, decisions, and any issues found)
```

---

## Bonus: Local Deployment

For bonus points, deploy the application to a local Kubernetes cluster (e.g. Docker Desktop with Kubernetes enabled):

1. Build the Docker image locally
2. Install the Helm chart into your cluster
3. Port-forward the service to `localhost:8081`
4. Include screenshots in your README showing:
   - The app running at `http://localhost:8081/`
   - The health check at `http://localhost:8081/healthz`
   - `kubectl get pods` and `kubectl get svc` output showing healthy resources

This is not required but demonstrates hands-on Kubernetes experience.

---

## Evaluation Criteria

| Area                    | What we're looking at                              |
|-------------------------|----------------------------------------------------|
| Dockerfile              | Build stages, security, image size, caching        |
| GitHub Actions          | Pipeline structure, linting, build steps           |
| Helm chart              | Clean structure, proper use of library, values     |
| Library chart bug       | Did you find it? How did you fix it?               |
| Documentation           | Clear reasoning and trade-off awareness            |
| Local deployment (bonus)| Screenshots of app running in a local k8s cluster  |

Good luck!

---

# Implementation Notes

## Stage 1: Dockerfile

Created multi-stage Dockerfile with the following:

- **Build stage**: Uses `golang:1.22-alpine` image for app build
- **Final stage**: Uses minimal `alpine:3.19.1` base image (~5MB)
- **Digest pinning**: Both base images pinned to specific SHA256 digests for reproducibility and security
- Runs application as non-root user (appuser)
- Pinned `ca-certificates` version to `20250911-r0` for security and reproducibility
- Exposes port 8080
- Optimized for build cache with proper layer ordering

**Production Safety:**
- Digest pinning prevents unexpected base image changes
- Ensures reproducible builds across environments
- See `docs/BASE_IMAGE_MANAGEMENT.md` for digest update policy

---

## Stage 2: GitHub Actions Pipeline

Created `.github/workflows/ci.yml` with three jobs:

**Job 1: Lint Helm Chart**
- Set up Helm v3.14.0
- Install kubeconform for Kubernetes manifest validation
- Build dependencies with `helm dependency build`
- **Verify lib-common integrity** using SHA256 checksum to detect unauthorized changes
- **Verify dependency version** matches expected version (0.1.0)
- Lints chart with `helm lint`
- Validate template rendering with `helm template`
- **Validate Kubernetes manifests** with kubeconform for runtime compatibility

**Production Safety Features:**
- Version pinning validation prevents unexpected lib-common changes
- Checksum verification ensures chart integrity
- Kubeconform validates against Kubernetes API schemas (catches invalid resources, deprecated APIs)
- Strict validation mode catches configuration errors before deployment

**Job 2: Lint Dockerfile**
- Uses `hadolint-action` v3.1.0 for Dockerfile linting
- Enforces best practices (pinned versions, specific tags)

**Job 3: Build Docker Image**
- Depends on both lint jobs (runs only if they pass)
- Uses Docker Buildx for efficient builds
- Tags image with git SHA: `hello-world:${{ github.sha }}`
- Implemented GitHub Actions cache for faster builds

---

## Stage 3: Helm Chart

Created `helm/hello-world/` chart that uses the `lib-common` library chart as a dependency:

```
helm/hello-world/
├── Chart.yaml          (references lib-common as file://../lib-common)
├── values.yaml         (includes resource limits and health probes)
└── templates/
    ├── deployment.yaml (uses lib-common.deployment template)
    └── service.yaml    (uses lib-common.service template)
```

**Key features:**
- Resource requests and limits defined
- Liveness and readiness probes configured for `/healthz` endpoint
- Service exposes port 80, targeting container port 8080
- Follows Kubernetes best practices

---

## Stage 4: Library Chart Issue

In `helm/lib-common/templates/_deployment.tpl`, the `ports` field was incorrectly indented at line 24. 

**Fix:** Corrected by aligning `ports` with `imagePullPolicy` to ensure proper YAML structure and Kubernetes resource validation.

---

## Stage 5: Local Deployment

Successfully deployed to local Kubernetes cluster:

1. Built Docker image: `docker build -t hello-world:latest .`
2. Loaded image into kind cluster: `kind load docker-image hello-world:latest --name hello-world-local`
3. Built Helm dependencies: `cd helm/hello-world && helm dependency build`
4. Installed Helm chart: `helm install hello-world .`
5. Port-forwarded service: `kubectl port-forward svc/hello-world-hello-world 8081:80`

See screenshots in the repository showing:
- Application running at `http://localhost:8081/`
- Health check at `http://localhost:8081/healthz`
- `kubectl get pods` and `kubectl get svc` output
