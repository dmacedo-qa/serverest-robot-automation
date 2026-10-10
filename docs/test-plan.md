# Test Plan: ServeRest API

| | |
|---|---|
| **System under test** | ServeRest 3.2.2, an open-source REST API that simulates an online store |
| **API reference** | [Swagger UI](https://serverest.dev/) · [swagger.json](https://serverest.dev/swagger.json?lang=pt-BR) (OpenAPI 3.0.0, version 3.2.2) |
| **Runtime** | Docker image `paulogoncalvesbh/serverest:3.2.2`, pinned by digest |
| **Approach** | Automated API regression with Robot Framework + RequestsLibrary |
| **Status** | Draft v0.2 (switched from ParaBank to ServeRest on 2026-10-10) |

## 1. Objective

Provide a fast, reliable regression suite for the ServeRest API. It should verify the documented
business rules (authentication, roles, validation, cart and stock lifecycle), detect contract drift
between the Swagger and real responses, and surface security weaknesses. The suite runs unattended
in CI against a disposable local instance.

## 2. Scope

**In scope**

| Area | Endpoints |
|---|---|
| Authentication | `POST /login` |
| Users | `GET/POST /usuarios`, `GET/PUT/DELETE /usuarios/{_id}` |
| Products | `GET/POST /produtos`, `GET/PUT/DELETE /produtos/{_id}` (admin only for writes) |
| Carts | `GET/POST /carrinhos`, `GET /carrinhos/{_id}`, `DELETE /carrinhos/concluir-compra`, `DELETE /carrinhos/cancelar-compra` |
| Cross-cutting | Role-based access (admin vs customer), token expiry, response contract, security observations |

**Out of scope**

- The ServeRest web front end (`front.serverest.dev`, in beta). This project is API only.
- Performance and load testing. ServeRest has its own load-testing guidance.
- Penetration testing. Security findings are limited to what is observable through normal API use.
- The public instance at `serverest.dev`, except for reading the Swagger

## 3. Test approach

- **Layered design.** Test suites contain only readable business steps. Endpoint paths, payload
  shapes, and RequestsLibrary calls live in the API keyword layer. See `docs/architecture.md` (Phase 2).
- **Verify state, not only status codes.** A `201` is followed by a `GET` that proves the record
  exists with the sent values. Cart actions are verified by reading product stock before and after.
- **Every test owns its data.** No test relies on ServeRest's seed records (`fulano@qa.com` and the
  two default products) or on data left by another test. See section 6.
- **Expected results come from reasonable API rules, not from current behavior.** Where ServeRest
  behaves in a way that would be a defect in a production API (for example, returning passwords), the
  test asserts the correct rule and gets the `known-defect` tag. It stays visible in reports
  without blocking the pipeline (`--skiponfailure known-defect`).
- **Error messages are asserted exactly.** ServeRest returns field-level messages in Portuguese
  (for example `"email deve ser um email válido"`). They are part of the contract and are kept in
  one data file, not hard-coded across tests.

## 4. Test environments

| Environment | URL | Use | Data reset |
|---|---|---|---|
| `dev` | `http://localhost:3000` (Docker or `npx serverest@3.2.2`) | Local development | Restart the container |
| `ci` | `http://localhost:3000` (Docker service in GitHub Actions) | Pull requests and nightly runs | New container per job |
| `ci` short token | `http://localhost:3001` (`--timeout 5`) | Token-expiry test only (AUTH-04) | New container per job |
| `public` | `https://serverest.dev` | Reading the Swagger only | Not ours to reset |

Tests never run against `serverest.dev`. Its database is shared by everyone who studies with it, so
results would be unreliable and our test data would pollute other people's work.

## 5. Tags

| Tag | Meaning |
|---|---|
| `smoke` | Fast, critical-path checks. Runs on every PR (target under 1 minute). |
| `regression` | Full suite. Runs nightly and on demand. |
| `auth` / `users` / `products` / `carts` | Functional area |
| `negative` | Invalid input or error path |
| `e2e` | Multi-endpoint purchase journey |
| `security` | Access control and data-exposure checks |
| `contract` | Response shape matches the documented schema |
| `known-defect` | Asserts a correct rule that ServeRest currently violates. Doesn't block the pipeline. |
| `AUTH-01`, `CRT-03`, … | Test case ID, for traceability from report to plan |

