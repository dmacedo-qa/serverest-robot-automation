*** Settings ***
Documentation       Carts: creation, totals, stock, and the conclude / cancel lifecycle.
...                 Every test uses products it created, so stock values are exact.

Resource            ../../resources/main.resource


*** Test Cases ***
CRT-01 Creating A Cart Reserves Stock And Calculates Totals
    [Tags]    CRT-01    positive    priority:critical    smoke
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${mouse}=    Admin Creates Product    ${admin}[token]    preco=100    quantidade=10
    ${pad}=    Admin Creates Product    ${admin}[token]    preco=30    quantidade=5

    ${items}=    Cart Items    ${mouse}[_id]    2    ${pad}[_id]    1
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    Cart Totals Should Be    ${cart_id}    preco_total=230    quantidade_total=3
    Product Stock Should Be    ${mouse}[_id]    8
    Product Stock Should Be    ${pad}[_id]    4

CRT-04 Concluding A Purchase Removes The Cart And Keeps Stock Reduced
    [Tags]    CRT-04    positive    priority:critical
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    3
    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    DELETE Cart To Conclude Purchase    ${customer}[token]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.carts.purchase_concluded}
    User Should Have No Cart    ${customer}[_id]
    Product Stock Should Be    ${product}[_id]    7

CRT-05 Cancelling A Purchase Removes The Cart And Restores Stock
    [Tags]    CRT-05    positive    priority:critical
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    3
    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Status Should Be    200    ${response}
    Response Message Should Be    ${response}    ${MSG.carts.purchase_cancelled}
    User Should Have No Cart    ${customer}[_id]
    Product Stock Should Be    ${product}[_id]    10

CRT-09 A User Can Have Only One Cart
    [Tags]    CRT-09    negative    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}

    ${response}=    POST Cart    ${items}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.carts.one_per_user}
    Product Stock Should Be    ${product}[_id]    9

CRT-12 Quantity Above Stock Is Rejected And Nothing Is Reserved
    [Tags]    CRT-12    negative    priority:critical
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=3

    ${items}=    Cart Items    ${product}[_id]    4
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.carts.insufficient_stock}
    Should Be Equal As Integers    ${response.json()}[item][quantidadeEstoque]    3
    Product Stock Should Be    ${product}[_id]    3
    User Should Have No Cart    ${customer}[_id]

DQ-07 Same Product Twice In A Cart Is Rejected Even When Not Adjacent
    [Documentation]    The duplicate check only compares neighboring lines. With ``[A, B, A]``,
    ...    ServeRest 3.2.2 accepts a cart holding 8 units of a product that has 5 in stock,
    ...    and only takes 4 out of stock.
    [Tags]    DQ-07    negative    priority:critical    known-defect
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product_a}=    Admin Creates Product    ${admin}[token]    quantidade=5
    ${product_b}=    Admin Creates Product    ${admin}[token]    quantidade=5

    ${items}=    Cart Items    ${product_a}[_id]    4    ${product_b}[_id]    1    ${product_a}[_id]    4
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Status Should Be    400    ${response}
    ...    msg=Cart accepted 8 units of a product with 5 in stock (duplicate lines not adjacent)
    Response Message Should Be    ${response}    ${MSG.carts.duplicate_product}
