*** Settings ***
Documentation       Test data and cleanup libraries, imported in one place so every suite shares
...                 the same instances (one seed, one run ID, one cleanup registry per process).

Library             libraries.data_factory.DataFactory    ${DATA_LOCALE}
Library             libraries.cleanup_registry.CleanupRegistry
Variables           ../../data/messages.yaml
