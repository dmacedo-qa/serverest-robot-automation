*** Settings ***
Documentation       Products: updating with PUT and deleting (admin only).

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-04 Product Is Updated With PUT
    [Tags]    PRD-04    positive    priority:high
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${changes}=    Generate Product    preco=999    quantidade=50

    ${response}=    PUT Product    ${product}[_id]    ${changes}    ${admin}[token]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.updated}
    Product Should Exist With Data    ${product}[_id]    ${changes}

PRD-05 Product Not In A Cart Is Deleted
    [Tags]    PRD-05    positive    priority:high
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]

    ${response}=    DELETE Product    ${product}[_id]    ${admin}[token]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.deleted}
    ${lookup}=    GET Product By Id    ${product}[_id]
    Request Should Fail With    ${lookup}    400    ${MSG.products.not_found}

PRD-09 Duplicate Product Name Is Rejected
    [Tags]    PRD-09    negative    priority:high
    ${admin}=    Create Admin With Token
    ${existing}=    Admin Creates Product    ${admin}[token]
    ${other}=    Admin Creates Product    ${admin}[token]
    ${same_name}=    Generate Product    nome=${existing}[nome]

    ${on_create}=    POST Product    ${same_name}    ${admin}[token]
    Register Response For Cleanup    product    ${on_create}    ${admin}[token]
    ${on_rename}=    PUT Product    ${other}[_id]    ${same_name}    ${admin}[token]

    Request Should Fail With    ${on_create}    400    ${MSG.products.name_taken}
    Request Should Fail With    ${on_rename}    400    ${MSG.products.name_taken}
    Product Should Exist With Data    ${other}[_id]    ${other}

PRD-11 Product In A Cart Can't Be Deleted
    [Tags]    PRD-11    negative    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    1
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    DELETE Product    ${product}[_id]    ${admin}[token]

    Request Should Fail With    ${response}    400    ${MSG.products.in_cart}
    Should Contain    ${response.json()}[idCarrinhos]    ${cart_id}
    Product Stock Should Be    ${product}[_id]    9

PRD-16 PUT Keeping The Same Name Is Not A Duplicate
    [Tags]    PRD-16    edge    priority:medium
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${changes}=    Generate Product    nome=${product}[nome]    preco=77

    ${response}=    PUT Product    ${product}[_id]    ${changes}    ${admin}[token]

    Status Should Be    200    ${response}
    Product Should Exist With Data    ${product}[_id]    ${changes}

PRD-17 PUT On An Unknown ID Creates A Product With A New ID
    [Tags]    PRD-17    edge    priority:low
    ${admin}=    Create Admin With Token
    ${payload}=    Generate Product

    ${response}=    PUT Product    aaaaaaaaaaaaaaaa    ${payload}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Should Not Be Equal    ${response.json()}[_id]    aaaaaaaaaaaaaaaa
    Product Should Exist With Data    ${response.json()}[_id]    ${payload}

PRD-18 Deleting An Unknown Product ID Is Harmless
    [Tags]    PRD-18    edge    priority:low
    ${admin}=    Create Admin With Token

    ${response}=    DELETE Product    aaaaaaaaaaaaaaaa    ${admin}[token]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.common.nothing_deleted}
