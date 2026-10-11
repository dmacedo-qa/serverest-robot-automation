*** Settings ***
Documentation       Response contracts for login and carts. Schemas are strict: required fields,
...                 types, ``_id`` format, and no unexpected fields.

Resource            ../../resources/main.resource


*** Test Cases ***
CON-01 Login Responses Match Their Contracts
    [Tags]    CON-01    contract    priority:high
    ${user}=    Register User

    ${success}=    POST Login    ${user}[email]    ${user}[password]
    ${wrong_password}=    POST Login    ${user}[email]    wrong-password
    ${invalid_body}=    POST Login    not-an-email    ${EMPTY}

    Status Should Be    200    ${success}
    Response Should Match Schema    ${success}    login_success
    Status Should Be    401    ${wrong_password}
    Response Should Match Schema    ${wrong_password}    message
    Status Should Be    400    ${invalid_body}
    Response Should Match Schema    ${invalid_body}    validation_error

CON-09 Cart Responses Match Their Contracts
    [Tags]    CON-09    contract    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=5
    ${items}=    Cart Items    ${product}[_id]    2
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${found}=    GET Cart By Id    ${cart_id}
    ${not_found}=    GET Cart By Id    aaaaaaaaaaaaaaaa

    Status Should Be    200    ${found}
    Response Should Match Schema    ${found}    cart
    Status Should Be    400    ${not_found}
    Response Should Match Schema    ${not_found}    message
