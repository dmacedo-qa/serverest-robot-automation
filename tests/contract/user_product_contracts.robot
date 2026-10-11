*** Settings ***
Documentation       Response contracts for /usuarios and /produtos.

Resource            ../../resources/main.resource


*** Test Cases ***
CON-02 User List Matches Its Contract
    [Tags]    CON-02    contract    priority:high
    Register User

    ${listed}=    GET Users
    ${invalid}=    GET Users    email=not-an-email

    Response Should Be    ${listed}    200    user_list
    Response Should Be    ${invalid}    400    validation_error

CON-03 User Lookup Matches Its Contract
    [Tags]    CON-03    contract    priority:high
    ${user}=    Register User

    ${found}=    GET User By Id    ${user}[_id]
    ${unknown}=    GET User By Id    aaaaaaaaaaaaaaaa
    ${malformed}=    GET User By Id    abc

    Response Should Be    ${found}    200    user
    Response Should Be    ${unknown}    400    message
    Response Should Be    ${malformed}    400    validation_error

CON-04 User Write Responses Match Their Contracts
    [Tags]    CON-04    contract    priority:high
    ${payload}=    Generate User
    ${created}=    POST User    ${payload}
    Register Response For Cleanup    user    ${created}
    ${duplicate}=    POST User    ${payload}
    ${changes}=    Generate User
    ${updated}=    PUT User    ${created.json()}[_id]    ${changes}
    ${deleted}=    DELETE User    ${created.json()}[_id]
    ${with_cart}=    Try To Delete A User With A Cart

    Response Should Be    ${created}    201    created
    Response Should Be    ${duplicate}    400    message
    Response Should Be    ${updated}    200    message
    Response Should Be    ${deleted}    200    message
    Response Should Be    ${with_cart}    400    user_has_cart

CON-05 Product List Matches Its Contract
    [Tags]    CON-05    contract    priority:high
    ${admin}=    Create Admin With Token
    Admin Creates Product    ${admin}[token]

    ${listed}=    GET Products
    ${invalid}=    GET Products    preco=0

    Response Should Be    ${listed}    200    product_list
    Response Should Be    ${invalid}    400    validation_error

CON-06 Product Lookup Matches Its Contract
    [Tags]    CON-06    contract    priority:high
    ${admin}=    Create Admin With Token
    ${product}=    Admin Creates Product    ${admin}[token]

    ${found}=    GET Product By Id    ${product}[_id]
    ${unknown}=    GET Product By Id    aaaaaaaaaaaaaaaa

    Response Should Be    ${found}    200    product
    Response Should Be    ${unknown}    400    message

CON-07 Product Write Responses Match Their Contracts
    [Tags]    CON-07    contract    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${payload}=    Generate Product
    ${created}=    POST Product    ${payload}    ${admin}[token]
    Register Response For Cleanup    product    ${created}    ${admin}[token]
    ${duplicate}=    POST Product    ${payload}    ${admin}[token]
    ${anonymous}=    POST Product    ${payload}
    ${forbidden}=    POST Product    ${payload}    ${customer}[token]
    ${changes}=    Generate Product
    ${updated}=    PUT Product    ${created.json()}[_id]    ${changes}    ${admin}[token]
    ${deleted}=    DELETE Product    ${created.json()}[_id]    ${admin}[token]
    ${in_cart}=    Try To Delete A Product In A Cart

    Response Should Be    ${created}    201    created
    Response Should Be    ${duplicate}    400    message
    Response Should Be    ${anonymous}    401    message
    Response Should Be    ${forbidden}    403    message
    Response Should Be    ${updated}    200    message
    Response Should Be    ${deleted}    200    message
    Response Should Be    ${in_cart}    400    product_in_cart
