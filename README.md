[![CI](https://github.com/artem-on-dev/devops-engineer-from-scratch-project-315/actions/workflows/ci.yml/badge.svg)](https://github.com/artem-on-dev/devops-engineer-from-scratch-project-315/actions/workflows/ci.yml)
[![hexlet-check](https://github.com/artem-on-dev/devops-engineer-from-scratch-project-315/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/artem-on-dev/devops-engineer-from-scratch-project-315/actions/workflows/hexlet-check.yml)

# Project DevOps Deploy

Bulletin board service. Spring Boot backend with React Admin frontend, deployed via Ansible to a DigitalOcean VPS with Nginx reverse proxy and Let's Encrypt SSL.

## Production

Available at: https://devops-3.sytes.net

## Infrastructure

The application is deployed to a single Ubuntu server using Ansible. The playbook provisions:

- **Docker** — runs the application container
- **Nginx** — reverse proxy with HTTPS redirect and static file caching
- **Certbot** — automatic Let's Encrypt SSL certificate provisioning and renewal
- **UFW** — firewall allowing only SSH (32223), HTTP (80), and HTTPS (443)

### Ansible roles

| Role | Version | Purpose |
|------|---------|---------|
| `geerlingguy.docker` | 8.0.0 | Docker engine and compose plugin |
| `geerlingguy.certbot` | 5.4.1 | Let's Encrypt certificates |
| `geerlingguy.nginx` | 3.3.0 | Nginx installation and vhost config |
| `deploy` (local) | — | App container, volumes, env vars |

### Deploying

```bash
# Install Ansible roles and collections
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

# Deploy to production
make deploy
```

The vault password file (`.vault_password`) must exist locally. It contains the password to decrypt `group_vars/production/vault.yml` with database and S3 credentials.

### Server access

SSH is configured on a custom port (32223). Connection details are in `inventory.ini`.

## Container

```bash
make image      # build Docker image (artemstepanenko/bulletins:<version>)
make container  # run container on http://localhost:8080
make publish    # push image to Docker Hub
```

Or directly:

```bash
docker run --rm -p 8080:8080 artemstepanenko/bulletins:0.0.1
```

The default `dev` profile uses an in-memory H2 database and seeds 10 sample bulletins through `DataInitializer`, so the API works immediately after startup.

API documentation is available via Swagger UI at `http://localhost:8080/swagger-ui/index.html`.

## Project layout

- Backend (Spring Boot) lives in the repository root.
- Frontend (React Admin + Vite) is located in `frontend/`.
- Ansible playbook and roles are in the repository root (`playbook.yml`, `roles/`).
- Shared static assets for the backend are served from `src/main/resources/static` (populated by the frontend build when needed).

## Environment variables

Key variables are read directly by Spring Boot (see `src/main/resources/application.yml` and `application-prod.yml` for defaults):

| Variable                     | Description                                                   | Default                                      |
|------------------------------|---------------------------------------------------------------|----------------------------------------------|
| `SPRING_PROFILES_ACTIVE`     | Active Spring profile (`dev`, `prod`, etc.)                   | `dev`                                        |
| `SPRING_DATASOURCE_URL`      | JDBC URL for PostgreSQL in `prod`                             | `jdbc:postgresql://localhost:5432/bulletins` |
| `SPRING_DATASOURCE_USERNAME` | DB username                                                   | `postgres`                                   |
| `SPRING_DATASOURCE_PASSWORD` | DB password                                                   | `postgres`                                   |
| `STORAGE_S3_BUCKET`          | Bucket name for bulletin images                               | empty                                        |
| `STORAGE_S3_REGION`          | Region for the S3-compatible storage                          | empty                                        |
| `STORAGE_S3_ENDPOINT`        | Optional custom endpoint                                      | empty                                        |
| `STORAGE_S3_ACCESSKEY`       | Access key ID                                                 | empty                                        |
| `STORAGE_S3_SECRETKEY`       | Secret key                                                    | empty                                        |
| `STORAGE_S3_CDNURL`          | Optional public CDN prefix                                    | empty                                        |
| `MANAGEMENT_SERVER_PORT`     | Port for Spring Actuator endpoints (health, metrics, etc.)    | `9090`                                       |
| `JAVA_OPTS`                  | Extra JVM parameters (heap, `-Dspring.profiles.active`, etc.) | empty                                        |

## Requirements

- JDK 21+
- Gradle 9.2.1
- Make
- NodeJS 20+
- Ansible (for deployment)
- PostgreSQL only if you run the `prod` profile with an external database

## Running

### Backend (local dev profile)

1. Install prerequisites from the **Requirements** section.
2. From the repository root start the backend:

    ```bash
    make run
    ```

3. Explore the API:
   - `GET http://localhost:8080/api/bulletins`
   - Swagger UI: `http://localhost:8080/swagger-ui/index.html`

### Frontend (development build)

1. Open a second terminal and move into the frontend directory:

    ```bash
    cd frontend
    make install   # npm install
    make start     # Vite dev server on http://localhost:5173
    ```

2. The dev server proxies `/api` requests to `http://localhost:8080`, so keep the backend running.

### Useful commands

See [Makefile](./Makefile)

## Linting

```bash
make lint         # Java code style (Spotless)
make lint-fix     # auto-fix Java formatting
```

## Monitoring

- Application: port `8080`
- Actuator (health, metrics, Prometheus): port `9090`
- Health probes: `/actuator/health/liveness` and `/actuator/health/readiness`

## Logging

Structured JSON to stdout via `logback-spring.xml` (Logstash encoder). Fields: `timestamp`, `app`, `environment`, `instance`, `logger`, `thread`, message, MDC, stack traces.
