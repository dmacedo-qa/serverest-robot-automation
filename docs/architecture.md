# Architecture

This document explains how the framework is organized and the rules that keep it maintainable.
It's the API-testing equivalent of the Page Object pattern. Endpoints play the role of pages.

## 1. Layers

```mermaid
flowchart TD
    T["<b>Test suites</b><br/>tests/**/*.robot<br/><i>Readable scenarios + assertions</i>"]
    F["<b>Flows</b><br/>resources/flows/*.resource<br/><i>Business steps: 'Customer Buys Products'</i>"]
    V["<b>Verifications</b><br/>resources/verifications/*.resource<br/><i>'Stock Should Be', 'Response Should Be Error'</i>"]
    A["<b>Endpoint keywords</b><br/>resources/api/*.resource<br/><i>One HTTP call each: 'POST Product'</i>"]
    L["<b>Libraries</b><br/>RequestsLibrary · libraries/*.py<br/><i>HTTP, data factory, config, cleanup, tokens</i>"]

    T --> F
    T --> V
    T -.->|negative tests only| A
    F --> A
    V --> A
    A --> L
    F --> L
```

| Layer | Knows about | Example | Asserts? |
|---|---|---|---|
| **Test suite** | Business language only | `Customer Creates Cart With    ${products}` | Yes: the outcome of the scenario |
| **Flow** | Which endpoints make up a business step | `Create Customer With Token` = generate user → `POST User` → `POST Login` | Only that setup steps succeeded (fail fast) |
| **Verification** | How to prove a fact | `Product Stock Should Be    ${id}    8` | Yes, that is its only job |
| **Endpoint keyword** | Path, method, payload shape, headers | `POST Product    ${payload}    ${token}` | **No.** Returns the response. |
| **Library** | HTTP, data generation, config, cleanup | `Generate Product`, `Register For Cleanup` | No |

### Why endpoint keywords never assert

The same call is used by positive and negative tests. `POST Product` must be able to return a
`403` so that PRD-02 can check it. If the endpoint keyword checked for `201`, every negative test
would need a second copy of the call. So:

- Endpoint keywords send the request with `expected_status=anything` and return the response.
- Flow keywords check for success, because they are used for setup, and a broken setup should
  fail immediately with a clear message, not three steps later.
- Tests and verification keywords make the assertions that matter for the scenario.

## 2. Rules

1. **Paths and payload shapes live only in `resources/api/`.** A test never contains `/produtos`
   or builds a JSON body by hand.
2. **Tests never call RequestsLibrary directly.** No `POST On Session` in a `.robot` file.
3. **Endpoint keywords do one HTTP call. Flows combine them.**
4. **Assertions live in tests or in `resources/verifications/`.**
5. **Negative tests may call endpoint keywords directly**, because the raw response *is* what they
   test. They still use generated data and verification keywords.
6. **No hard-coded test data in tests.** Values come from the data factory (dynamic) or from
   `data/*.yaml` (static negative sets and expected messages).
7. **Every created record is registered for cleanup** by the flow that created it.

## 3. Example across the layers

**Endpoint keyword** (`resources/api/products.resource`): one call, no assertion.

```robotframework
*** Variables ***
${PRODUCTS_PATH}    /produtos

*** Keywords ***
POST Product
    [Documentation]    Sends POST /produtos and returns the response, whatever its status.
    [Arguments]    ${payload}    ${token}=${NONE}
    ${headers}=    Auth Header    ${token}
    ${response}=    POST On Session    serverest    ${PRODUCTS_PATH}
    ...    json=${payload}    headers=${headers}    expected_status=anything
    RETURN    ${response}
```

**Flow** (`resources/flows/catalog.resource`): a business step that must succeed.

```robotframework
*** Keywords ***
Admin Creates Product
    [Documentation]    Creates a product as admin and registers it for cleanup.
    [Arguments]    ${admin_token}    &{overrides}
    ${product}=    Generate Product    &{overrides}
    ${response}=    POST Product    ${product}    ${admin_token}
    Status Should Be    201    ${response}
    Set To Dictionary    ${product}    _id=${response.json()}[_id]
    Register For Cleanup    product    ${product}[_id]
    RETURN    ${product}
```

**Test** (`tests/carts/create_cart.robot`): reads like the scenario in the test plan.

```robotframework
*** Test Cases ***
CRT-01 Creating A Cart Reserves Stock And Calculates Totals
    [Tags]    CRT-01    carts    smoke    regression
    ${admin}=       Create Admin With Token
    ${customer}=    Create Customer With Token
    ${mouse}=       Admin Creates Product    ${admin}[token]    preco=100    quantidade=10
    ${pad}=         Admin Creates Product    ${admin}[token]    preco=30     quantidade=5

    ${items}=    Cart Items    ${mouse}    2    ${pad}    1
    ${cart}=     Customer Creates Cart    ${customer}[token]    ${items}

    Cart Totals Should Be       ${cart}[_id]    preco_total=230    quantidade_total=3
    Product Stock Should Be     ${mouse}[_id]    8
    Product Stock Should Be     ${pad}[_id]      4
```

