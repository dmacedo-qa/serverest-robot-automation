*** Settings ***
Documentation       Assertions about a single HTTP response.

Library             RequestsLibrary
Library             libraries.http_helpers.HttpHelpers
Library             libraries.schema_assertions.SchemaAssertions
Resource            ../common/test_data.resource


*** Keywords ***
Response Message Should Be
    [Documentation]    Checks the ``message`` field of a JSON response.
    [Arguments]    ${response}    ${expected}
    Should Be Equal    ${response.json()}[message]    ${expected}

Request Should Fail With
    [Documentation]    Checks the status code and the ``message`` of an error response.
    [Arguments]    ${response}    ${status}    ${message}
    Status Should Be    ${status}    ${response}
    Response Message Should Be    ${response}    ${message}

Response Should Have Field Error
    [Documentation]    Checks a 400 validation error for one field. ``rule`` is a key of
    ...    ``MSG.field_rules``, so ``email`` + ``required`` expects "email é obrigatório".
    [Arguments]    ${response}    ${field}    ${rule}
    Status Should Be    400    ${response}
    VAR    ${expected}    ${field} ${MSG.field_rules}[${rule}]
    Should Be Equal    ${response.json()}[${field}]    ${expected}

Response Should Contain Bearer Token
    [Documentation]    Checks that ``authorization`` is ``Bearer <JWT>``, without ever logging the token.
    [Arguments]    ${response}
    ${token}=    Extract Token    ${response}
    Should Match Regexp    ${token.value}    ^Bearer [\\w-]+\\.[\\w-]+\\.[\\w-]+$
    ...    msg=authorization is not "Bearer <JWT>"    values=False
