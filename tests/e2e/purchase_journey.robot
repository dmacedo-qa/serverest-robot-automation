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
