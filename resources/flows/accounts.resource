*** Settings ***
Documentation       Business steps for users and authentication. Setup steps that must succeed:
...                 they fail immediately, with a clear message, if ServeRest refuses them.

Library             Collections
Library             RequestsLibrary
Library             libraries.http_helpers.HttpHelpers
Resource            ../common/test_data.resource
Resource            ../api/users.resource
Resource            ../api/login.resource


*** Keywords ***
Register User
    [Documentation]    Creates a user with generated data and registers it for cleanup.
    ...    Any field can be overridden, e.g. ``administrador=true``.
    ...    Returns the payload plus the ``_id`` ServeRest assigned.
    [Arguments]    &{overrides}
    ${user}=    Generate User    &{overrides}
    ${response}=    POST User    ${user}
    Register Response For Cleanup    user    ${response}
    Status Should Be    201    ${response}    msg=Setup failed: could not register user
    Set To Dictionary    ${user}    _id=${response.json()}[_id]
    RETURN    ${user}

Log In As
    [Documentation]    Logs in and returns the token as a ``Secret``.
    [Arguments]    ${user}
    ${response}=    POST Login    ${user}[email]    ${user}[password]
    Status Should Be    200    ${response}    msg=Setup failed: could not log in as ${user}[email]
    ${token}=    Extract Token    ${response}
    RETURN    ${token}

Create Customer With Token
    [Documentation]    Registers a non-admin user and logs in. The token is under ``token``.
    ${customer}=    Register User    administrador=false
    ${token}=    Log In As    ${customer}
    Set To Dictionary    ${customer}    token=${token}
    RETURN    ${customer}

Create Admin With Token
    [Documentation]    Registers an admin user and logs in. The token is under ``token``.
    ${admin}=    Register User    administrador=true
    ${token}=    Log In As    ${admin}
    Set To Dictionary    ${admin}    token=${token}
    RETURN    ${admin}
