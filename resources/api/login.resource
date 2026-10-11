*** Settings ***
Documentation       Endpoint keywords for /login. One HTTP call each, no assertions.

Resource            ../common/http.resource


*** Variables ***
${LOGIN_PATH}       /login


*** Keywords ***
POST Login
    [Documentation]    Sends POST /login. ``password`` may be a plain string or a ``Secret``.
    [Arguments]    ${email}    ${password}
    VAR    &{body}    email=${email}    password=${password}
    ${response}=    POST Login With Body    ${body}
    RETURN    ${response}

POST Login As Form
    [Documentation]    Sends POST /login as ``application/x-www-form-urlencoded``.
    [Arguments]    ${email}    ${password}
    VAR    &{form}    email=${email}    password=${password}
    ${response}=    Send Request    POST    ${LOGIN_PATH}    data=${form}
    RETURN    ${response}

POST Login With Body
    [Documentation]    Sends POST /login with any body, including invalid ones.
    [Arguments]    ${body}
    ${response}=    Send Request    POST    ${LOGIN_PATH}    json=${body}
    RETURN    ${response}
