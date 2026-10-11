"""Builds invalid variants of a real ServeRest token for the token-validation tests."""

import base64
import hashlib
import hmac
import json

from robot.api.deco import keyword, library
from robot.api.types import Secret


@library(scope="GLOBAL", auto_keywords=False)
class JwtTools:

    @keyword
    def forge_token(self, token: Secret, mode: str) -> Secret:
        """Returns ``Bearer <jwt>`` derived from ``token``.

        ``wrong_key``: same header and payload, signed with a key ServeRest doesn't know.
        ``alg_none``: unsigned token that declares ``"alg": "none"``.
        ``tampered``: email in the payload replaced, original signature kept.
        """
        header, payload, signature = token.value.split(" ", 1)[1].split(".")
        claims = _decode(payload)
        if mode == "wrong_key":
            unsigned = f"{header}.{payload}"
            signature = _b64(hmac.new(b"not-the-server-key", unsigned.encode(), hashlib.sha256).digest())
            jwt = f"{unsigned}.{signature}"
        elif mode == "alg_none":
            jwt = f"{_b64_json({'alg': 'none', 'typ': 'JWT'})}.{payload}."
        elif mode == "tampered":
            claims["email"] = "someone.else@example.com"
            jwt = f"{header}.{_b64_json(claims)}.{signature}"
        else:
            raise ValueError(f"Unknown mode '{mode}'. Use wrong_key, alg_none, or tampered.")
        return Secret(f"Bearer {jwt}")

    @keyword
    def authorization_header_from_template(self, token: Secret, template: str) -> Secret:
        """Fills ``{jwt}`` in ``template`` with the raw JWT of ``token``, e.g. ``bearer {jwt}``."""
        return Secret(template.replace("{jwt}", token.value.split(" ", 1)[1]))

    @keyword
    def token_payload_fields(self, token: Secret) -> list[str]:
        """Returns the names of the claims in the token payload, never their values."""
        payload = token.value.split(" ", 1)[1].split(".")[1]
        return sorted(_decode(payload))


def _b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def _b64_json(data: dict) -> str:
    return _b64(json.dumps(data, separators=(",", ":")).encode())


def _decode(segment: str) -> dict:
    return json.loads(base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4)))
