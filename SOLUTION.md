# Solution Steps

1. 1. Refactor the Dockerfile into a secure multi-stage build:

2.    - Use golang:1.21-alpine as the builder stage.

3.    - Build a statically linked Linux binary with CGO_ENABLED=0.

4.    - Use the distroless/static-debian11 base image for the final stage (no shell, minimal attack surface).

5.    - Copy only the binary and static assets (if any) to the final image.

6.    - Use a non-root user with USER nonroot:nonroot, expose port 8080, and set ENTRYPOINT to the binary.

7. 2. Update docker-compose.yml for resource hardening:

8.    - Add deploy.resources.limits for CPU (0.5), memory (256M), and pids (100) per container.

9.    - Add healthcheck using curl against /health endpoint, with appropriate intervals and retries.

10.    - Add restart: always policy.

11.    - Ensure the exported port is 8080:8080, and optionally set GOMEMLIMIT to 200MiB.

12. 3. Modify main.go for graceful shutdown on SIGTERM:

13.    - Use os/signal to listen for SIGINT and SIGTERM.

14.    - On receiving a signal, initiate server.Shutdown() with a context timeout (10s), and wait for shutdown to complete before process exit.

15.    - Existing handlers and endpoints remain unchanged, just wrap server lifecycle for graceful shutdown.

16. 4. Create deployment_metrics.sh to automate before/after metrics:

17.    - Script builds the Docker image, measures build time, image size, starts the container, waits for healthy status, and collects memory usage and /health endpoint response time.

18.    - Outputs all metrics to console, tears down container afterward.

19. 5. (Optional but recommended) Test both before and after optimization:

20.    - Run the deployment_metrics.sh script before making changes to collect baseline data.

21.    - Re-run after optimization to compare reductions in image size, memory usage, and improvements in stability.

