# Base Image Digest Management

## Current Pinned Images

### Build Stage
- **Image**: `golang:1.22-alpine`
- **Digest**: `sha256:8e96e6cff6a388c2f70f5f662b64120941fcd7d4b89d62fec87520323a316bd9`
- **Last Updated**: 2024-03-13
- **Reason**: Reproducible builds, prevent unexpected Go version changes

### Runtime Stage
- **Image**: `alpine:3.19.1`
- **Digest**: `sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b`
- **Last Updated**: 2024-03-13
- **Reason**: Security, reproducibility, prevent package repository changes

## Why Digest Pinning?

1. **Reproducibility**: Same Dockerfile always produces identical builds
2. **Security**: Explicit control over when base images update
3. **Stability**: Prevents unexpected breaking changes from upstream
4. **Audit Trail**: Clear record of what base images were used

## How to Update Digests

### Manual Update
```bash
# Get latest digest for golang:1.22-alpine
docker pull golang:1.22-alpine
docker inspect golang:1.22-alpine | grep -A 1 RepoDigests

# Get latest digest for alpine:3.19.1
docker pull alpine:3.19.1
docker inspect alpine:3.19.1 | grep -A 1 RepoDigests
```

## Update Policy

- **Security patches**: Update within 48 hours of CVE disclosure
- **Minor updates**: Review and update monthly
- **Major updates**: Test thoroughly in staging before production
