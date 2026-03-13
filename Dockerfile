# Build stage
# Using digest pinning for reproducible builds and security
FROM golang:1.22-alpine@sha256:8e96e6cff6a388c2f70f5f662b64120941fcd7d4b89d62fec87520323a316bd9 AS builder

WORKDIR /build

# Copy go mod files first for better caching
COPY app/go.mod app/go.sum* ./
RUN go mod download

# Copy source code
COPY app/main.go ./

# Build the binary with optimizations and version info
# Keep debug symbols for production troubleshooting
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-X main.Version=${VERSION} -X main.Commit=${COMMIT} -X main.BuildDate=${BUILD_DATE}" \
    -o hello-world .

# Final stage
# Using digest pinning for security and reproducibility
FROM alpine:3.19.1@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b

# Install ca-certificates for HTTPS requests
# hadolint ignore=DL3018
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/hello-world .

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Run the application
CMD ["./hello-world"]
