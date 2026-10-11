*** Settings ***
Documentation       Users: updating with PUT and deleting.

Resource            ../../resources/main.resource


*** Test Cases ***
USR-07 User Is Updated With PUT
    [Tags]    USR-07    positive    priority:high
    ${user}=    Register User
    ${changes}=    Generate User    administrador=true

    ${response}=    PUT User    ${user}[_id]    ${changes}
    Register Response For Cleanup    user    ${response}

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.updated}
    User Should Exist With Data    ${user}[_id]    ${changes}

USR-08 PUT Keeping The Same Email Is Not A Duplicate
    [Tags]    USR-08    positive    priority:medium
    ${user}=    Register User
    ${changes}=    Generate User    email=${user}[email]

    ${response}=    PUT User    ${user}[_id]    ${changes}

    Status Should Be    200    ${response}
    User Should Exist With Data    ${user}[_id]    ${changes}

USR-09 User Without A Cart Is Deleted
    [Tags]    USR-09    positive    priority:high
    ${user}=    Register User

    ${response}=    DELETE User    ${user}[_id]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.deleted}
    ${lookup}=    GET User By Id    ${user}[_id]
    Request Should Fail With    ${lookup}    400    ${MSG.users.not_found}

USR-11 PUT With Another User's Email Is Rejected
    [Tags]    USR-11    negative    priority:high
    ${user}=    Register User
    ${other}=    Register User
    ${changes}=    Generate User    email=${other}[email]

    ${response}=    PUT User    ${user}[_id]    ${changes}

    Request Should Fail With    ${response}    400    ${MSG.users.email_taken}
    User Should Exist With Data    ${user}[_id]    ${user}

USR-15 User With A Cart Can't Be Deleted
    [Tags]    USR-15    negative    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${items}=    Cart Items    ${product}[_id]    1
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    DELETE User    ${customer}[_id]

    Request Should Fail With    ${response}    400    ${MSG.users.has_cart}
    Should Be Equal    ${response.json()}[idCarrinho]    ${cart_id}
    User Should Exist With Data    ${customer}[_id]    ${customer}

USR-17 Deleting An Unknown ID Is Harmless
    [Tags]    USR-17    edge    priority:low
    ${response}=    DELETE User    aaaaaaaaaaaaaaaa

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.nothing_deleted}

USR-18 PUT On An Unknown ID Creates A User With A New ID
    [Documentation]    Documented upsert. The ID in the URL is ignored: ServeRest generates another.
    [Tags]    USR-18    edge    priority:medium
    ${payload}=    Generate User

    ${response}=    PUT User    aaaaaaaaaaaaaaaa    ${payload}
    Register Response For Cleanup    user    ${response}

    Status Should Be    201    ${response}
    Should Not Be Equal    ${response.json()}[_id]    aaaaaaaaaaaaaaaa
    User Should Exist With Data    ${response.json()}[_id]    ${payload}

DQ-09 Malformed IDs Are Rejected On Every Verb
    [Documentation]    GET rejects malformed IDs, but PUT accepts them and creates a user.
    [Tags]    DQ-09    negative    priority:low    known-defect
    ${payload}=    Generate User

    ${response}=    PUT User    abc    ${payload}
    Register Response For Cleanup    user    ${response}

    Status Should Be    400    ${response}    msg=PUT /usuarios/abc was accepted
    Response Should Have Field Error    ${response}    id    sixteen_chars

DQ-10 PUT On An Unknown ID Keeps That ID
    [Documentation]    An upsert should create the record under the requested ID (or return 404).
    ...    ServeRest creates it under a different, generated ID.
    [Tags]    DQ-10    edge    priority:low    known-defect
    ${payload}=    Generate User

    ${response}=    PUT User    bbbbbbbbbbbbbbbb    ${payload}
    Register Response For Cleanup    user    ${response}

    Should Be Equal    ${response.json()}[_id]    bbbbbbbbbbbbbbbb
    ...    msg=PUT created the user under a different ID than the one requested
