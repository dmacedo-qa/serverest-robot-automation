*** Settings ***
Documentation       End-to-end purchase journey, from an empty catalog to a concluded order.

Resource            ../../resources/main.resource


*** Test Cases ***
E2E-01 Customer Buys Two Products And Concludes The Purchase
    [Tags]    E2E-01    e2e    priority:critical    smoke
    ${admin}=    Create Admin With Token
    ${keyboard}=    Admin Creates Product    ${admin}[token]    preco=250    quantidade=4
    ${cable}=    Admin Creates Product    ${admin}[token]    preco=15    quantidade=20
    ${customer}=    Create Customer With Token

    ${items}=    Cart Items    ${keyboard}[_id]    1    ${cable}[_id]    3
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}
    Cart Totals Should Be    ${cart_id}    preco_total=295    quantidade_total=4
    Product Stock Should Be    ${keyboard}[_id]    3
    Product Stock Should Be    ${cable}[_id]    17

    ${response}=    DELETE Cart To Conclude Purchase    ${customer}[token]

    Status Should Be    200    ${response}
    User Should Have No Cart    ${customer}[_id]
    Product Stock Should Be    ${keyboard}[_id]    3
    Product Stock Should Be    ${cable}[_id]    17

E2E-02 Customer Cancels, Stock Is Restored, And The Account Can Be Deleted
    [Tags]    E2E-02    e2e    priority:high
    ${admin}=    Create Admin With Token
    ${keyboard}=    Admin Creates Product    ${admin}[token]    preco=250    quantidade=4
    ${cable}=    Admin Creates Product    ${admin}[token]    preco=15    quantidade=20
    ${customer}=    Create Customer With Token
    ${items}=    Cart Items    ${keyboard}[_id]    2    ${cable}[_id]    5
    Customer Creates Cart    ${customer}[token]    ${items}
    ${blocked}=    DELETE User    ${customer}[_id]
    Request Should Fail With    ${blocked}    400    ${MSG.users.has_cart}

    ${cancelled}=    DELETE Cart To Cancel Purchase    ${customer}[token]
    Status Should Be    200    ${cancelled}
    Product Stock Should Be    ${keyboard}[_id]    4
    Product Stock Should Be    ${cable}[_id]    20

    ${deleted}=    DELETE User    ${customer}[_id]
    Status Should Be    200    ${deleted}
    Response Message Should Be    ${deleted}    ${MSG.common.deleted}

E2E-03 Product Can Be Removed From The Catalog Only After The Order Is Done
    [Tags]    E2E-03    e2e    priority:high
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=3
    ${customer}=    Create Customer With Token
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}

    ${while_in_cart}=    DELETE Product    ${product}[_id]    ${admin}[token]
    Request Should Fail With    ${while_in_cart}    400    ${MSG.products.in_cart}

    ${concluded}=    DELETE Cart To Conclude Purchase    ${customer}[token]
    Status Should Be    200    ${concluded}

    ${after_purchase}=    DELETE Product    ${product}[_id]    ${admin}[token]
    Status Should Be    200    ${after_purchase}
    Response Message Should Be    ${after_purchase}    ${MSG.common.deleted}
