*** Settings ***
Documentation       Single entry point for every HTTP call to ServeRest.
...
...                 RequestsLibrary logs full requests and responses, including passwords and the
...                 Authorization header. This keyword silences that output during the call and logs
...                 a masked summary instead (method, URL, status, time, bodies).

Library             RequestsLibrary
Library             libraries.http_helpers.HttpHelpers


*** Variables ***
${SESSION}      serverest


*** Keywords ***
Send Request
    [Documentation]    Sends one request on the ServeRest session and returns the response,
    ...    whatever its status. ``token`` and any ``Secret`` inside ``json`` are revealed only
    ...    while the log is silenced.
    [Arguments]    ${method}    ${path}    ${token}=${NONE}    ${json}=${NONE}    ${params}=${NONE}
    ${previous_level}=    Set Log Level    WARN
    TRY
        ${headers}=    Auth Headers    ${token}
        ${body}=    Reveal Secrets    ${json}
        ${response}=    Run Keyword    ${method} On Session    ${SESSION}    ${path}
        ...    json=${body}    params=${params}    headers=${headers}    expected_status=anything
    FINALLY
        Set Log Level    ${previous_level}
    END
    Log Exchange    ${response}
    RETURN    ${response}
