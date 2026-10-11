*** Settings ***
Documentation       Users: creating a user with POST /usuarios.

Resource            ../../resources/main.resource


*** Test Cases ***
USR-01 New Customer Is Created And Retrievable By Id
    [Documentation]    A non-admin user is created, and GET by ID returns exactly the data sent.
    [Tags]    USR-01    positive    priority:critical    smoke
    New User Should Be Created And Retrievable    administrador=false

USR-01 New Admin Is Created And Retrievable By Id
    [Documentation]    An admin user is created, and GET by ID returns exactly the data sent.
    [Tags]    USR-01    positive    priority:critical
    New User Should Be Created And Retrievable    administrador=true


*** Keywords ***
New User Should Be Created And Retrievable
    [Documentation]    Creates a user with the given role and checks the response and the stored record.
    [Arguments]    ${administrador}
    ${user}=    Generate User    administrador=${administrador}

    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    User Should Exist With Data    ${response.json()}[_id]    ${user}
