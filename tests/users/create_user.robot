*** Settings ***
Documentation       Users: creating a user with POST /usuarios.

Resource            ../../resources/main.resource


*** Test Cases ***
USR-01 New Customer Is Created And Retrievable By Id
    [Tags]    USR-01    positive    priority:critical    smoke
    New User Should Be Created And Retrievable    administrador=false

USR-01 New Admin Is Created And Retrievable By Id
    [Documentation]    Current behavior: anyone can register an admin. SEC-07 asserts that this
    ...    shouldn't be allowed; if ServeRest fixes it, this case changes with it.
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

USR-19 Accents, Apostrophes, And Emoji In Names Are Kept Exactly
    [Tags]    USR-19    edge    priority:medium
    ${user}=    Register User    nome=João D'Ávila Çaña 😀

    User Should Exist With Data    ${user}[_id]    ${user}

USR-20 Long Names Are Accepted
    [Documentation]    There is no length limit on ``nome``.
    [Tags]    USR-20    edge    priority:low
    ${user}=    Register User    nome=${{ 'N' * 300 }}

    User Should Exist With Data    ${user}[_id]    ${user}

USR-21 Plus-Addressing And Subdomains Are Valid Emails
    [Tags]    USR-21    edge    priority:low
    ${email}=    Unique Email
    ${user}=    Register User    email=${{ $email.replace('@', '+tag@sub.') }}

    User Should Exist With Data    ${user}[_id]    ${user}

USR-23 Body Larger Than 100 KB Is Rejected
    [Tags]    USR-23    edge    priority:low
    ${user}=    Generate User    nome=${{ 'x' * 120000 }}

    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}

    Request Should Fail With    ${response}    413    ${MSG.common.payload_too_large}

DQ-04 Blank Name Is Rejected
    [Documentation]    ``"   "`` passes validation because only empty strings are checked.
    [Tags]    DQ-04    negative    priority:medium    known-defect
    ${user}=    Generate User    nome=${SPACE * 3}

    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}

    Status Should Be    400    ${response}    msg=A name made only of spaces was accepted
    Response Should Have Field Error    ${response}    nome    blank


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
    ${valid}=    Generate User
    ${user}=    Payload With Field    ${valid}    ${field}    ${value}
    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}
    Response Should Have Field Error    ${response}    ${field}    ${rule}
