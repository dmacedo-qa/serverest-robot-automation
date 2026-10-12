*** Settings ***
Documentation       Products: creating a product with POST /produtos.

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-01 Admin Creates A Product That Is Retrievable By Id
    [Tags]    PRD-01    positive    priority:critical    smoke
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Response Message Should Be    ${response}    ${MSG.common.created}
    Product Should Exist With Data    ${response.json()}[_id]    ${product}

PRD-14 Price And Stock Boundaries
    [Documentation]    ``preco`` must be an integer from 1 to 2^53 - 1. ``quantidade`` may be 0.
    [Tags]    PRD-14    edge    priority:medium
    [Template]    Product Field Value Should Give
    # field        value                       status    rule
    preco          ${0}                        400       positive_number
    preco          ${1}                        201
    preco          ${9007199254740991}         201
    preco          ${9007199254740993}         400       max_safe_integer
    quantidade     ${-1}                       400       min_zero
    quantidade     ${0}                        201

PRD-06 Optional Image Field Is Stored Trimmed
    [Documentation]    ``imagem`` isn't in the Swagger (DRIFT-02), but the API accepts and returns it.
    [Tags]    PRD-06    positive    priority:low
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product
    Set To Dictionary    ${product}    imagem=${SPACE}https://example.com/mouse.png${SPACE}

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    ${stored}=    GET Product By Id    ${response.json()}[_id]
    Should Be Equal    ${stored.json()}[imagem]    https://example.com/mouse.png

PRD-10 Invalid Product Payload Is Rejected With A Field Message
    [Tags]    PRD-10    negative    priority:high
    [Template]    Product Payload Should Be Rejected
    # field         value            rule
    nome            <missing>        required
    preco           <missing>        required
    descricao       <missing>        required
    quantidade      <missing>        required
    nome            ${EMPTY}         blank
    descricao       ${EMPTY}         blank
    preco           ${-1}            positive_number
    preco           ${1.5}           integer
    preco           abc              number
    quantidade      ${1.5}           integer
    extra           unexpected       not_allowed

PRD-15 Surrounding Spaces Are Trimmed From The Name
    [Tags]    PRD-15    edge    priority:low
    ${admin}=    Create Admin With Token
    ${tag}=    Unique Tag
    ${padded}=    Admin Creates Product    ${admin}[token]    nome=${SPACE * 2}Mouse ${tag}${SPACE * 2}
    ${trimmed}=    Generate Product    nome=Mouse ${tag}

    ${stored}=    GET Product By Id    ${padded}[_id]
    ${duplicate}=    POST Product    ${trimmed}    ${admin}[token]
    Register Response For Cleanup    product    ${duplicate}    ${admin}[token]

    Should Be Equal    ${stored.json()}[nome]    Mouse ${tag}
    Request Should Fail With    ${duplicate}    400    ${MSG.products.name_taken}

PRD-19 Product With Zero Stock Can Be Created
    [Tags]    PRD-19    edge    priority:low
    ${admin}=    Create Admin With Token

    ${product}=    Admin Creates Product    ${admin}[token]    quantidade=0

    Product Stock Should Be    ${product}[_id]    0

DQ-02 Product Name Uniqueness Ignores Letter Case
    [Tags]    DQ-02    negative    priority:medium    known-defect
    ${admin}=    Create Admin With Token
    ${existing}=    Admin Creates Product    ${admin}[token]
    ${upper}=    Generate Product    nome=${{ $existing['nome'].upper() }}

    ${response}=    POST Product    ${upper}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    400    ${response}    msg=Same name in upper case created a second product
    Response Message Should Be    ${response}    ${MSG.products.name_taken}

DQ-03 Price Sent As Text Is Rejected
    [Documentation]    The API converts numeric strings instead of rejecting them.
    [Tags]    DQ-03    negative    priority:low    known-defect
    [Template]    Price As Text Should Be Rejected
    10
    1e2

DQ-05 Blank Product Name Is Rejected
    [Documentation]    ``"   "`` passes validation and is stored as an empty name.
    [Tags]    DQ-05    negative    priority:medium    known-defect
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product    nome=${SPACE * 3}

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    400    ${response}    msg=A name made only of spaces was accepted
    Response Should Have Field Error    ${response}    nome    blank


*** Keywords ***
Product Field Value Should Give
    [Documentation]    Creates a product with one field set to ``value``: expects a field error
    ...    when ``rule`` is given, otherwise ``status`` and the stored product.
    [Arguments]    ${field}    ${value}    ${status}    ${rule}=${NONE}
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product
    Set To Dictionary    ${product}    ${field}=${value}

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    IF    $rule
        Response Should Have Field Error    ${response}    ${field}    ${rule}
    ELSE
        Status Should Be    ${status}    ${response}
        Product Should Exist With Data    ${response.json()}[_id]    ${product}
    END

Product Payload Should Be Rejected
    [Documentation]    Removes or replaces one field of a valid product and checks the field error.
    [Arguments]    ${field}    ${value}    ${rule}
    ${admin}=    Create Admin With Token
    ${valid}=    Generate Product
    ${product}=    Payload With Field    ${valid}    ${field}    ${value}
    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]
    Response Should Have Field Error    ${response}    ${field}    ${rule}

Price As Text Should Be Rejected
    [Documentation]    Sends ``preco`` as a JSON string.
    [Arguments]    ${text}
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product
    Set To Dictionary    ${product}    preco=${text}
    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]
    Status Should Be    400    ${response}    msg=preco "${text}" (a string) was accepted
