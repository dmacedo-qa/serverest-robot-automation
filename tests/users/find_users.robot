*** Settings ***
Documentation       Users: listing, filtering, and reading by ID.
...                 Other tests (and pabot workers) create users at the same time, so these tests
...                 never compare totals between two calls. Each one checks a single response.

Resource            ../../resources/main.resource


*** Test Cases ***
USR-02 User List Count Matches Its Content
    [Tags]    USR-02    positive    priority:medium
    Register User

    ${response}=    GET Users

    Status Should Be    200    ${response}
    ${listed}=    Get Length    ${response.json()}[usuarios]
    Should Be Equal As Integers    ${response.json()}[quantidade]    ${listed}

USR-03 Filter By Email Returns Only That User
    [Tags]    USR-03    positive    priority:medium
    ${user}=    Register User

    ${response}=    GET Users    email=${user}[email]

    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    Should Be Equal    ${response.json()}[usuarios][0][_id]    ${user}[_id]

USR-04 Filter By Name Is Partial And Case-Insensitive
    [Tags]    USR-04    positive    priority:low
    ${tag}=    Unique Tag
    ${user}=    Register User    nome=Ana ${tag} Souza

    ${response}=    GET Users    nome=${tag.upper()}

    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    Should Be Equal    ${response.json()}[usuarios][0][_id]    ${user}[_id]

USR-05 Filter By Role Returns Only That Role
    [Tags]    USR-05    positive    priority:low
    Register User    administrador=true

    ${response}=    GET Users    administrador=true

    Status Should Be    200    ${response}
    FOR    ${listed}    IN    @{response.json()}[usuarios]
        Should Be Equal    ${listed}[administrador]    true    msg=${listed}[email] isn't an admin
    END

USR-06 Combined Filters Must All Match
    [Tags]    USR-06    positive    priority:low
    ${tag}=    Unique Tag
    ${admin}=    Register User    nome=Admin ${tag}    administrador=true
    Register User    nome=Customer ${tag}    administrador=false

    ${response}=    GET Users    nome=${tag}    administrador=true

    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    Should Be Equal    ${response.json()}[usuarios][0][_id]    ${admin}[_id]

USR-13 Unknown User ID Returns Not Found
    [Tags]    USR-13    negative    priority:medium
    ${response}=    GET User By Id    aaaaaaaaaaaaaaaa

    Request Should Fail With    ${response}    400    ${MSG.users.not_found}

USR-14 Malformed User ID Is Rejected
    [Tags]    USR-14    negative    priority:medium
    [Template]    Malformed User Id Should Be Rejected
    aaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaa
    aaaaaaaa-aaaaaaa
    aaaaaaaa_aaaaaaa

USR-16 Invalid Filters Are Rejected
    [Tags]    USR-16    negative    priority:low
    [Template]    Filter Should Be Rejected
    # list endpoint    filter             value        rule
    GET Users          email              not-email    invalid_email
    GET Users          administrador      TRUE         boolean_string
    GET Users          cidade             Recife       not_allowed

USR-22 Empty Filter Value Is Ignored
    [Documentation]    ``?nome=`` must not restrict the result: combined with an email filter it
    ...    still returns that user.
    [Tags]    USR-22    edge    priority:low
    ${user}=    Register User

    ${response}=    GET Users    nome=${EMPTY}    email=${user}[email]

    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1


*** Keywords ***
Malformed User Id Should Be Rejected
    [Documentation]    GET /usuarios/{id} with an ID that isn't 16 alphanumeric characters.
    [Arguments]    ${user_id}
    ${response}=    GET User By Id    ${user_id}
    Response Should Have Field Error    ${response}    id    sixteen_chars
