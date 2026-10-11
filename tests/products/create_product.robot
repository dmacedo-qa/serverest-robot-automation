*** Settings ***
Documentation       Products: creating a product with POST /produtos.

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-01 Admin Creates A Product That Is Retrievable By Id
    [Tags]    PRD-01    positive    priority:critical    smoke
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    Product Should Exist With Data    ${response.json()}[_id]    ${product}

PRD-14 Price And Stock Boundaries
    [Documentation]    ``preco`` must be an integer from 1 to 2^53 - 1. ``quantidade`` may be 0.
    [Tags]    PRD-14    edge    priority:medium
    [Template]    Product Field Value Should Give
    # field        value                       status    rule
    preco          ${0}                        400       positive_number
    preco          ${1}                        201
    preco          ${9007199254740991}         201
    preco          ${9007199254740993}         400       max_safe_integer
    quantidade     ${-1}                       400       min_zero
    quantidade     ${0}                        201


*** Keywords ***
Product Field Value Should Give
    [Documentation]    Creates a product with one field set to ``value``: expects a field error
    ...    when ``rule`` is given, otherwise ``status`` and the stored product.
    [Arguments]    ${field}    ${value}    ${status}    ${rule}=${NONE}
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product
    Set To Dictionary    ${product}    ${field}=${value}

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    IF    $rule
        Response Should Have Field Error    ${response}    ${field}    ${rule}
    ELSE
        Status Should Be    ${status}    ${response}
        Product Should Exist With Data    ${response.json()}[_id]    ${product}
    END
