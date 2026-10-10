# ServeRest API Automation with Robot Framework

<!-- CI badge added in Phase 6 -->

REST API test automation for [ServeRest](https://serverest.dev/), an open-source API that simulates
an online store, built with **Robot Framework** and **RequestsLibrary**.

> Status: work in progress. See [the test plan](docs/test-plan.md).

## Highlights

- Layered design: test suites → business flows → endpoint keywords → libraries
- Dynamic, synthetic test data. Every test creates the users and products it needs and removes them afterwards.
- Covers authentication, role-based access (admin vs customer), validation rules, and stock consistency across the cart lifecycle
- ServeRest runs locally in Docker and is pinned by version and digest, so tests never touch the shared public server
- Parallel execution with pabot, and CI on GitHub Actions

## Tech stack

| Purpose | Tool |
|---|---|
| Test framework | Robot Framework 7.5 |
| HTTP | RequestsLibrary 0.9.7 |
| Test data | Faker |
| Parallel runs | pabot |
| System under test | `paulogoncalvesbh/serverest:3.2.2` Docker image |

## Quick start

Prerequisites: Python 3.13 and Docker.

```bash
# 1. Start ServeRest (http://localhost:3000)
docker compose up -d

# 2. Install dependencies
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Run the smoke tests
robot --argumentfile config/robot.args --include smoke tests/
```

On macOS, any Docker runtime works. A lightweight, CLI-only option is Colima:

```bash
brew install colima docker docker-compose
colima start --vm-type vz --vz-rosetta --cpu 2 --memory 2   # Rosetta runs the amd64 image on Apple Silicon
```

No Docker? `npx serverest@3.2.2 --nodoc` starts the same version on port 3000 (needs Node.js).

## Project structure

```
config/          environment settings (dev, ci) and shared robot options
data/            expected API messages and static negative data sets
libraries/       custom Python: config loader, data factory, cleanup registry
resources/
  api/           one keyword per endpoint call (no assertions)
  flows/         business steps built from endpoint keywords
  verifications/ assertion keywords
  common/        session setup and teardown
tests/           suites grouped by area: auth, users, products, carts, e2e, security, contract
```

How the layers fit together, and the rules that keep them clean: [docs/architecture.md](docs/architecture.md).

## Test documentation

- [Test plan](docs/test-plan.md)
- [Architecture](docs/architecture.md)
- ServeRest API: [Swagger UI](https://serverest.dev/) · [swagger.json](https://serverest.dev/swagger.json?lang=pt-BR)

## Disclaimer

This is a personal portfolio project. All test data is synthetic and generated at runtime.
ServeRest is an open-source project by Paulo Gonçalves and is not affiliated with this project.
