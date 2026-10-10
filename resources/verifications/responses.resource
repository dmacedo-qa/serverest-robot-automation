*** Settings ***
Documentation       Assertions about a single HTTP response.

Library             RequestsLibrary
Library             libraries.http_helpers.HttpHelpers


*** Keywords ***
Response Message Should Be
    [Documentation]    Checks the ``message`` field of a JSON response.
    [Arguments]    ${response}    ${expected}
    Should Be Equal    ${response.json()}[message]    ${expected}

Response Should Contain Bearer Token
    [Documentation]    Checks that ``authorization`` is ``Bearer <JWT>``. The token is never shown,
    ...    not even when the check fails.
    [Arguments]    ${response}
    ${token}=    Extract Token    ${response}
    Should Match Regexp    ${token.value}    ^Bearer [\\w-]+\\.[\\w-]+\\.[\\w-]+$
    ...    msg=authorization is not "Bearer <JWT>"    values=False
