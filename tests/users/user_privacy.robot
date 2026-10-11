*** Settings ***
Documentation       Users: exposure of personal data and unauthenticated changes.
...                 All of these rules are broken in ServeRest 3.2.2 (tagged known-defect).

Resource            ../../resources/main.resource


*** Test Cases ***
SEC-01 User Listing Does Not Expose Passwords
    [Tags]    SEC-01    security    priority:high    known-defect
    ${user}=    Register User

    ${response}=    GET Users    email=${user}[email]

    Status Should Be    200    ${response}
    FOR    ${listed}    IN    @{response.json()}[usuarios]
        Dictionary Should Not Contain Key    ${listed}    password
        ...    msg=GET /usuarios returns the password of ${listed}[email]
    END

SEC-03 Deleting A User Requires Authentication
    [Tags]    SEC-03    security    priority:high    known-defect
    ${victim}=    Register User

    ${response}=    DELETE User    ${victim}[_id]

    Status Should Be    401    ${response}    msg=An anonymous request deleted another user's account
    User Should Exist With Data    ${victim}[_id]    ${victim}

SEC-04 Users Cannot Be Searched By Password
    [Documentation]    The ``password`` filter does a case-insensitive partial match, so
    ...    ``?password=searchable`` finds a user whose password is ``AbcSearchable123``.
    [Tags]    SEC-04    security    priority:critical    known-defect
    ${user}=    Register User    password=AbcSearchable123

    ${response}=    GET Users    password=searchable

    ${found}=    Evaluate    [u['email'] for u in $response.json().get('usuarios', [])]
    Should Not Contain    ${found}    ${user}[email]
    ...    msg=Searching by part of a password returned the user who owns it

SEC-07 Self-Registration Can't Create An Admin
    [Documentation]    Anyone can call POST /usuarios with ``administrador: "true"`` and get
    ...    full control of the catalog.
    [Tags]    SEC-07    security    priority:high    known-defect
    ${user}=    Generate User    administrador=true

    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}

    Should Not Be Equal As Integers    ${response.status_code}    201
    ...    msg=An anonymous request created an admin account
