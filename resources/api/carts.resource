*** Settings ***
Documentation       Endpoint keywords for /carrinhos. One HTTP call each, no assertions.
...                 A cart belongs to the user of the token. Each user can have only one.

Resource            ../common/http.resource


*** Variables ***
${CARTS_PATH}       /carrinhos


*** Keywords ***
POST Cart
    [Documentation]    Sends POST /carrinhos. ``items`` is a list of ``{idProduto, quantidade}``.
    [Arguments]    ${items}    ${token}=${NONE}
    VAR    &{body}=    produtos=${items}
    ${response}=    Send Request    POST    ${CARTS_PATH}    token=${token}    json=${body}
    RETURN    ${response}

GET Carts
    [Documentation]    Sends GET /carrinhos. Named arguments become query filters, e.g. ``idUsuario=...``.
    [Arguments]    &{filters}
    ${response}=    Send Request    GET    ${CARTS_PATH}    params=${filters}
    RETURN    ${response}

GET Cart By Id
    [Documentation]    Sends GET /carrinhos/{id}.
    [Arguments]    ${cart_id}
    ${response}=    Send Request    GET    ${CARTS_PATH}/${cart_id}
    RETURN    ${response}

DELETE Cart To Conclude Purchase
    [Documentation]    Sends DELETE /carrinhos/concluir-compra. Stock stays reduced.
    [Arguments]    ${token}=${NONE}
    ${response}=    Send Request    DELETE    ${CARTS_PATH}/concluir-compra    token=${token}
    RETURN    ${response}

DELETE Cart To Cancel Purchase
    [Documentation]    Sends DELETE /carrinhos/cancelar-compra. Stock is restored.
    [Arguments]    ${token}=${NONE}
    ${response}=    Send Request    DELETE    ${CARTS_PATH}/cancelar-compra    token=${token}
    RETURN    ${response}
