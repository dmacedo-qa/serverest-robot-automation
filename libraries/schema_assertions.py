"""Validates JSON responses against the schemas in data/schemas/."""

import json
from pathlib import Path

from jsonschema import Draft202012Validator
from robot.api import logger
from robot.api.deco import keyword, library

SCHEMA_DIR = Path(__file__).resolve().parent.parent / "data" / "schemas"
SENSITIVE_FIELDS = {"password", "authorization"}


@library(scope="GLOBAL", auto_keywords=False)
class SchemaAssertions:

    @keyword
    def response_should_match_schema(self, response, schema_name: str):
        """Fails with every violation listed if the response body doesn't match the schema."""
        schema = json.loads((SCHEMA_DIR / f"{schema_name}.json").read_text(encoding="utf-8"))
        validator = Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER)
        errors = sorted(validator.iter_errors(response.json()), key=lambda error: list(error.path))
        if errors:
            details = "\n".join(f"- {'/'.join(map(str, e.path)) or '(root)'}: {_describe(e)}" for e in errors)
            raise AssertionError(f"Response doesn't match schema '{schema_name}':\n{details}")
        logger.info(f"Response matches schema '{schema_name}'")


def _describe(error) -> str:
    """jsonschema messages quote the offending value; never quote a password or token."""
    if SENSITIVE_FIELDS & {str(part).lower() for part in error.path}:
        return f"failed '{error.validator}' check (value hidden)"
    return error.message