## 4. Cross-cutting components

| Component | Where | Responsibility |
|---|---|---|
| **Config loader** | `libraries/config_loader.py` | Reads `config/<env>.yaml` and exposes values such as `${BASE_URL}` as Robot variables. Environment variables override YAML. The environment is chosen with `ENV` (default `dev`). |
| **Data factory** | `libraries/data_factory.py` | Builds users and products with Faker, using defaults plus overrides. Unique values use the run ID and the pabot worker ID. Seeded and replayable with `DATA_SEED`. |
| **Cleanup registry** | `libraries/cleanup_registry.py` | Records what each test created. Teardown deletes in dependency order: carts → products → users. Best-effort: failures become warnings. |
| **Token cache** | inside the auth flow | One login per persona per suite, refreshed before the 600 s expiry |
| **Messages** | `data/messages.yaml` | Every expected ServeRest message, verbatim, under an English key, for example `users.email_taken: "Este email já está sendo usado"` |
| **Negative data sets** | `data/negative/*.yaml` | Invalid payloads and their expected field errors. They drive data-driven tests (`[Template]`). |
| **Session setup** | `resources/common/setup.resource` | Creates the `serverest` HTTP session, logs the run ID and seed, and runs the cleanup teardown |

### Sensitive values in logs

Passwords and the `Authorization` header must never appear in `log.html`. RequestsLibrary logs
every request and response at INFO level, so:

- The login and user-creation endpoint keywords lower Robot's log level (`Set Log Level    WARN`)
  around the HTTP call and restore it afterwards.
- The data factory returns passwords that are logged as `***`.
- Tokens are kept in variables and never logged in full.

## 5. Configuration

```
config/dev.yaml   → local work (docker compose or npx)
config/ci.yaml    → GitHub Actions
```

Precedence, highest first:

1. Command line: `--variable BASE_URL:http://...`
2. Environment variables or `.env` file
3. `config/<ENV>.yaml`

Run options that are the same for everyone (output folder, log level, tag statistics) live in
`config/robot.args`, so the everyday command stays short:

```bash
robot --argumentfile config/robot.args --include smoke tests/
```

## 6. Parallel execution

Suites run in parallel with pabot (`pabot --processes 4 ...`). The design is parallel-safe because:

- Every test creates its own users and products with globally unique emails and names.
- Unique values include the pabot worker ID (the `${PABOTEXECUTIONPOOLID}` variable that pabot sets;
  it falls back to `0` in a normal `robot` run).
- No test uses ServeRest's seed records.
- Stock is only asserted on products that the same test created.

## 7. Folder structure

```
serverest-robot-automation/
├── config/
│   ├── dev.yaml               # local settings
│   ├── ci.yaml                # CI settings
│   └── robot.args             # shared robot command-line options
├── data/
│   ├── messages.yaml          # expected ServeRest messages (verbatim)
│   ├── negative/              # invalid payload sets for data-driven tests
│   └── generated/             # runtime output, gitignored
├── docs/
│   ├── test-plan.md
│   └── architecture.md
├── libraries/                 # custom Python: config, data factory, cleanup
├── resources/
│   ├── api/                   # endpoint keywords: login, users, products, carts
│   ├── flows/                 # business keywords
│   ├── verifications/         # assertion keywords
│   └── common/                # session setup, teardown, shared helpers
├── tests/
│   ├── auth/
│   ├── users/
│   ├── products/
│   ├── carts/
│   ├── e2e/
│   ├── security/              # SEC-* and DQ-* (known-defect)
│   └── contract/
├── docker-compose.yml
├── requirements.txt
└── pyproject.toml             # Robocop lint and format settings
```

Tests are grouped by **functional area**, not by layer, because the whole suite is API. Tags
(`smoke`, `negative`, `e2e`, …) cut across folders.

## 8. Naming conventions

| Item | Convention | Example |
|---|---|---|
| Test case | `<ID> <Behavior in plain English>` | `USR-02 Duplicate Email Is Rejected` |
| Endpoint keyword | `<METHOD> <Resource>` | `GET Product By Id`, `DELETE User` |
| Flow keyword | Actor + action | `Customer Creates Cart`, `Admin Creates Product` |
| Verification keyword | `… Should …` | `Product Stock Should Be`, `Response Should Have Field Error` |
| Variables | `${UPPER_SNAKE}` for constants and paths, `${lower_snake}` for local values | `${USERS_PATH}`, `${customer}` |
| Files | `snake_case.robot` / `snake_case.resource` | `create_cart.robot`, `products.resource` |
