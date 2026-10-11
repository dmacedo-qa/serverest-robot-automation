"""Tracks the records each test or suite creates, so teardown can delete them.

Records are registered in the scope where they were created: a test, or any suite setup.
``Pop Cleanup Items`` returns them in the order ServeRest allows them to be deleted:
carts first (they lock users and products), then products, then users. Within each kind,
the most recent record comes first.
"""

from robot.api import logger
from robot.api.deco import keyword, library
from robot.api.types import Secret
from robot.libraries.BuiltIn import BuiltIn

DELETE_ORDER = {"cart": 0, "product": 1, "user": 2}


@library(scope="GLOBAL", auto_keywords=False)
class CleanupRegistry:

    def __init__(self):
        self._items: dict[str, list[dict]] = {}

    @keyword
    def register_for_cleanup(self, kind: str, resource_id: str, token: Secret | None = None):
        """Registers a created record. ``token`` is the one needed to delete it, if any."""
        if kind not in DELETE_ORDER:
            raise ValueError(f"Unknown kind '{kind}'. Expected one of: {', '.join(DELETE_ORDER)}")
        self._items.setdefault(self._current_scope(), []).append(
            {"kind": kind, "id": resource_id, "token": token}
        )
        logger.info(f"Registered {kind} {resource_id} for cleanup")

    @keyword
    def register_response_for_cleanup(self, kind: str, response, token: Secret | None = None):
        """Registers the record a create request produced, if it produced one.

        Call it right after the request and before any assertion. That way the record is
        cleaned up even when a later step fails, or when a negative test unexpectedly
        creates a record because of an API defect.
        """
        try:
            resource_id = response.json().get("_id")
        except (ValueError, AttributeError):
            resource_id = None
        if resource_id:
            self.register_for_cleanup(kind, resource_id, token)

    @keyword
    def pop_cleanup_items(self) -> list[dict]:
        """Removes and returns the current scope's records, in safe deletion order."""
        items = self._items.pop(self._current_scope(), [])
        newest_first = list(reversed(items))
        return sorted(newest_first, key=lambda item: DELETE_ORDER[item["kind"]])

    @staticmethod
    def _current_scope() -> str:
        """Records created inside a test belong to that test. Records created in any suite
        setup share one bucket, emptied by the root suite teardown (tests/__init__.robot)."""
        variables = BuiltIn()
        test = variables.get_variable_value("${TEST NAME}")
        suite = variables.get_variable_value("${SUITE NAME}")
        return f"test:{suite}.{test}" if test else "suite"
