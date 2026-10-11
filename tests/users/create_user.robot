*** Settings ***
Documentation       Users: creating a user with POST /usuarios.

Resource            ../../resources/main.resource


*** Test Cases ***
USR-01 New Customer Is Created And Retrievable By Id
    [Tags]    USR-01    positive    priority:critical    smoke
    New User Should Be Created And Retrievable    administrador=false

USR-01 New Admin Is Created And Retrievable By Id
    [Tags]    USR-01    positive    priority:critical
    New User Should Be Created And Retrievable    administrador=true

USR-10 Duplicate Email Is Rejected
    [Tags]    USR-10    negative    priority:critical
    ${existing}=    Register User
    ${duplicate}=    Generate User    email=${existing}[email]

    ${response}=    POST User    ${duplicate}
    Register Response For Cleanup    user    ${response}

    Request Should Fail With    ${response}    400    ${MSG.users.email_taken}

USR-12 Invalid User Payload Is Rejected With A Field Message
    [Tags]    USR-12    negative    priority:high
    [Template]    User Payload Should Be Rejected
    # field          value                    rule
    nome             <missing>                required
    email            <missing>                required
    password         <missing>                required
    administrador    <missing>                required
    nome             ${EMPTY}                 blank
    email            ${EMPTY}                 blank
    password         ${EMPTY}                 blank
    nome             ${123}                   string
    email            not-an-email             invalid_email
    email            user@                    invalid_email
    email            @example.com             invalid_email
    email            user@example.test        invalid_email
    administrador    TRUE                     boolean_string
    administrador    yes                      boolean_string
    administrador    ${True}                  boolean_string
    extra            unexpected               not_allowed

DQ-01 Email Uniqueness Ignores Letter Case
    [Documentation]    Email addresses are case-insensitive in practice, so ``A@x.com`` and
    ...    ``a@x.com`` are the same person. ServeRest 3.2.2 creates two accounts.
    [Tags]    DQ-01    negative    priority:medium    known-defect
    ${existing}=    Register User
    ${duplicate}=    Generate User    email=${{ $existing['email'].upper() }}

    ${response}=    POST User    ${duplicate}
    Register Response For Cleanup    user    ${response}

    Status Should Be    400    ${response}    msg=Same email in upper case created a second account
    Response Message Should Be    ${response}    ${MSG.users.email_taken}


*** Keywords ***
New User Should Be Created And Retrievable
    [Documentation]    Creates a user with the given role and reads it back by ID.
    [Arguments]    ${administrador}
    ${user}=    Generate User    administrador=${administrador}

    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    User Should Exist With Data    ${response.json()}[_id]    ${user}

User Payload Should Be Rejected
    [Documentation]    Removes or replaces one field of a valid user and checks the field error.
    [Arguments]    ${field}    ${value}    ${rule}
    ${user}=    Generate User
    IF    $value == '<missing>'
        Remove From Dictionary    ${user}    ${field}
    ELSE
        Set To Dictionary    ${user}    ${field}=${value}
    END
    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}
    Response Should Have Field Error    ${response}    ${field}    ${rule}
