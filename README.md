# Implementation Notes

## Stage 1: Dockerfile

Created multi-stage Dockerfile with the following:

- **Build stage**: Uses `golang:1.22-alpine` image for app build
- **Final stage**: Uses minimal `alpine:3.19.1` base image (~5MB)
- Runs application as non-root user (appuser)
- Exposes port 8080
- Optimized for build cache with proper layer ordering

**Production Safety:**
- Digest pinning prevents unexpected base image changes
- Ensures reproducible builds across environments

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

In `helm/lib-common/templates/_deployment.tpl`,`ports` field was incorrectly indented at line 24. 

**Fix:** Corrected by aligning `ports` with `imagePullPolicy` to ensure proper YAML structure and Kubernetes resource validation.

---

## Stage 5: Local Deployment

Successfully deployed to local Kubernetes cluster:

1. Built Docker image: `docker build -t hello-world:1.0 .`
2. Loaded image into kind cluster: `kind load docker-image hello-world:1.0 --name hello-world-local`
3. Built Helm dependencies: `cd helm/hello-world && helm dependency build`
4. Installed Helm chart: `helm install hello-world .`
5. Port-forwarded service: `kubectl port-forward svc/hello-world-hello-world 8081:80`

See screenshots in the repository showing:
- Application running at `http://localhost:8081/`
- Health check at `http://localhost:8081/healthz`
- `kubectl get pods` and `kubectl get svc` output
