*** Settings ***
Documentation       Assertions that read state back from the API.

Library             RequestsLibrary
Library             libraries.record_assertions.RecordAssertions
Resource            ../api/users.resource
Resource            ../api/products.resource
Resource            ../api/carts.resource


*** Keywords ***
User Should Exist With Data
    [Documentation]    Reads the user by ID and checks every field of ``expected``.
    [Arguments]    ${user_id}    ${expected}
    ${response}=    GET User By Id    ${user_id}
    Status Should Be    200    ${response}
    Record Should Match Payload    ${response.json()}    ${expected}

Product Should Exist With Data
    [Documentation]    Reads the product by ID and checks every field of ``expected``.
    [Arguments]    ${product_id}    ${expected}
    ${response}=    GET Product By Id    ${product_id}
    Status Should Be    200    ${response}
    Record Should Match Payload    ${response.json()}    ${expected}

Product Stock Should Be
    [Documentation]    Reads the product and checks its ``quantidade``.
    [Arguments]    ${product_id}    ${expected}
    ${response}=    GET Product By Id    ${product_id}
    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    ${expected}
    ...    msg=Stock of product ${product_id}

Cart Totals Should Be
    [Documentation]    Reads the cart and checks ``precoTotal`` and ``quantidadeTotal``.
    [Arguments]    ${cart_id}    ${preco_total}    ${quantidade_total}
    ${response}=    GET Cart By Id    ${cart_id}
    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[precoTotal]    ${preco_total}    msg=precoTotal
    Should Be Equal As Integers    ${response.json()}[quantidadeTotal]    ${quantidade_total}    msg=quantidadeTotal

User Should Have No Cart
    [Documentation]    Checks that no cart is linked to the user.
    [Arguments]    ${user_id}
    ${response}=    GET Carts    idUsuario=${user_id}
    Status Should Be    200    ${response}
    Should Be Equal As Integers    ${response.json()}[quantidade]    0    msg=Carts of user ${user_id}
