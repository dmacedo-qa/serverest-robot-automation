*** Settings ***
Documentation       HTTP layer: version, routing, malformed requests, and CORS.

Resource            ../../resources/main.resource


*** Test Cases ***
PLT-01 Version Endpoint Reports The Pinned Release
    [Documentation]    Also the entry criterion: the suite runs against the version it was written for.
    [Tags]    PLT-01    positive    priority:high    smoke
    ${response}=    GET Version

    Status Should Be    200    ${response}
    Should Be Equal    ${response.json()}[version]    ${SERVEREST_VERSION}

PLT-02 Unknown Route Returns 405 Naming The Method And Path
    [Tags]    PLT-02    negative    priority:low
    ${response}=    Send Raw Request    GET    /pedidos

    Status Should Be    405    ${response}
    Should Start With    ${response.json()}[message]    ${MSG.platform.method_not_allowed} GET em /pedidos.

PLT-03 Unsupported Method Returns 405
    [Tags]    PLT-03    negative    priority:low
    ${response}=    Send Raw Request    PATCH    /usuarios    {}

    Status Should Be    405    ${response}
    Should Start With    ${response.json()}[message]    ${MSG.platform.method_not_allowed} PATCH em /usuarios.

PLT-04 Malformed JSON Is Rejected On Every Write Route
    [Documentation]    The body is parsed before authentication, so no token is needed.
    [Tags]    PLT-04    negative    priority:medium
    [Template]    Malformed JSON Should Be Rejected
    POST      /login
    POST      /usuarios
    PUT       /usuarios/aaaaaaaaaaaaaaaa
    POST      /produtos
    POST      /carrinhos

PLT-05 Invalid Percent-Encoding In The URL Is Rejected
    [Documentation]    ``%FF`` is valid percent-encoding but not valid UTF-8. A malformed sequence
    ...    like ``%A`` would be re-encoded by the HTTP client and never reach the server as is.
    [Tags]    PLT-05    negative    priority:low
    ${response}=    GET User By Id    %FF

    Request Should Fail With    ${response}    400    ${MSG.platform.invalid_url}

PLT-06 Body Larger Than 100 KB Is Rejected
    [Tags]    PLT-06    negative    priority:low
    ${body}=    Evaluate    '{"email": "' + 'x' * 120000 + '"}'

    ${response}=    Send Raw Request    POST    /login    ${body}

    Request Should Fail With    ${response}    413    ${MSG.common.payload_too_large}

PLT-07 Any Origin Can Call The API
    [Documentation]    CORS is open (``*``). Acceptable here because tokens travel in a header,
    ...    not in cookies, so other sites can't use a visitor's session.
    [Tags]    PLT-07    security    priority:low
    ${response}=    GET Version

    Should Be Equal    ${response.headers}[Access-Control-Allow-Origin]    *


*** Keywords ***
Malformed JSON Should Be Rejected
    [Documentation]    Sends a body with an unquoted value to one route.
    [Arguments]    ${method}    ${path}
    ${response}=    Send Raw Request    ${method}    ${path}    {"nome": Fulano}
    Request Should Fail With    ${response}    400    ${MSG.platform.malformed_json}
