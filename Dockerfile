# Multi-stage, small, secure Dockerfile for Go microservice
# --- BUILD STAGE ---
FROM golang:1.21-alpine AS builder
WORKDIR /app

# Dependencies
RUN apk add --no-cache git

# Copy go mod and sum, then download deps
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build statically-linked binary
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server

# --- FINAL IMAGE STAGE ---
# Use Google's distroless/static for max security
FROM gcr.io/distroless/static-debian11
WORKDIR /

COPY --from=builder /app/server /server
COPY --from=builder /app/static /static  # In case you have static assets, optional

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/server"]
