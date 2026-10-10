*** Settings ***
Documentation       Endpoint keywords for /usuarios. One HTTP call each, no assertions.
...                 ServeRest doesn't require a token on any /usuarios route (see SEC-03).

Resource            ../common/http.resource


*** Variables ***
${USERS_PATH}       /usuarios


*** Keywords ***
POST User
    [Documentation]    Sends POST /usuarios with the given payload.
    [Arguments]    ${payload}
    ${response}=    Send Request    POST    ${USERS_PATH}    json=${payload}
    RETURN    ${response}

GET Users
    [Documentation]    Sends GET /usuarios. Named arguments become query filters, e.g. ``email=a@b.com``.
    [Arguments]    &{filters}
    ${response}=    Send Request    GET    ${USERS_PATH}    params=${filters}
    RETURN    ${response}

GET User By Id
    [Documentation]    Sends GET /usuarios/{id}.
    [Arguments]    ${user_id}
    ${response}=    Send Request    GET    ${USERS_PATH}/${user_id}
    RETURN    ${response}

PUT User
    [Documentation]    Sends PUT /usuarios/{id}. Creates the user if the ID doesn't exist (upsert).
    [Arguments]    ${user_id}    ${payload}
    ${response}=    Send Request    PUT    ${USERS_PATH}/${user_id}    json=${payload}
    RETURN    ${response}

DELETE User
    [Documentation]    Sends DELETE /usuarios/{id}.
    [Arguments]    ${user_id}
    ${response}=    Send Request    DELETE    ${USERS_PATH}/${user_id}
    RETURN    ${response}
