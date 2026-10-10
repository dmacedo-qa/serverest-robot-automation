"""Assertions that compare API records with the payloads that created them."""

from robot.api import logger
from robot.api.deco import keyword, library
from robot.api.types import Secret

MASK = "***"
CLIENT_ONLY_FIELDS = {"token"}  # added by flows, never part of an API record


@library(scope="GLOBAL", auto_keywords=False)
class RecordAssertions:

    @keyword
    def record_should_match_payload(self, record: dict, payload: dict):
        """Fails if any payload field is missing from ``record`` or has a different value.

        ``Secret`` values in the payload are compared by their real value, but failure
        messages never show them.
        """
        differences = []
        fields = [field for field in payload if field not in CLIENT_ONLY_FIELDS]
        for field in fields:
            expected = payload[field]
            is_secret = isinstance(expected, Secret)
            expected_value = expected.value if is_secret else expected
            if field not in record:
                differences.append(f"'{field}' is missing")
            elif record[field] != expected_value:
                shown_expected = MASK if is_secret else repr(expected_value)
                shown_actual = MASK if is_secret else repr(record[field])
                differences.append(f"'{field}' is {shown_actual}, expected {shown_expected}")
        if differences:
            raise AssertionError("Record does not match payload:\n- " + "\n- ".join(differences))
        logger.info(f"Record matches payload fields: {', '.join(fields)}")
