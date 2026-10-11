*** Settings ***
Documentation       Products: only admins can create, change, or delete products.

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-07 Customer Cannot Change The Catalog
    [Tags]    PRD-07    negative    priority:critical
    [Template]    Catalog Change Should Be Refused
    POST      customer    403    ${MSG.auth.admin_only}
    PUT       customer    403    ${MSG.auth.admin_only}
    DELETE    customer    403    ${MSG.auth.admin_only}

PRD-08 Anonymous User Cannot Change The Catalog
    [Tags]    PRD-08    negative    priority:critical
    [Template]    Catalog Change Should Be Refused
    POST      anonymous    401    ${MSG.auth.token_invalid}
    PUT       anonymous    401    ${MSG.auth.token_invalid}
    DELETE    anonymous    401    ${MSG.auth.token_invalid}


*** Keywords ***
Catalog Change Should Be Refused
    [Documentation]    Tries the change as ``persona`` and checks that the refusal is correct
    ...    and that the existing product didn't change.
    [Arguments]    ${method}    ${persona}    ${status}    ${message}
    ${admin}=    Create Admin With Token
    ${existing}=    Admin Creates Product    ${admin}[token]
    IF    $persona == 'customer'
        ${caller}=    Create Customer With Token
        VAR    ${token}    ${caller}[token]
    ELSE
        VAR    ${token}    ${NONE}
    END
    ${changes}=    Generate Product

    IF    $method == 'POST'
        ${response}=    POST Product    ${changes}    ${token}
        Register Response For Cleanup    product    ${response}    ${admin}[token]
    ELSE IF    $method == 'PUT'
        ${response}=    PUT Product    ${existing}[_id]    ${changes}    ${token}
    ELSE
        ${response}=    DELETE Product    ${existing}[_id]    ${token}
    END

    Request Should Fail With    ${response}    ${status}    ${message}
    Product Should Exist With Data    ${existing}[_id]    ${existing}
