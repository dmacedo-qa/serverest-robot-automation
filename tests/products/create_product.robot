*** Settings ***
Documentation       Products: creating a product with POST /produtos.

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-01 Admin Creates A Product That Is Retrievable By Id
    [Documentation]    An admin creates a product, and GET by ID returns exactly the data sent.
    [Tags]    PRD-01    positive    priority:critical    smoke
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    Product Should Exist With Data    ${response.json()}[_id]    ${product}
