# Task Management API

A production-style **Spring Boot 3** showcase: REST API for tasks, layered architecture, validation, JPA with **H2** (local) and **PostgreSQL** (production), tests with **JUnit 5** and **Mockito**, **Docker**, **GitHub Actions** CI, and deployment notes for **AWS Elastic Beanstalk**.

## Tech stack

| Area | Choice |
|------|--------|
| Language | Java 21 |
| Framework | Spring Boot 3.4 |
| Build | Maven |
| Web | Spring Web |
| Persistence | Spring Data JPA |
| Databases | H2 (local), PostgreSQL (production profile) |
| Utilities | Lombok |
| Testing | JUnit 5, Mockito, AssertJ |
| Container | Docker (eclipse-temurin:21-jdk) |
| CI | GitHub Actions |

## Project layout

```
.
├── Dockerfile
├── Procfile
├── docker-compose.yml
├── pom.xml
├── .github/workflows/ci.yml
└── src/main/java/com/example/taskmanagement/
    ├── TaskManagementApplication.java
    ├── controller/          # REST layer
    ├── service/             # Business logic
    ├── repository/        # JPA repositories
    ├── model/               # Entities & enums
    ├── dto/                 # Request/response DTOs
    └── exception/           # Global exception handling
```

## API

Base path: `/tasks` (default server port **8080**).

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/tasks` | List all tasks |
| `GET` | `/tasks/{id}` | Get task by id |
| `POST` | `/tasks` | Create task (JSON body, validated) |
| `PUT` | `/tasks/{id}` | Update task |
| `DELETE` | `/tasks/{id}` | Delete task |

**Task fields:** `id`, `title` (required), `description`, `status` (`TODO` \| `IN_PROGRESS` \| `DONE`), `createdAt` (set on create).

Example create body:

```json
{
  "title": "Ship feature",
  "description": "API + tests",
  "status": "TODO"
}
```

## Run locally (H2)

Default profile is `local` (in-memory H2, JPA `ddl-auto: update`).

```bash
mvn spring-boot:run
```

H2 console (dev only): `http://localhost:8080/h2-console`  
JDBC URL: `jdbc:h2:mem:taskdb` — user `sa`, empty password.

## Run locally against PostgreSQL

Start PostgreSQL, create a database (e.g. `taskdb`), then:

```bash
export SPRING_PROFILES_ACTIVE=production
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/taskdb
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=postgres
mvn spring-boot:run
```

## Run with Docker

The `Dockerfile` expects a built fat JAR at `target/application.jar` (Maven `finalName` is `application`).

```bash
mvn -B verify
docker build -t task-management:local .
docker run --rm -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=production \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/taskdb \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  task-management:local
```

### Docker Compose (app + PostgreSQL)

Build the JAR first, then start the stack:

```bash
mvn -B verify
docker compose up --build
```

The API is available at `http://localhost:8080/tasks`.

## CI/CD (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

1. Checkout repository  
2. Set up JDK 21 (Eclipse Temurin) with Maven cache  
3. **`mvn -B verify`** — compile, test, package `target/application.jar`  
4. Build Docker image tagged with the commit SHA  
5. **Deploy** — optional placeholder step (`if: false`); enable and wire to your AWS account when ready  

Typical next steps for deploy: [AWS CLI](https://aws.amazon.com/cli/) + [EB CLI](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html), OIDC to AWS from GitHub Actions, or a container registry + Beanstalk Docker platform.

## Deploy to AWS Elastic Beanstalk

These steps assume the **Java SE** platform (runnable JAR) or equivalent; adjust if you use the **Docker** platform.

### 1. Prerequisites

- AWS account, IAM user or role with Elastic Beanstalk and related permissions  
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)  
- [EB CLI](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) optional but convenient  

### 2. Build the application

```bash
mvn -B verify
```

Artifact: `target/application.jar` (rename or symlink to `application.jar` in your bundle if your process expects that exact name; this repo’s `Procfile` uses `application.jar`).

### 3. Create the Elastic Beanstalk application (first time)

```bash
eb init -p "corretto-21" task-management-api --region us-east-1
```

Pick a region and platform version that matches your org (Corretto 21 aligns with Java 21).

### 4. Create environment and database

- In the [Elastic Beanstalk console](https://console.aws.amazon.com/elasticbeanstalk/), create an environment.  
- Add an **RDS PostgreSQL** instance from the EB console (or use an existing RDS) and note endpoint, database name, user, and password.  

### 5. Configure environment properties

In the environment **Configuration → Software → Environment properties**, set for example:

| Property | Example |
|----------|---------|
| `SPRING_PROFILES_ACTIVE` | `production` |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://your-rds-endpoint:5432/ebdb` |
| `SPRING_DATASOURCE_USERNAME` | *(RDS user)* |
| `SPRING_DATASOURCE_PASSWORD` | *(RDS password)* |
| `PORT` | `8080` |

Elastic Beanstalk sets `PORT` for the reverse proxy; this app reads `server.port=${PORT:8080}` so it listens on the port EB expects.

### 6. Include `Procfile` (optional but useful)

This repository includes:

```
web: java -jar application.jar
```

Package your deploy bundle so `application.jar` and `Procfile` sit at the **root** of the uploaded zip (see AWS docs for Java platform bundle layout).

### 7. Deploy

Using EB CLI from the project root after `mvn package`:

```bash
cp target/application.jar ./application.jar
eb create task-management-prod
# later updates:
eb deploy
```

Or upload a **Source bundle** (zip with `application.jar` + `Procfile`) via the console.

### 8. Verify

Open the environment URL and call `GET /tasks`. Use HTTPS in production and restrict security groups so only the load balancer reaches the app tier.

---

## Infrastructure as code (Terraform + CloudFormation)

AWS resources are declared in [`terraform/cloudformation/task-management.yaml`](terraform/cloudformation/task-management.yaml) and deployed as **one CloudFormation stack** (Terraform wraps `aws_cloudformation_stack`), so you can inspect **Events**, **Resources**, and **Outputs** in the CloudFormation console. Follow [`terraform/README.md`](terraform/README.md) for apply order (stack first, then [`scripts/upload-eb-bundle.sh`](scripts/upload-eb-bundle.sh), then enable the EB environment) and free-tier cautions.

After apply, configure GitHub using outputs from Terraform and run the deploy workflow manually: [`.github/workflows/deploy-aws.yml`](.github/workflows/deploy-aws.yml) (**Actions → Run workflow** only).

---

## License

Showcase / portfolio use — add a license if you redistribute.
