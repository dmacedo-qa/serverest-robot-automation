*** Settings ***
Documentation       Business steps for carts.

Library             RequestsLibrary
Resource            ../common/test_data.resource
Resource            ../api/carts.resource


*** Keywords ***
Customer Creates Cart
    [Documentation]    Creates a cart for the owner of ``token`` and registers it for cleanup
    ...    (cancelling it restores the stock). Returns the cart ID.
    [Arguments]    ${token}    ${items}
    ${response}=    POST Cart    ${items}    ${token}
    Register Response For Cleanup    cart    ${response}    ${token}
    Status Should Be    201    ${response}    msg=Setup failed: could not create cart
    RETURN    ${response.json()}[_id]
