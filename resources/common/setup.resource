*** Settings ***
Documentation       Suite and test setup/teardown shared by every suite.

Library             RequestsLibrary
Resource            http.resource
Resource            test_data.resource
Resource            ../api/users.resource
Resource            ../api/products.resource
Resource            ../api/carts.resource


*** Keywords ***
Start API Session
    [Documentation]    Opens the HTTP session and logs the seed and run ID of this run's test data.
    Create Session    ${SESSION}    ${BASE_URL}    timeout=${REQUEST_TIMEOUT}    verify=${VERIFY_SSL}
    Log Test Data Context

Use Short Token Instance
    [Documentation]    Sends the rest of the current test to the ServeRest instance whose tokens
    ...    expire after 5 seconds. Session setup and cleanup go to the same instance.
    Create Session    short-token    ${SHORT_TOKEN_BASE_URL}    timeout=${REQUEST_TIMEOUT}    verify=${VERIFY_SSL}
    VAR    ${SESSION}    short-token    scope=TEST    # robocop: off=no-test-variable

End API Session
    [Documentation]    Deletes records created in suite setup, then closes the session.
    Clean Up Test Data
    Delete All Sessions

Clean Up Test Data
    [Documentation]    Deletes what the current test (or suite) created: carts, then products,
    ...    then users. Best-effort: a failed delete is a warning and never changes the test result.
    @{items}=    Pop Cleanup Items
    IF    not ${CLEANUP_ENABLED}
        Log    Cleanup disabled. Leaving ${{len($items)}} record(s) in place.    WARN
        RETURN
    END
    FOR    ${item}    IN    @{items}
        TRY
            ${response}=    Delete Registered Item    ${item}
            IF    ${response.status_code} != 200
                Log    Cleanup of ${item}[kind] ${item}[id] returned ${response.status_code}.    WARN
            END
        EXCEPT    AS    ${error}
            Log    Cleanup of ${item}[kind] ${item}[id] failed: ${error}    WARN
        END
    END

Delete Registered Item
    [Documentation]    Deletes one registered record with the endpoint that matches its kind.
    [Arguments]    ${item}
    IF    $item['kind'] == 'cart'
        ${response}=    DELETE Cart To Cancel Purchase    ${item}[token]
    ELSE IF    $item['kind'] == 'product'
        ${response}=    DELETE Product    ${item}[id]    ${item}[token]
    ELSE
        ${response}=    DELETE User    ${item}[id]
    END
    RETURN    ${response}
