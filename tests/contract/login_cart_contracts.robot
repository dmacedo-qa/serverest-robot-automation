*** Settings ***
Documentation       Response contracts for /login and /carrinhos.

Resource            ../../resources/main.resource


*** Test Cases ***
CON-01 Login Responses Match Their Contracts
    [Tags]    CON-01    contract    priority:high
    ${user}=    Register User

    ${success}=    POST Login    ${user}[email]    ${user}[password]
    ${wrong_password}=    POST Login    ${user}[email]    wrong-password
    ${invalid_body}=    POST Login    not-an-email    ${EMPTY}

    Response Should Be    ${success}    200    login_success
    Response Should Be    ${wrong_password}    401    message
    Response Should Be    ${invalid_body}    400    validation_error

CON-08 Cart List Matches Its Contract
    [Tags]    CON-08    contract    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}

    ${listed}=    GET Carts    idUsuario=${customer}[_id]
    ${invalid}=    GET Carts    precoTotal=0

    Response Should Be    ${listed}    200    cart_list
    Response Should Be    ${invalid}    400    validation_error

CON-09 Cart Lookup Matches Its Contract
    [Tags]    CON-09    contract    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=5
    ${items}=    Cart Items    ${product}[_id]    2
    ${cart_id}=    Customer Creates Cart    ${customer}[token]    ${items}

    ${found}=    GET Cart By Id    ${cart_id}
    ${not_found}=    GET Cart By Id    aaaaaaaaaaaaaaaa

    Response Should Be    ${found}    200    cart
    Response Should Be    ${not_found}    400    message

CON-10 Cart Creation Responses Match Their Contracts
    [Tags]    CON-10    contract    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=2
    ${too_many}=    Cart Items    ${product}[_id]    3
    ${unknown}=    Cart Items    aaaaaaaaaaaaaaaa    1
    ${twice}=    Cart Items    ${product}[_id]    1    ${product}[_id]    1
    ${valid}=    Cart Items    ${product}[_id]    1

    ${insufficient}=    POST Cart    ${too_many}    ${customer}[token]
    ${not_found}=    POST Cart    ${unknown}    ${customer}[token]
    ${duplicate}=    POST Cart    ${twice}    ${customer}[token]
    ${created}=    POST Cart    ${valid}    ${customer}[token]
    Register Response For Cleanup    cart    ${created}    ${customer}[token]
    ${second}=    POST Cart    ${valid}    ${customer}[token]

    Response Should Be    ${insufficient}    400    cart_item_error
    Response Should Be    ${not_found}    400    cart_item_error
    Response Should Be    ${duplicate}    400    cart_duplicate
    Response Should Be    ${created}    201    created
    Response Should Be    ${second}    400    message

CON-11 Purchase Responses Match Their Contracts
    [Tags]    CON-11    contract    priority:medium
    ${customer}=    Create Customer With Token

    ${conclude}=    DELETE Cart To Conclude Purchase    ${customer}[token]
    ${cancel}=    DELETE Cart To Cancel Purchase    ${customer}[token]
    ${anonymous}=    DELETE Cart To Cancel Purchase

    Response Should Be    ${conclude}    200    message
    Response Should Be    ${cancel}    200    message
    Response Should Be    ${anonymous}    401    message
