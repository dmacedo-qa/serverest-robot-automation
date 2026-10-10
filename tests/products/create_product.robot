*** Settings ***
Documentation       Products: creating a product with POST /produtos.

Resource            ../../resources/common/setup.resource
Resource            ../../resources/flows/accounts.resource
Resource            ../../resources/verifications/responses.resource
Resource            ../../resources/verifications/records.resource

Suite Setup         Start API Session
Suite Teardown      End API Session
Test Teardown       Clean Up Test Data

Test Tags           products    regression


*** Test Cases ***
PRD-01 Admin Creates A Product That Is Retrievable By Id
    [Documentation]    An admin creates a product, and GET by ID returns exactly the data sent.
    [Tags]    PRD-01    smoke
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    Product Should Exist With Data    ${response.json()}[_id]    ${product}
