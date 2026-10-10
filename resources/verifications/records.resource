*** Settings ***
Documentation       Assertions that read a record back from the API and compare it with what was sent.

Library             RequestsLibrary
Library             libraries.record_assertions.RecordAssertions
Resource            ../api/users.resource
Resource            ../api/products.resource


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
