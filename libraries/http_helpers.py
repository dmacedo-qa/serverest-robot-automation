"""Helpers that keep secrets out of logs while still logging useful HTTP details.

RequestsLibrary logs full requests and responses, including passwords and Authorization
headers. ``Send Request`` (resources/common/http.resource) silences that output and calls
``Log Exchange`` instead, which logs the same information with sensitive values masked.
"""

import json

from robot.api import logger
from robot.api.deco import keyword, library
from robot.api.types import Secret

SENSITIVE_FIELDS = {"password", "authorization"}
MASK = "***"


@library(scope="GLOBAL", auto_keywords=False)
class HttpHelpers:

    @keyword
    def auth_headers(self, token: Secret | str | None = None, extra: dict | None = None) -> dict:
        """Returns request headers: ``Authorization`` when a token is given, plus ``extra``."""
        headers = dict(extra or {})
        if token is not None:
            headers["Authorization"] = token.value if isinstance(token, Secret) else token
        return headers

    @keyword
    def reveal_secrets(self, data):
        """Returns a copy of ``data`` with every ``Secret`` replaced by its real value."""
        if isinstance(data, Secret):
            return data.value
        if isinstance(data, dict):
            return {key: self.reveal_secrets(value) for key, value in data.items()}
        if isinstance(data, (list, tuple)):
            return [self.reveal_secrets(value) for value in data]
        return data

    @keyword
    def extract_token(self, response) -> Secret:
        """Returns the ``authorization`` value of a login response as a ``Secret``."""
        return Secret(response.json()["authorization"])

    @keyword
    def log_exchange(self, response):
        """Logs method, URL, status, and both bodies, with sensitive fields masked."""
        request = response.request
        elapsed_ms = int(response.elapsed.total_seconds() * 1000)
        lines = [f"{request.method} {request.url} → {response.status_code} ({elapsed_ms} ms)"]
        if request.headers.get("Authorization"):
            lines.append(f"Authorization: {MASK}")
        if request.body:
            lines.append("Request body: " + _masked_json(request.body))
        if response.content:
            lines.append("Response body: " + _masked_json(response.content))
        logger.info("\n".join(lines))


def _masked_json(raw) -> str:
    try:
        data = json.loads(raw)
    except (TypeError, ValueError):
        return "<non-JSON body>"
    return json.dumps(_mask(data), ensure_ascii=False, indent=2)


def _mask(data):
    if isinstance(data, dict):
        return {key: MASK if key.lower() in SENSITIVE_FIELDS else _mask(value) for key, value in data.items()}
    if isinstance(data, list):
        return [_mask(value) for value in data]
    return data
