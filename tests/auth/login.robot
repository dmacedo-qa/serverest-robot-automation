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

AUTH-02 Admin Token Grants Access To Admin Routes
    [Tags]    AUTH-02    positive    priority:high
    ${admin}=    Register User    administrador=true
    ${login}=    POST Login    ${admin}[email]    ${admin}[password]
    Status Should Be    200    ${login}
    ${token}=    Extract Token    ${login}
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${token}
    Register Response For Cleanup    product    ${response}    ${token}

    Status Should Be    201    ${response}

AUTH-03 Customer Token Grants Access To Customer Routes
    [Tags]    AUTH-03    positive    priority:high
    ${customer}=    Register User
    ${login}=    POST Login    ${customer}[email]    ${customer}[password]
    Status Should Be    200    ${login}
    ${token}=    Extract Token    ${login}

    ${response}=    DELETE Cart To Cancel Purchase    ${token}

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.carts.no_cart_for_user}

AUTH-04 Login Also Accepts A Form-Encoded Body
    [Documentation]    Not in the Swagger, but the API parses ``application/x-www-form-urlencoded``.
    [Tags]    AUTH-04    positive    priority:low
    ${user}=    Register User

    ${response}=    POST Login As Form    ${user}[email]    ${user}[password]

    Status Should Be    200    ${response}
    Response Should Contain Bearer Token    ${response}

AUTH-08 Login Email Is Case-Sensitive
    [Documentation]    Current behavior: the email must match exactly. See DQ-01 for the
    ...    related uniqueness problem.
    [Tags]    AUTH-08    edge    priority:low
    ${user}=    Register User

    ${response}=    POST Login    ${{ $user['email'].upper() }}    ${user}[password]

    Request Should Fail With    ${response}    401    ${MSG.auth.invalid_credentials}


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