Run examples: `robot --include smoke tests/`, `robot --include cartsANDnegative tests/`.

## 6. Test data strategy

### 6.1 Principles

1. **Synthetic only.** Nothing comes from real people or any employer.
2. **Generated at runtime.** Unique values (emails, product names) are created per test, so reruns
   and parallel workers never collide.
3. **Isolated.** Every test that changes state creates its own users and products.
4. **Cleaned up.** Unlike many demo apps, ServeRest supports deletion, so each test removes what it
   created (section 6.5).
5. **Reproducible.** The generator is seeded. The seed is logged in the report, and you can replay a
   run's data with `--variable DATA_SEED:<seed>`.
6. **Static where meaning matters.** Boundary and invalid values are fixed, named data sets in
   YAML, not random values.

### 6.2 Facts about ServeRest that shape the strategy

Verified by running ServeRest 3.2.2 locally on 2026-10-10. Several of these are **not** in the Swagger.

| Fact | Consequence for test data |
|---|---|
| The database starts with seed data: 1 admin user (`fulano@qa.com`), 2 products, 1 cart. | Tests never use or assert on seed records. Filters and counts are always scoped to the test's own data. |
| Email must be unique, product name must be unique. Both checks are **case-sensitive**. | Generated emails and product names include a unique suffix. |
| Email validation only accepts real top-level domains: `@example.test` and `@test.invalid` are rejected, `@example.com` is accepted. | Generated emails use `example.com`, which is reserved for examples and never belongs to a real person. |
| `administrador` must be the **string** `"true"` or `"false"`. A JSON boolean is rejected. | Builders emit strings. Booleans are a negative case. |
| `preco` must be a positive integer. `quantidade` must be an integer ≥ 0. Unknown fields are rejected. | Generated prices are integers ≥ 1. Stock is chosen per test. |
| Each user can have **only one cart**. A cart decreases product stock immediately. | Each cart test needs its own customer **and** its own products with known stock. |
| You can't delete a user who has a cart, or a product that's in a cart. | Cleanup must cancel carts first, then delete products and users. |
| `concluir-compra` keeps stock reduced. `cancelar-compra` restores it. | Stock checks before and after are deterministic only on test-owned products. |
| Tokens last 600 s by default (`--timeout` changes this). A deleted user's token stops working. | Tokens are cached per user per suite. Expiry is tested on a separate 5 s instance. |
| IDs are exactly 16 alphanumeric characters. Any other length returns a validation error, not "not found". | Two negative ID sets: well-formed but non-existent, and malformed. |
| `PUT` on a non-existent ID **creates** a record (upsert). | Update tests use IDs they created. Upsert has its own test. |

### 6.3 Personas

| Persona | `administrador` | Used for |
|---|---|---|
| **Admin** | `"true"` | Creating, updating, and deleting products |
| **Customer** | `"false"` | Carts. Also proves that product writes are forbidden (`403`). |
| **Anonymous** | No token | Proves that protected routes return `401` |
| **Ghost** | Token of a user deleted afterwards | Proves that tokens are invalidated (`401`) |

### 6.4 Data scopes

| Scope | Created by | Example | Rule |
|---|---|---|---|
| **Suite (read-only)** | Suite setup | Admin user and token for a products suite | Tests may use it but never change it |
| **Test (mutable)** | Test setup | Customer + 2 products with stock 10 for a cart test | Never shared. Deleted in teardown. |
| **Static** | Committed YAML in `data/` | Invalid payloads with their expected messages | Versioned and reviewed like code |

### 6.5 Cleanup

- Every create keyword registers what it created (type and `_id`) in a per-test registry.
- Test teardown cleans up in dependency order: **cancel carts → delete products → delete users**.
- Cleanup is best-effort. A cleanup failure is logged as a warning and never hides the test's real
  result.
- The disposable container is the safety net. CI starts a fresh one for every job.

