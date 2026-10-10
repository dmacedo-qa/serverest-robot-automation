*** Settings ***
Documentation       Endpoint keywords for /produtos. One HTTP call each, no assertions.
...                 Writes need an admin token. Reads are public.

Resource            ../common/http.resource


*** Variables ***
${PRODUCTS_PATH}    /produtos


*** Keywords ***
POST Product
    [Documentation]    Sends POST /produtos with the given payload.
    [Arguments]    ${payload}    ${token}=${NONE}
    ${response}=    Send Request    POST    ${PRODUCTS_PATH}    token=${token}    json=${payload}
    RETURN    ${response}

GET Products
    [Documentation]    Sends GET /produtos. Named arguments become query filters, e.g. ``preco=100``.
    [Arguments]    &{filters}
    ${response}=    Send Request    GET    ${PRODUCTS_PATH}    params=${filters}
    RETURN    ${response}

GET Product By Id
    [Documentation]    Sends GET /produtos/{id}.
    [Arguments]    ${product_id}
    ${response}=    Send Request    GET    ${PRODUCTS_PATH}/${product_id}
    RETURN    ${response}

PUT Product
    [Documentation]    Sends PUT /produtos/{id}. Creates the product if the ID doesn't exist (upsert).
    [Arguments]    ${product_id}    ${payload}    ${token}=${NONE}
    ${response}=    Send Request    PUT    ${PRODUCTS_PATH}/${product_id}    token=${token}    json=${payload}
    RETURN    ${response}

DELETE Product
    [Documentation]    Sends DELETE /produtos/{id}.
    [Arguments]    ${product_id}    ${token}=${NONE}
    ${response}=    Send Request    DELETE    ${PRODUCTS_PATH}/${product_id}    token=${token}
    RETURN    ${response}
