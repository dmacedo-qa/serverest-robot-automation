*** Settings ***
Documentation       Business steps for carts.

Library             RequestsLibrary
Resource            ../common/test_data.resource
Resource            ../api/carts.resource
Resource            ../api/users.resource
Resource            ../api/products.resource
Resource            accounts.resource
Resource            catalog.resource


*** Keywords ***
Customer Creates Cart
    [Documentation]    Creates a cart for the owner of ``token`` and registers it for cleanup
    ...    (cancelling it restores the stock). Returns the cart ID.
    [Arguments]    ${token}    ${items}
    ${response}=    POST Cart    ${items}    ${token}
    Register Response For Cleanup    cart    ${response}    ${token}
    Status Should Be    201    ${response}    msg=Setup failed: could not create cart
    RETURN    ${response.json()}[_id]

Try To Delete A User With A Cart
    [Documentation]    Returns the response to deleting a customer who has an active cart.
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}
    ${response}=    DELETE User    ${customer}[_id]
    RETURN    ${response}

Try To Delete A Product In A Cart
    [Documentation]    Returns the response to deleting a product that is in an active cart.
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]
    ${items}=    Cart Items    ${product}[_id]    1
    Customer Creates Cart    ${customer}[token]    ${items}
    ${response}=    DELETE Product    ${product}[_id]    ${admin}[token]
    RETURN    ${response}
