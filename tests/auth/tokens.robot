*** Settings ***
Documentation       Token validation on protected routes. A customer route
...                 (DELETE /carrinhos/cancelar-compra) is used as the probe: with a valid
...                 token and no cart it returns 200, so any other status comes from the token.

Resource            ../../resources/main.resource


*** Test Cases ***
TOK-01 Protected Route Without A Token Returns 401
    [Tags]    TOK-01    negative    priority:critical    smoke
    ${response}=    DELETE Cart To Cancel Purchase

    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}

TOK-02 Malformed Authorization Header Returns 401
    [Tags]    TOK-02    negative    priority:high
    [Template]    Authorization Header Should Be Rejected
    Bearer
    bearer {jwt}
    {jwt}
    Bearer abc
    Basic dXNlcjpwYXNz

TOK-03 Token Signed With Another Key Returns 401
    [Tags]    TOK-03    security    priority:high
    Forged Token Should Be Rejected    wrong_key

TOK-04 Unsigned Token With Alg None Returns 401
    [Tags]    TOK-04    security    priority:high
    Forged Token Should Be Rejected    alg_none

TOK-05 Token With A Tampered Payload Returns 401
    [Tags]    TOK-05    security    priority:high
    Forged Token Should Be Rejected    tampered

TOK-06 Token Stops Working After It Expires
    [Documentation]    Runs on the instance started with ``--timeout 5``.
    [Tags]    TOK-06    negative    priority:high
    Use Short Token Instance
    ${customer}=    Create Customer With Token

    ${before}=    DELETE Cart To Cancel Purchase    ${customer}[token]
    Sleep    6s    reason=Token lifetime on this instance is 5 seconds
    ${after}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Status Should Be    200    ${before}
    Request Should Fail With    ${after}    401    ${MSG.auth.token_invalid}

TOK-11 Customer Token On An Admin Route Returns 403
    [Tags]    TOK-11    negative    priority:critical
    ${customer}=    Create Customer With Token
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${customer}[token]
    Register Response For Cleanup    product    ${response}

    Request Should Fail With    ${response}    403    ${MSG.auth.admin_only}

SEC-02 JWT Payload Must Not Contain The Password
    [Documentation]    The payload of a JWT is only base64-encoded, so anyone holding the token
    ...    can read it. ServeRest 3.2.2 puts the password in it.
    [Tags]    SEC-02    security    priority:high    known-defect
    ${customer}=    Create Customer With Token

    ${fields}=    Token Payload Fields    ${customer}[token]

    Should Not Contain    ${fields}    password    msg=JWT payload exposes the password. Fields: ${fields}

TOK-07 Token Of A Deleted User Returns 401
    [Tags]    TOK-07    negative    priority:medium
    ${customer}=    Create Customer With Token
    ${deleted}=    DELETE User    ${customer}[_id]
    Status Should Be    200    ${deleted}

    ${response}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}

TOK-08 Token Stops Working After A Password Change
    [Tags]    TOK-08    negative    priority:medium
    ${customer}=    Create Customer With Token
    Update User    ${customer}    password=a-new-password

    ${response}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}

TOK-09 Demoted Admin Loses Admin Access Immediately
    [Documentation]    The role is read from the database on every request, not from the token.
    [Tags]    TOK-09    negative    priority:high
    ${admin}=    Create Admin With Token
    Update User    ${admin}    administrador=false
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}

    Request Should Fail With    ${response}    403    ${MSG.auth.admin_only}

TOK-10 Token Survives A Name Change
    [Documentation]    Only email and password are bound to the token.
    [Tags]    TOK-10    edge    priority:low
    ${customer}=    Create Customer With Token
    Update User    ${customer}    nome=Renamed Customer

    ${response}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Status Should Be    200    ${response}

SEC-08 Responses Carry Security Headers
    [Tags]    SEC-08    security    priority:medium
    ${response}=    GET Version

    Should Be Equal    ${response.headers}[X-Frame-Options]    SAMEORIGIN
    Should Be Equal    ${response.headers}[X-Content-Type-Options]    nosniff
    Should Start With    ${response.headers}[Strict-Transport-Security]    max-age\=
    Should Not Contain    ${response.headers}    X-Powered-By    msg=Server technology is disclosed


*** Keywords ***
Authorization Header Should Be Rejected
    [Documentation]    Sends a header built from a valid token, e.g. ``bearer {jwt}``.
    [Arguments]    ${header_template}
    ${customer}=    Create Customer With Token
    ${header}=    Authorization Header From Template    ${customer}[token]    ${header_template}
    ${response}=    DELETE Cart To Cancel Purchase    ${header}
    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}

Forged Token Should Be Rejected
    [Documentation]    Builds an invalid variant of a valid token (see ``Forge Token``).
    [Arguments]    ${mode}
    ${customer}=    Create Customer With Token
    ${forged}=    Forge Token    ${customer}[token]    ${mode}

    ${response}=    DELETE Cart To Cancel Purchase    ${forged}

    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}
