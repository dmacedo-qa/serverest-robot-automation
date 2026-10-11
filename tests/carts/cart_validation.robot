*** Settings ***
Documentation       Carts: requests that must be refused, and proof that a refused cart reserves
...                 nothing.

Resource            ../../resources/main.resource


*** Test Cases ***
CRT-10 Invalid Cart Body Is Rejected And Stock Is Untouched
    [Documentation]    ``{id}`` in a row is replaced by a real product with 10 in stock.
    [Tags]    CRT-10    negative    priority:high
    [Template]    Cart Body Should Be Rejected
    # field                   produtos (JSON, {id} = real product)                       rule
    produtos                  []                                                         one_required
    produtos                  "not a list"                                               array
    produtos[0].idProduto     [{"quantidade": 1}]                                        required
    produtos[0].quantidade    [{"idProduto": "{id}"}]                                    required
    produtos[0].quantidade    [{"idProduto": "{id}", "quantidade": 0}]                   positive_number
    produtos[0].quantidade    [{"idProduto": "{id}", "quantidade": -1}]                  positive_number
    produtos[0].quantidade    [{"idProduto": "{id}", "quantidade": 1.5}]                 integer
    produtos[0].desconto      [{"idProduto": "{id}", "quantidade": 1, "desconto": 5}]    not_allowed

CRT-11 Unknown Product Rejects The Whole Cart
    [Tags]    CRT-11    negative    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10

    ${items}=    Cart Items    ${product}[_id]    2    aaaaaaaaaaaaaaaa    1
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.products.not_found}
    Should Be Equal As Integers    ${response.json()}[item][index]    1
    Product Stock Should Be    ${product}[_id]    10

CRT-13 Same Product Twice In A Row Is Rejected
    [Tags]    CRT-13    negative    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10

    ${items}=    Cart Items    ${product}[_id]    1    ${product}[_id]    1
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.carts.duplicate_product}
    Should Contain    ${response.json()}[idProdutosDuplicados]    ${product}[_id]
    Product Stock Should Be    ${product}[_id]    10

CRT-14 Cart Routes Require A Token
    [Tags]    CRT-14    negative    priority:high
    [Template]    Cart Route Without Token Should Be Refused
    create
    conclude
    cancel

CRT-20 Product With Zero Stock Can't Be Added
    [Tags]    CRT-20    edge    priority:medium
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=0

    ${items}=    Cart Items    ${product}[_id]    1
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.carts.insufficient_stock}
    Product Stock Should Be    ${product}[_id]    0

CRT-22 Quantity One Above Stock Is Rejected
    [Documentation]    Boundary next to CRT-08 (quantity equal to stock is accepted).
    [Tags]    CRT-22    edge    priority:high
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=5

    ${items}=    Cart Items    ${product}[_id]    6
    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Request Should Fail With    ${response}    400    ${MSG.carts.insufficient_stock}
    Product Stock Should Be    ${product}[_id]    5

DQ-06 Quantity Sent As Text Is Rejected
    [Tags]    DQ-06    negative    priority:low    known-defect
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${items}=    Evaluate    [{'idProduto': $product['_id'], 'quantidade': '2'}]

    ${response}=    POST Cart    ${items}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Status Should Be    400    ${response}    msg=quantidade "2" (a string) was accepted


*** Keywords ***
Cart Body Should Be Rejected
    [Documentation]    Sends ``produtos`` built from a JSON template and checks the field error,
    ...    that no cart was created, and that stock didn't move.
    [Arguments]    ${field}    ${produtos_template}    ${rule}
    ${admin}=    Create Admin With Token
    ${customer}=    Create Customer With Token
    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=10
    ${produtos}=    Evaluate    json.loads($produtos_template.replace('{id}', $product['_id']))    modules=json

    ${response}=    POST Cart    ${produtos}    ${customer}[token]
    Register Response For Cleanup    cart    ${response}    ${customer}[token]

    Response Should Have Field Error    ${response}    ${field}    ${rule}
    User Should Have No Cart    ${customer}[_id]
    Product Stock Should Be    ${product}[_id]    10

Cart Route Without Token Should Be Refused
    [Documentation]    Calls one cart route with no Authorization header.
    [Arguments]    ${action}
    IF    $action == 'create'
        ${items}=    Cart Items    aaaaaaaaaaaaaaaa    1
        ${response}=    POST Cart    ${items}
    ELSE IF    $action == 'conclude'
        ${response}=    DELETE Cart To Conclude Purchase
    ELSE
        ${response}=    DELETE Cart To Cancel Purchase
    END
    Request Should Fail With    ${response}    401    ${MSG.auth.token_invalid}
