*** Settings ***
Documentation       Single import for test suites: every flow, verification, and endpoint keyword.
...
...                 Test files import only this file. The layers below keep their own explicit
...                 imports, so each one still declares exactly what it depends on.

Resource            common/setup.resource
Resource            api/login.resource
Resource            api/users.resource
Resource            api/products.resource
Resource            api/carts.resource
Resource            flows/accounts.resource
Resource            flows/catalog.resource
Resource            verifications/responses.resource
Resource            verifications/records.resource
