*** Settings ***
Documentation       Endpoint keywords for routes outside the business resources, and for raw
...                 requests used to test the HTTP layer itself. No assertions.

Resource            ../common/http.resource


*** Keywords ***
GET Version
    [Documentation]    Sends GET /version.
    ${response}=    Send Request    GET    /version
    RETURN    ${response}

GET Swagger
    [Documentation]    Sends GET /swagger.json, the spec served by the running instance.
    ${response}=    Send Request    GET    /swagger.json
    RETURN    ${response}

Send Raw Request
    [Documentation]    Sends any method to any path, optionally with a raw body. Used to test
    ...    routing, malformed JSON, and other HTTP-level behavior.
    [Arguments]    ${method}    ${path}    ${body}=${NONE}    ${content_type}=application/json
    VAR    &{headers}    Content-Type=${content_type}
    ${response}=    Send Request    ${method}    ${path}    data=${body}    headers=${headers}
    RETURN    ${response}
