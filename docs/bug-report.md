# Bug Report: ServeRest 3.2.2

| | |
|---|---|
| Application | [ServeRest](https://github.com/ServeRest/ServeRest) 3.2.2 (tag `v3.2.2`, commit `0a8068f`) |
| Environments | Docker image `paulogoncalvesbh/serverest:3.2.2` (digest in `docker-compose.yml`), and the same tag built from source with Node.js. Both give identical results. |
| Found by | Test design from the Swagger, the source code, and live probing (see the [test plan](test-plan.md)) |
| Evidence | Every bug below has an automated test that fails today. Those tests are tagged `known-defect`, so they show as SKIP in the [published report](https://dmacedo-qa.github.io/serverest-robot-automation/) with the failure message. |
| Date | 2026-10-13 |

ServeRest is a study API, and some of these behaviors may be intentional simplifications. They're
reported against the rules a production online store would need, which is the point of view the
test plan takes.

## Severity scale

| Severity | Meaning |
|---|---|
| Critical | Corrupts money or stock data, or lets someone take actions on accounts they don't own |
| High | Exposes credentials or grants privileges that shouldn't be granted |
| Medium | Breaks a data-integrity rule, or makes the documentation misleading for clients |
| Low | Inconsistent validation with limited impact |

## Summary

| ID | Severity | Title | Test |
|---|---|---|---|
| BUG-01 | Critical | A cart can contain the same product twice; stock goes down for only one line | DQ-07, DQ-08 |
| BUG-02 | Critical | Users can be updated and deleted without authentication | SEC-03 |
| BUG-03 | Critical | Users can be searched by part of their password | SEC-04 |
| BUG-04 | High | User listing returns passwords in plain text | SEC-01 |
| BUG-05 | High | The JWT payload contains the user's password | SEC-02 |
| BUG-06 | High | Anyone can register an admin account | SEC-07 |
| BUG-07 | Medium | Email uniqueness is case-sensitive | DQ-01 |
| BUG-08 | Medium | Product name uniqueness is case-sensitive | DQ-02 |
| BUG-09 | Medium | Names made only of spaces are accepted | DQ-04, DQ-05 |
| BUG-10 | Low | Numbers sent as strings are accepted | DQ-03, DQ-06 |
| BUG-11 | Low | PUT and DELETE on users accept malformed IDs | DQ-09 |
| BUG-12 | Low | PUT on an unknown ID creates the record under a different ID | DQ-10 |
| DOC-01 | Medium | Swagger names the cart field `idCarrinho`; the API returns `idCarrinhos` | DRIFT-01 |
| DOC-02 | Low | Products accept an `imagem` field the Swagger doesn't list | DRIFT-02 |
| DOC-03 | Low | Swagger allows `quantidadeTotal=0`; the API rejects it | DRIFT-03 |
| DOC-04 | Low | Status codes 405, 413, and 415 aren't documented | DRIFT-04 |

Source references below point to files in the ServeRest repository at tag `v3.2.2`.

---

## BUG-01: A cart can contain the same product twice; stock goes down for only one line

**Severity:** Critical · **Component:** `POST /carrinhos` · **Tests:** DQ-07, DQ-08

**Steps**

1. As an admin, create product A with `quantidade: 5` and product B with `quantidade: 5`.
2. As a customer, `POST /carrinhos` with:
   ```json
   { "produtos": [
       { "idProduto": "<A>", "quantidade": 4 },
       { "idProduto": "<B>", "quantidade": 1 },
       { "idProduto": "<A>", "quantidade": 4 } ] }
   ```
3. `GET /produtos/<A>`.

**Expected:** `400 "Não é permitido possuir produto duplicado"`, as it already happens when the two
lines for A are next to each other (`[A, A, B]`).

**Actual:** `201`. The cart holds 8 units of A (`precoTotal` and `quantidadeTotal` count all of
them), but A's stock goes from 5 to 1, a reduction of 4. Concluding the purchase sells 8 units of
a product that had 5.

**Root cause**

- `src/services/carrinhos-service.js:44-48`: `extrairProdutosDuplicados` calls `.sort()` on an
  array of objects. Without a compare function, objects aren't reordered, and the loop only
  compares neighboring items, so duplicates that aren't adjacent are missed.
- `src/services/produtos-service.js:45-56`: `updateQuantidadePorLote` computes every new quantity
  from the same snapshot of the stock, so two lines for one product overwrite each other instead of
  adding up.

**Suggested fix:** detect duplicates with a set of `idProduto` values, and check stock against
the total quantity per product.

**Note:** ServeRest's own suite tests duplicates only with two adjacent lines, which is why this
passed its checks.

---

## BUG-02: Users can be updated and deleted without authentication

**Severity:** Critical · **Component:** `PUT /usuarios/{id}`, `DELETE /usuarios/{id}` · **Test:** SEC-03

**Steps:** without an `Authorization` header, send `PUT /usuarios/<id of another user>` with a
valid user body, or `DELETE /usuarios/<id of another user>`.

**Expected:** `401`, and only the account owner (or an admin) can change or remove an account.

**Actual:** `200`. Any caller can change any account, including its password and its
`administrador` flag, or delete it. SEC-03 checks the DELETE; the PUT side is exercised by every
user update in the suite (USR-07, TOK-08 to TOK-10), which runs without a token.

**Root cause:** `src/routes/usuarios-route.js:13-14` registers both routes without the
authentication middleware that protects products and carts.

**Suggested fix:** require a token on both routes, and allow the change only for the account owner
or an admin.

---

## BUG-03: Users can be searched by part of their password

**Severity:** Critical · **Component:** `GET /usuarios` · **Test:** SEC-04

**Steps:** create a user whose password contains `Searchable`, then `GET /usuarios?password=searchable`
without a token.

**Expected:** `400` (`password` isn't a valid filter), or the parameter is ignored.

**Actual:** `200`, and the user is in the result. The match is partial and ignores case.

**Root cause**

- `src/models/usuarios-model.js:10` accepts `password` as a query filter.
- `src/utils/alterarValoresParaRegex.js:3,11` turns `password` (like `nome`) into a
  case-insensitive regular expression.

**Suggested fix:** remove `password` from the accepted filters.

---

## BUG-04: User listing returns passwords in plain text

**Severity:** High · **Component:** `GET /usuarios`, `GET /usuarios/{id}` · **Test:** SEC-01

**Expected:** user records never include the password.

**Actual:** every record includes `password` with its plain-text value. Combined with BUG-03,
anyone can read any user's password.

**Root cause:** `src/services/usuarios-service.js:14-21` (`getAll`, `getOne`) return the stored
documents as they are, and passwords are stored without hashing.

**Suggested fix:** store a hash, and leave `password` out of every response.

---

## BUG-05: The JWT payload contains the user's password

**Severity:** High · **Component:** `POST /login` · **Test:** SEC-02

**Expected:** the token identifies the user without carrying secrets. A JWT payload is only
base64-encoded, so anyone who sees the token can read it.

**Actual:** the payload contains `email` and `password`.

**Root cause:** `src/controllers/login-controller.js:14` passes the whole request body to
`createToken`, which signs it as the payload (`src/services/auth-service.js:10`).

**Suggested fix:** sign only a user identifier, and look up the rest on the server.

---

## BUG-06: Anyone can register an admin account

**Severity:** High · **Component:** `POST /usuarios` · **Test:** SEC-07

**Steps:** without a token, `POST /usuarios` with `"administrador": "true"`, then log in.

**Expected:** self-registration creates customers only. Promoting a user to admin requires an
existing admin.

**Actual:** `201`, and the new account can create, change, and delete products.

**Root cause:** `src/routes/usuarios-route.js:12` is public, and `src/models/usuarios-model.js:26`
accepts `administrador` from the client.

**Note:** USR-01 documents the current behavior (an admin can be created through `POST /usuarios`)
and will change together with this fix.

---

## BUG-07: Email uniqueness is case-sensitive

**Severity:** Medium · **Component:** `POST /usuarios`, `PUT /usuarios/{id}` · **Test:** DQ-01

**Steps:** create a user with `ana@example.com`, then another with `ANA@example.com`.

**Expected:** `400 "Este email já está sendo usado"`.

**Actual:** `201`. Two accounts exist for what is, in practice, the same address. Login is also
case-sensitive (AUTH-08), so the user has to remember which spelling they registered.

**Root cause:** `src/controllers/usuarios-controller.js:22` compares emails exactly.

**Suggested fix:** normalize emails to lower case before storing and comparing.

---

## BUG-08: Product name uniqueness is case-sensitive

**Severity:** Medium · **Component:** `POST /produtos`, `PUT /produtos/{id}` · **Test:** DQ-02

**Steps:** create `Mouse X`, then `MOUSE X`.

**Expected:** `400 "Já existe produto com esse nome"`.

**Actual:** `201`, so the catalog shows two products with the same name.

**Root cause:** `src/controllers/produtos-controller.js:25` compares the trimmed name exactly.

---

## BUG-09: Names made only of spaces are accepted

**Severity:** Medium · **Component:** `POST /usuarios`, `POST /produtos` · **Tests:** DQ-04, DQ-05

**Steps:** create a user or a product with `"nome": "   "`.

**Expected:** `400 "nome não pode ficar em branco"`, as for an empty string.

**Actual:** `201`. A product is stored with an empty name (`""`), because the name is trimmed
after validation.

**Root cause:** `src/models/usuarios-model.js:23` and `src/models/produtos-model.js:24` use
`Joi.string()` without `.trim()`, and `src/services/produtos-service.js:152` trims afterwards.

**Suggested fix:** validate with `Joi.string().trim()`.

---

## BUG-10: Numbers sent as strings are accepted

**Severity:** Low · **Component:** `POST /produtos` (`preco`), `POST /carrinhos` (`quantidade`) · **Tests:** DQ-03, DQ-06

**Steps:** create a product with `"preco": "10"` or `"preco": "1e2"`, or a cart line with
`"quantidade": "2"`.

**Expected:** `400`. The Swagger declares these fields as integers, and a client sending strings
has a bug the API should report.

**Actual:** `201`.

**Root cause:** Joi converts numeric strings by default, and the product service then applies its
own conversion (`src/services/produtos-service.js:153`).

**Suggested fix:** validate numbers with `convert: false`.

---

## BUG-11: PUT and DELETE on users accept malformed IDs

**Severity:** Low · **Component:** `PUT /usuarios/{id}`, `DELETE /usuarios/{id}` · **Test:** DQ-09

**Steps:** `GET /usuarios/abc`, then `PUT /usuarios/abc` with a valid body.

**Expected:** both return `400 "id deve ter exatamente 16 caracteres alfanuméricos"`.

**Actual:** GET returns that 400, but PUT returns `201` and creates a user, and DELETE returns `200`.

**Root cause:** `src/models/usuarios-model.js:30-32` validates the ID on PUT and DELETE only as
"any string", unlike GET and the product routes.

---

## BUG-12: PUT on an unknown ID creates the record under a different ID

**Severity:** Low · **Component:** `PUT /usuarios/{id}`, `PUT /produtos/{id}` · **Test:** DQ-10

**Steps:** `PUT /usuarios/bbbbbbbbbbbbbbbb` (an ID that doesn't exist) with a valid body.

**Expected:** either the record is created under `bbbbbbbbbbbbbbbb`, or `404`.

**Actual:** `201` with a newly generated `_id`. A client that retries the same PUT creates a new
record every time.

**Root cause:** `src/services/usuarios-service.js:45` and `src/services/produtos-service.js:148` use
an upsert that doesn't keep the requested `_id`.

---

## Documentation defects (Swagger)

The spec served by the API (`GET /swagger.json`) disagrees with the API's behavior in four places.

| ID | Swagger says | API does | Source |
|---|---|---|---|
| DOC-01 | Deleting a product that is in a cart returns `idCarrinho` | Returns `idCarrinhos` (an array) | `docs/swagger.json:1359`, `src/controllers/produtos-controller.js:39` |
| DOC-02 | Product body has `nome`, `preco`, `descricao`, `quantidade` | Also accepts, stores, and returns `imagem` | `src/models/produtos-model.js:28` |
| DOC-03 | `quantidadeTotal` filter allows a minimum of 0 | Rejects 0: "deve ser um número positivo" | `src/models/carrinhos-model.js:8` |
| DOC-04 | Status codes 200, 201, 400, 401, 403 | Also returns 405 (unknown route), 413 (body over 100 KB), and 415 (unsupported charset) | `src/app.js:171`, `src/middlewares/error-handler.js:25,28` |

DRIFT-04 automates the 405 and 413 checks. The 415 case was found while comparing this suite with
ServeRest's own tests, and isn't automated yet.

## Not considered bugs

- Open CORS (`Access-Control-Allow-Origin: *`): acceptable because tokens travel in a header, not
  in cookies (PLT-07).
- Forged tokens (another key, `alg: none`, a tampered payload) are rejected correctly
  (TOK-03 to TOK-05).
- Changing a password invalidates old tokens, and demoting an admin takes effect immediately
  (TOK-08, TOK-09).
