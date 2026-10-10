*** Settings ***
Documentation       Endpoint keywords for /login. One HTTP call each, no assertions.

Resource            ../common/http.resource


*** Variables ***
${LOGIN_PATH}       /login


*** Keywords ***
POST Login
    [Documentation]    Sends POST /login. ``password`` may be a plain string or a ``Secret``.
    [Arguments]    ${email}    ${password}
    VAR    &{body}=    email=${email}    password=${password}
    ${response}=    Send Request    POST    ${LOGIN_PATH}    json=${body}
    RETURN    ${response}
