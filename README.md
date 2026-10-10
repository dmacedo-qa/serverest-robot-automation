# ServeRest API Test Automation

<!-- CI badge added with the pipeline -->

API test automation for [ServeRest](https://github.com/ServeRest/ServeRest), an open-source REST API
that simulates an online store. Built with **Robot Framework** and **RequestsLibrary**.

📋 **[Read the test plan](docs/test-plan.md)**: 127 test cases (positive, negative, edge, contract,
security, end-to-end), the test design behind them, and the defects found.

## What this project shows

- **A test plan based on evidence.** Scenarios come from the Swagger, the ServeRest source code, and
  probing the running API. Every expected result was confirmed against ServeRest 3.2.2.
- **Real defects found**, including two critical ones:
  - **Overselling:** a cart with the same product in non-adjacent positions bypasses the duplicate
    check. A cart holding 8 units was accepted for a product with only 5 in stock.
  - **Password search:** `GET /usuarios?password=...` finds users by partial password match, with no
    authentication.
- **A layered framework**: tests → business flows → endpoint keywords → libraries.
  See [architecture](docs/architecture.md).
- **Test data that cleans up after itself.** Every test creates its own users and products and
  deletes them, even when the test fails. Data is unique per parallel worker and replayable by seed.
- **No secrets in reports.** Passwords and tokens are masked in `log.html`.
- **Reproducible runs.** ServeRest, Python, and every dependency are pinned.

## Run the tests

You only need **Docker**:

```bash
git clone https://github.com/<your-user>/serverest-robot-automation.git
cd serverest-robot-automation
docker compose run --rm tests
```

This starts ServeRest, waits until it's healthy, runs the suite, and writes the reports to
`results/`. Open **`results/report.html`** for the summary and **`results/log.html`** for the
details of each request. When you're done, run `docker compose down`.

Run a subset by passing Robot Framework options and a path:

```bash
docker compose run --rm tests --include smoke tests          # smoke tests only
docker compose run --rm tests --include products tests       # one area
```

<details>
<summary>Run without Docker for the tests (Python 3.13)</summary>

ServeRest still needs to be running, either with `docker compose up -d serverest` or with
`npx serverest@3.2.2 --nodoc` (Node.js).

```bash
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

robot --argumentfile config/robot.args tests/                         # everything
robot --argumentfile config/robot.args --include smoke tests/         # smoke only
pabot --processes 4 --argumentfile config/robot.args tests/           # in parallel
robot --argumentfile config/robot.args --variable DATA_SEED:81714172 tests/   # replay a run's data
```

The virtual environment must be active for pabot, because it starts its workers with the
`python` on the `PATH`.
</details>

## Project structure

```
docs/            test plan and architecture
tests/           test suites, grouped by area (auth, users, products, …)
resources/
  api/           one keyword per endpoint call (no assertions)
  flows/         business steps built from endpoint keywords
  verifications/ assertion keywords
  common/        HTTP entry point, setup and teardown
libraries/       Python: config loader, test data factory, cleanup registry, HTTP helpers
data/            expected API messages
config/          environment settings and shared Robot Framework options
```

## Status

| | |
|---|---|
| Test plan | ✅ Complete: 127 cases |
| Framework | ✅ Data factory, cleanup, secret masking, parallel runs, Docker runner |
| Automated | 3 of 127 cases (AUTH-01, USR-01, PRD-01). The rest are being added area by area. |
| CI | Next: GitHub Actions with smoke tests on every PR and the full suite nightly |

## Tech stack

Robot Framework 7.5 · RequestsLibrary 0.9.7 · pabot · Faker · Docker ·
ServeRest 3.2.2 (`paulogoncalvesbh/serverest`)

## Disclaimer

Personal portfolio project. All test data is synthetic and generated at runtime. ServeRest is an
open-source project by Paulo Gonçalves and is not affiliated with this project.
