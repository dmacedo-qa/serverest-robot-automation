*** Settings ***
Documentation       Contracts that hold across every route: error format, content type, and
...                 the responses that don't belong to a resource.

Resource            ../../resources/main.resource


*** Test Cases ***
CON-12 Every Validation Error Is A Map Of Field To Message
    [Tags]    CON-12    contract    priority:medium
    [Template]    Validation Error Should Match Contract
    POST      /login                       {"email": "not-an-email"}
    POST      /usuarios                    {}
    GET       /usuarios?administrador=x    ${NONE}
    GET       /produtos?preco=0            ${NONE}
    GET       /carrinhos/abc               ${NONE}

CON-13 Every Response Is UTF-8 JSON
    [Tags]    CON-13    contract    priority:low
    [Template]    Response Should Be UTF-8 JSON
    GET       /version
    GET       /usuarios/aaaaaaaaaaaaaaaa
    DELETE    /carrinhos/cancelar-compra
    GET       /pedidos

CON-14 Version, 405, And 413 Responses Match Their Contracts
    [Tags]    CON-14    contract    priority:low
    ${version}=    GET Version
    ${not_allowed}=    Send Raw Request    GET    /pedidos
    ${body}=    Evaluate    '{"email": "' + 'x' * 120000 + '"}'
    ${too_large}=    Send Raw Request    POST    /login    ${body}

    Response Should Be    ${version}    200    version
    Response Should Be    ${not_allowed}    405    message
    Response Should Be    ${too_large}    413    message


*** Keywords ***
Validation Error Should Match Contract
    [Documentation]    Sends a request that fails schema validation and checks the error body.
    [Arguments]    ${method}    ${path}    ${body}
    ${response}=    Send Raw Request    ${method}    ${path}    ${body}
    Response Should Be    ${response}    400    validation_error

Response Should Be UTF-8 JSON
    [Documentation]    Checks the Content-Type header of one response.
    [Arguments]    ${method}    ${path}
    ${response}=    Send Raw Request    ${method}    ${path}
    Should Be Equal    ${response.headers}[Content-Type]    application/json; charset=utf-8
