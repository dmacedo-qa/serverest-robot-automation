*** Settings ***
Documentation       Authentication: POST /login.

Resource            ../../resources/common/setup.resource
Resource            ../../resources/flows/accounts.resource
Resource            ../../resources/verifications/responses.resource

Suite Setup         Start API Session
Suite Teardown      End API Session
Test Teardown       Clean Up Test Data

Test Tags           auth    regression


*** Test Cases ***
AUTH-01 Registered User Logs In And Receives A Bearer Token
    [Documentation]    A registered user logs in with valid credentials and receives a JWT.
    [Tags]    AUTH-01    positive    priority:critical    smoke
    ${user}=    Register User

    ${response}=    POST Login    ${user}[email]    ${user}[password]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.auth.login_success}
    Response Should Contain Bearer Token    ${response}