### 6.6 Generation rules

| Field | Rule | Example |
|---|---|---|
| `email` | `qa.` + run ID + worker ID + random suffix, on the reserved `example.com` domain (RFC 2606) | `qa.k7f2.w3.x9p4@example.com` |
| `nome` (user) | Faker `pt_BR` name. Includes accents and apostrophes on purpose. | `João D'Ávila` |
| `password` | Random and strong. Never logged in plain text. | — |
| `nome` (product) | Faker product-style words + unique suffix | `Ergonomic Mouse k7f2x9` |
| `preco` | Integer, 1–5000, chosen so cart totals are easy to verify | `120` |
| `quantidade` | Explicit per test (default 10), so stock arithmetic is visible in the test | `10` |

Data is built with **builder keywords that use defaults and allow overrides**, so a test states only
what it cares about:

```robotframework
${user}=       Generate User                              # customer, all defaults
${admin}=      Generate User    administrador=true
${product}=    Generate Product    preco=100    quantidade=5
```

### 6.7 Traceability and privacy in reports

- Each test logs the IDs it created, so you can investigate a failure directly through the API.
- Passwords and the `Authorization` header are masked in `log.html`.
- Generated data files go in `data/generated/`, which is gitignored.

## 7. Test cases

### Authentication

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| AUTH-01 | Valid login returns `200` and a `Bearer` token | High | `auth` `smoke` |
| AUTH-02 | Wrong password or unknown email returns `401` with `"Email e/ou senha inválidos"` | High | `auth` `negative` |
| AUTH-03 | Missing or blank email/password returns `400` with field messages (data-driven) | Medium | `auth` `negative` |
| AUTH-04 | Expired token returns `401` (short-token instance) | Medium | `auth` `negative` |
| AUTH-05 | Missing, malformed, unprefixed, or deleted-user token returns `401` on a protected route (data-driven) | High | `auth` `negative` `security` |

### Users

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| USR-01 | Create a customer and an admin, then `GET` by ID returns the sent data | High | `users` `smoke` |
| USR-02 | Duplicate email returns `400` | High | `users` `negative` |
| USR-03 | Field validation: missing, blank, invalid email, non-string `administrador`, unknown field (data-driven) | Medium | `users` `negative` |
| USR-04 | List with filters (`email`, `nome`, `administrador`) returns only matching users | Medium | `users` |
| USR-05 | `PUT` updates an existing user. `PUT` on an unknown ID creates one (documented upsert). | Medium | `users` |
| USR-06 | Delete a user without a cart returns `200`. Deleting a user with a cart returns `400` with the cart ID. | High | `users` `negative` |
| USR-07 | Non-existent ID returns `"Usuário não encontrado"`. Malformed ID returns the 16-character rule. | Medium | `users` `negative` |

### Products

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| PRD-01 | Admin creates a product, then `GET` by ID returns the sent data | High | `products` `smoke` |
| PRD-02 | Customer gets `403`, anonymous gets `401` on create, update, and delete | High | `products` `negative` `security` |
| PRD-03 | Duplicate product name returns `400` | Medium | `products` `negative` |
| PRD-04 | Field validation: `preco` 0, negative, decimal; `quantidade` negative; missing fields (data-driven). `quantidade` 0 is accepted. | Medium | `products` `negative` |
| PRD-05 | Update and delete a product. Deleting a product that is in a cart returns `400`. | High | `products` `negative` |
| PRD-06 | List with filters (`nome`, `preco`, `quantidade`) returns only matching products | Low | `products` |

### Carts

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| CRT-01 | Create a cart: `201`, correct `precoTotal` and `quantidadeTotal`, product stock decreased | High | `carts` `smoke` |
| CRT-02 | A second cart for the same user returns `400` | High | `carts` `negative` |
| CRT-03 | Invalid cart: duplicate product, unknown product, quantity above stock, quantity 0, empty list (data-driven). Stock unchanged. | High | `carts` `negative` |
| CRT-04 | Conclude purchase: cart removed, stock stays reduced | High | `carts` |
| CRT-05 | Cancel purchase: cart removed, stock restored to the original value | High | `carts` |
| CRT-06 | Conclude or cancel without a cart returns `200` with `"Não foi encontrado carrinho para esse usuário"` | Low | `carts` `negative` |

