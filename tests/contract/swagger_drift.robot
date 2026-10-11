*** Settings ***
Documentation       Swagger drift: compares the spec served by the running instance
...                 (GET /swagger.json) with what the API actually does. All four differ in
...                 ServeRest 3.2.2 and are tagged known-defect.

Resource            ../../resources/main.resource


*** Test Cases ***
DRIFT-01 Documented Error Field Matches The Response
    [Documentation]    Deleting a product that is in a cart: which field holds the cart IDs?
    [Tags]    DRIFT-01    contract    priority:medium    known-defect
    ${spec}=    GET Swagger
    ${documented}=    Evaluate
    ...    sorted($spec.json()['components']['schemas']['naoPermitidoExcluirProdutoDeCarrinho']['properties'])
    ${response}=    Try To Delete A Product In A Cart

    ${returned}=    Evaluate    sorted($response.json())
    Lists Should Be Equal    ${returned}    ${documented}
    ...    msg=Swagger documents ${documented}, the API returns ${returned}

DRIFT-02 Every Accepted Product Field Is Documented
    [Tags]    DRIFT-02    contract    priority:low    known-defect
    ${spec}=    GET Swagger
    ${documented}=    Evaluate
    ...    list($spec.json()['components']['schemas']['requestBodyProduto']['properties'])
    ${admin}=    Create Admin With Token
    ${product}=    Generate Product
    Set To Dictionary    ${product}    imagem=https://example.com/mouse.png

    ${response}=    POST Product    ${product}    ${admin}[token]
    Register Response For Cleanup    product    ${response}    ${admin}[token]

    Status Should Be    201    ${response}
    Should Contain    ${documented}    imagem
    ...    msg=The API accepts and stores "imagem", but the Swagger doesn't list it

DRIFT-03 Documented Filter Limits Match The API
    [Tags]    DRIFT-03    contract    priority:low    known-defect
    ${spec}=    GET Swagger
    ${minimum}=    Evaluate
    ...    $spec.json()['components']['parameters']['quantidadeTotal']['schema']['minimum']

    ${response}=    GET Carts    quantidadeTotal=${minimum}

    Status Should Be    200    ${response}
    ...    msg=Swagger says quantidadeTotal >= ${minimum}, but the API rejects ${minimum}

DRIFT-04 Every Returned Status Code Is Documented
    [Tags]    DRIFT-04    contract    priority:low    known-defect
    ${spec}=    GET Swagger
    ${documented}=    Evaluate
    ...    sorted({c for path in $spec.json()['paths'].values() for op in path.values() for c in op['responses']})
    ${not_allowed}=    Send Raw Request    GET    /pedidos
    ${body}=    Evaluate    '{"email": "' + 'x' * 120000 + '"}'
    ${too_large}=    Send Raw Request    POST    /login    ${body}

    VAR    @{returned}    ${{ str($not_allowed.status_code) }}    ${{ str($too_large.status_code) }}
    FOR    ${status}    IN    @{returned}
        Should Contain    ${documented}    ${status}
        ...    msg=The API returns ${status}, which the Swagger documents nowhere (${documented})
    END
