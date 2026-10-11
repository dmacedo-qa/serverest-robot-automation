*** Settings ***
Documentation       Authentication: POST /login.

Resource            ../../resources/main.resource


*** Test Cases ***
AUTH-01 Registered User Logs In And Receives A Bearer Token
    [Tags]    AUTH-01    positive    priority:critical    smoke
    ${user}=    Register User

    ${response}=    POST Login    ${user}[email]    ${user}[password]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.auth.login_success}
    Response Should Contain Bearer Token    ${response}

AUTH-05 Wrong Password Is Rejected
    [Tags]    AUTH-05    negative    priority:critical
    ${user}=    Register User

    ${response}=    POST Login    ${user}[email]    wrong-password

    Request Should Fail With    ${response}    401    ${MSG.auth.invalid_credentials}

AUTH-06 Unknown Email Gets The Same Error As A Wrong Password
    [Documentation]    Both cases must look the same, so nobody can probe which emails exist.
    [Tags]    AUTH-06    security    priority:high
    ${email}=    Unique Email

    ${response}=    POST Login    ${email}    any-password

    Request Should Fail With    ${response}    401    ${MSG.auth.invalid_credentials}

AUTH-07 Invalid Login Body Is Rejected With A Field Message
    [Tags]    AUTH-07    negative    priority:high
    [Template]    Login Body Should Be Rejected
    # field      value                rule
    email        <missing>            required
    password     <missing>            required
    email        ${EMPTY}             blank
    password     ${EMPTY}             blank
    email        not-an-email         invalid_email
    password     ${12345}             string
    extra        unexpected           not_allowed


*** Keywords ***
Login Body Should Be Rejected
    [Documentation]    Removes or replaces one field of a valid login body and checks the field error.
    [Arguments]    ${field}    ${value}    ${rule}
    VAR    &{body}    email=someone@example.com    password=any-password
    IF    $value == '<missing>'
        Remove From Dictionary    ${body}    ${field}
    ELSE
        Set To Dictionary    ${body}    ${field}=${value}
    END
    ${response}=    POST Login With Body    ${body}
    Response Should Have Field Error    ${response}    ${field}    ${rule}
