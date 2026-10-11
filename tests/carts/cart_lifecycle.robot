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

CRT-06 A New Cart Can Be Created After Concluding A Purchase
    [Tags]    CRT-06    positive    priority:medium
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}
    ${concluded}=    DELETE Cart To Conclude Purchase    ${customer}[token]
    Status Should Be    200    ${concluded}

    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Status Should Be    201    ${response}

CRT-07 An Admin Can Also Have A Cart
    [Tags]    CRT-07    positive    priority:low
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10

    ${items}=    Cart Items    ${product}[_id]    1
    ${cart_id}=    Customer Creates Cart    ${admin}[token]    ${items}

    ${response}=    GET Cart By Id    ${cart_id}
    Should Be Equal    ${response.json()}[idUsuario]    ${admin}[_id]

CRT-08 Buying Exactly The Remaining Stock Is Allowed
    [Tags]    CRT-08    positive    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=5

    ${items}=    Cart Items    ${product}[_id]    5
    Customer Creates Cart    ${customer}[token]    ${items}

    Product Stock Should Be    ${product}[_id]    0

CRT-17 Concluding Or Cancelling Without A Cart Is Harmless
    [Tags]    CRT-17    edge    priority:low
    ${customer}=    Create Customer With Token

    ${conclude}=    DELETE Cart To Conclude Purchase    ${customer}[token]
    ${cancel}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Status Should Be    200    ${conclude}
    Response Message Should Be    ${conclude}    ${MSG.carts.no_cart_for_user}
    Status Should Be    200    ${cancel}
    Response Message Should Be    ${cancel}    ${MSG.carts.no_cart_for_user}

CRT-18 Cart Keeps The Price From When It Was Created
    [Tags]    CRT-18    edge    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    preco=100    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    2
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${new_price}=    Generate Product    nome=${product}[nome]    preco=999    quantidade=8
    ${updated}=    PUT Product    ${product}[_id]    ${new_price}    ${admin}[token]
    Status Should Be    200    ${updated}

    Cart Totals Should Be    ${cart_id}    preco_total=200    quantidade_total=2
    ${cart}=    GET Cart By Id    ${cart_id}
    Should Be Equal As Integers    ${cart.json()}[produtos][0][precoUnitario]    100

CRT-19 Cancelling Adds The Reserved Quantity Back To The Current Stock
    [Documentation]    Stock is 10, the cart reserves 2 (stock 8), an admin sets stock to 50,
    ...    and the cancel adds the 2 back: 52.
    [Tags]    CRT-19    edge    priority:medium
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Cart Items    ${product}[_id]    2
    Customer Creates Cart    ${customer}[token]    ${items}
    ${restock}=    Generate Product    nome=${product}[nome]    preco=${product}[preco]    quantidade=50
    ${updated}=    PUT Product    ${product}[_id]    ${restock}    ${admin}[token]
    Status Should Be    200    ${updated}

    ${response}=    DELETE Cart To Cancel Purchase    ${customer}[token]

    Status Should Be    200    ${response}
    Product Stock Should Be    ${product}[_id]    52

CRT-21 Totals Are Right For A Cart With Ten Products
    [Tags]    CRT-21    edge    priority:medium
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    VAR    @{pairs}    @{EMPTY}
    FOR    ${price}    IN RANGE    1    11
        ${product}=    Admin Creates Product    ${admin}[token]    preco=${price}    quantidade=10
        Append To List    ${pairs}    ${product}[_id]    2
    END

    ${items}=    Cart Items    @{pairs}
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    Cart Totals Should Be    ${cart_id}    preco_total=110    quantidade_total=20

DQ-08 Stock Goes Down By Everything A Cart Holds
    [Documentation]    Follow-up to DQ-07: when ``[A, B, A]`` is accepted, stock must drop by both
    ...    lines of A. ServeRest 3.2.2 drops it by one line only, so the cart holds more units
    ...    than were ever in stock. Passes if the API rejects the cart instead.
    [Tags]    DQ-08    negative    priority:critical    known-defect
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product_a}=    Admin Creates Product    ${admin}[token]    quantidade=5
    ${product_b}=    Admin Creates Product    ${admin}[token]    quantidade=5

    ${items}=    Cart Items    ${product_a}[_id]    4    ${product_b}[_id]    1    ${product_a}[_id]    4
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    IF    ${response.status_code} == 201
        ${stock}=    GET Product By Id    ${product_a}[_id]
        ${removed}=    Evaluate    5 - $stock.json()['quantidade']
        Should Be Equal As Integers    ${removed}    8
        ...    msg=Cart holds 8 units of a product that had 5, but stock only dropped by ${removed}
    END
