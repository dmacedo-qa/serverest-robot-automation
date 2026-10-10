*** Settings ***
Documentation       Business steps for the product catalog. Setup steps that must succeed.

Library             Collections
Library             RequestsLibrary
Resource            ../common/test_data.resource
Resource            ../api/products.resource


*** Keywords ***
Admin Creates Product
    [Documentation]    Creates a product with generated data and registers it for cleanup.
    ...    Any field can be overridden, e.g. ``preco=100    quantidade=5``.
    ...    Returns the payload plus the ``_id`` ServeRest assigned.
    [Arguments]    ${admin_token}    &{overrides}
    ${product}=    Generate Product    &{overrides}
    ${response}=    POST Product    ${product}    ${admin_token}
    Register Response For Cleanup    product    ${response}    ${admin_token}
    Status Should Be    201    ${response}    msg=Setup failed: could not create product
    Set To Dictionary    ${product}    _id=${response.json()}[_id]
    RETURN    ${product}
