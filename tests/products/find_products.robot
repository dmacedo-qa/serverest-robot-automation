*** Settings ***
Documentation       Products: listing, filtering, and reading by ID.
...                 Each test checks a single response, so parallel workers don't affect it.

Resource            ../../resources/main.resource


*** Test Cases ***
PRD-02 Product List Count Matches Its Content
    [Tags]    PRD-02    positive    priority:medium
    ${response}=    GET Products

    Status Should Be    200    ${response}
    ${listed}=    Get Length    ${response.json()}[produtos]
    Should Be Equal As Integers    ${response.json()}[quantidade]    ${listed}

PRD-03 Product Filters Return Only Matching Products
    [Documentation]    ``nome`` and ``descricao`` match partially and ignore case; ``preco`` and
    ...    ``quantidade`` match exactly.
    [Tags]    PRD-03    positive    priority:low
    [Template]    Product Filter Should Match
    nome
    descricao
    preco
    quantidade

PRD-12 Unknown Or Malformed Product ID Is Rejected
    [Tags]    PRD-12    negative    priority:medium
    ${unknown}=    GET Product By Id    aaaaaaaaaaaaaaaa
    ${malformed}=    GET Product By Id    abc

    Request Should Fail With    ${unknown}    400    ${MSG.products.not_found}
    Response Should Have Field Error    ${malformed}    id    sixteen_chars

PRD-13 Invalid Product Filters Are Rejected
    [Tags]    PRD-13    negative    priority:low
    [Template]    Product Filter Should Be Rejected
    # filter        value     rule
    preco           abc       number
    preco           0         positive_number
    quantidade      -1        min_zero
    categoria       mouse     not_allowed


*** Keywords ***
Product Filter Should Match
    [Documentation]    Creates a product, filters by one of its fields, and checks that it's in
    ...    the result and that every result matches the filter.
    [Arguments]    ${field}
    ${admin}=    Create Admin With Token
    ${tag}=    Unique Tag
    ${product}=    Admin Creates Product    ${admin}[token]
    ...    nome=Mouse ${tag}    descricao=Wireless ${tag} mouse    preco=4321    quantidade=17
    ${partial}=    Evaluate    $field in ('nome', 'descricao')
    VAR    ${value}    ${{ $tag.upper() if $partial else $product[$field] }}

    ${response}=    GET Products    ${field}=${value}

    Status Should Be    200    ${response}
    ${ids}=    Evaluate    [p['_id'] for p in $response.json()['produtos']]
    Should Contain    ${ids}    ${product}[_id]
    FOR    ${listed}    IN    @{response.json()}[produtos]
        IF    ${partial}
            Should Contain    ${listed}[${field}]    ${tag}    ignore_case=True
        ELSE
            Should Be Equal As Integers    ${listed}[${field}]    ${value}
        END
    END

Product Filter Should Be Rejected
    [Documentation]    GET /produtos with one invalid query filter.
    [Arguments]    ${filter}    ${value}    ${rule}
    ${response}=    GET Products    ${filter}=${value}
    Response Should Have Field Error    ${response}    ${filter}    ${rule}
