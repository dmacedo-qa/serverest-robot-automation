*** Settings ***
Documentation       Carts: reading by ID and listing with filters.

Resource            ../../resources/main.resource


*** Test Cases ***
CRT-02 Cart Details Show Unit Prices And The Owner
    [Tags]    CRT-02    positive    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    preco=120    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    2
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    GET Cart By Id    ${cart_id}

    Status Should Be    200    ${response}
    Should Be Equal    ${response.json()}[idUsuario]    ${customer}[_id]
    VAR    ${line}    ${response.json()}[produtos][0]
    Should Be Equal    ${line}[idProduto]    ${product}[_id]
    Should Be Equal As Integers    ${line}[quantidade]    2
    Should Be Equal As Integers    ${line}[precoUnitario]    120

CRT-03 Cart List Filtered By User Returns Only That User's Cart
    [Tags]    CRT-03    positive    priority:low
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${items}=    Cart Items    ${product}[_id]    1
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    GET Carts    idUsuario=${customer}[_id]

    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    1
    Should Be Equal    ${response.json()}[carrinhos][0][_id]    ${cart_id}

CRT-15 Unknown Or Malformed Cart ID Is Rejected
    [Tags]    CRT-15    negative    priority:medium
    ${unknown}=    GET Cart By Id    aaaaaaaaaaaaaaaa
    ${malformed}=    GET Cart By Id    abc

    Request Should Fail With    ${unknown}    400    ${MSG.carts.not_found}
    Response Should Have Field Error    ${malformed}    id    sixteen_chars

CRT-16 Invalid Cart Filters Are Rejected
    [Tags]    CRT-16    negative    priority:low
    [Template]    Filter Should Be Rejected
    # list endpoint    filter             value        rule
    GET Carts          precoTotal         0            positive_number
    GET Carts          precoTotal         abc          number
    GET Carts          quantidadeTotal    -1           positive_number