### End-to-end

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| E2E-01 | Admin creates products → customer registers and logs in → creates cart → totals and stock verified → concludes purchase → stock final | High | `e2e` `smoke` |
| E2E-02 | Same journey, but the customer cancels. Stock fully restored and the user can then be deleted. | Medium | `e2e` |

### Contract

| ID | Scenario | Priority | Tags |
|---|---|---|---|
| CON-01 | Success and error responses match the Swagger schemas (required fields, types) | Medium | `contract` |

### Security and data-quality observations

These assert what a production API should do. Each was observed on 3.2.2 and is expected to fail
today, so they carry `known-defect`.

| ID | Expected rule | Observed on 3.2.2 | Tags |
|---|---|---|---|
| SEC-01 | `GET /usuarios` must not return passwords | Plain-text `password` in every user | `security` `known-defect` |
| SEC-02 | The JWT payload must not contain the password | Payload includes `email` **and** `password` (base64, not encrypted) | `security` `known-defect` |
| SEC-03 | Deleting or updating a user must require authentication | `DELETE` and `PUT /usuarios/{_id}` work with no token | `security` `known-defect` |
| DQ-01 | Email uniqueness must be case-insensitive | `ADM@x` and `adm@x` are both accepted | `users` `known-defect` |
| DQ-02 | Product name uniqueness must be case-insensitive | `Widget A` and `widget a` are both accepted | `products` `known-defect` |
| DQ-03 | `preco` sent as a string must be rejected | `"10"` is accepted | `products` `known-defect` |
| DQ-04 | Response body matches the documented field name | Product-in-cart error returns `idCarrinhos`, while the Swagger documents `idCarrinho` | `contract` `known-defect` |

## 8. Entry criteria

- The ServeRest container is healthy and its image digest matches `docker-compose.yml`
- Dependencies installed from the pinned `requirements.txt`
- The generator seed is logged at the start of the run
- The test cases in this plan are reviewed and tagged

## 9. Exit criteria

- **PR gate:** 100 % of `smoke` tests pass
- **Nightly:** 100 % of High-priority tests pass. Any other failure has a linked issue or the `known-defect` tag.
- No flaky test stays in the gating set. A test that fails and then passes on rerun without a code
  change is quarantined and investigated.
- No test data is left behind after a full run, apart from ServeRest's own seed records (checked by
  a final suite teardown)
- `report.html` and `log.html` are published as CI artifacts

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The Swagger is incomplete (validation rules and some field names are undocumented) | Weak or wrong assertions | Rules confirmed by observation (section 6.2). Mismatches tracked as `contract` findings. |
| A new ServeRest release changes messages or rules | Many tests fail at once | Pinned image version and digest. Messages centralized in one data file. Upgrades done in their own PR. |
| Data collisions in parallel runs | Flaky failures | Unique emails and names with worker ID, per-test data, no shared mutable records |
| Stock assertions affected by other tests | Wrong totals | Stock checked only on products created by the same test |
| Token expiry during long runs (600 s) | Random `401`s | Tokens cached per suite and refreshed when close to expiry |
| Cleanup fails and leaves data | Later collisions, failed "no leftovers" check | Ordered, best-effort teardown. Fresh container per CI job. |
| amd64-only image on ARM machines | Slower local start | Runs under emulation. `npx serverest@3.2.2` documented as an alternative. |
| Error messages are in Portuguese while the code is in English | Readability for non-Portuguese readers | Messages kept verbatim (they are the contract), with English names for the data-set keys |

## 11. Open points

- [x] Confirm the Docker health check works inside the image (image runs Node 22; healthy in ~7 s)
- [x] Confirm the short-token instance expires tokens (valid at 0 s, `401` at 6 s)
- [ ] Decide whether CON-01 uses a JSON-schema library or schemas derived from the Swagger
- [ ] Measure how long a full run takes sequentially vs with pabot
