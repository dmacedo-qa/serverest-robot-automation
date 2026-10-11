*** Settings ***
Documentation       ServeRest API test suite.
...
...                 Shared by every suite below: one HTTP session per run (per process under
...                 pabot), data cleanup after every test, and the ``regression`` tag.
...                 Each area folder adds its own area tag in its ``__init__.robot``.

Resource            ../resources/main.resource

Suite Setup         Start API Session
Suite Teardown      End API Session
Test Teardown       Clean Up Test Data

Test Tags           regression
