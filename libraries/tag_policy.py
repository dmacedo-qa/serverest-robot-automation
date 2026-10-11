"""Pre-run modifier that enforces the tag taxonomy described in docs/test-plan.md.

Every test must have exactly one type tag, exactly one priority tag, and a test-case ID.
A test that breaks the rule fails immediately with a message saying what's missing, so a
test can never silently escape filters such as ``--include negative``.

Usage (already in config/robot.args):
    --prerunmodifier libraries/tag_policy.py
"""

import re

from robot.api import SuiteVisitor

TYPE_TAGS = {"positive", "negative", "edge", "contract", "security", "e2e"}
PRIORITY_TAGS = {"priority:critical", "priority:high", "priority:medium", "priority:low"}
ID_PATTERN = re.compile(r"^(AUTH|TOK|USR|PRD|CRT|PLT|CON|SEC|DQ|DRIFT|E2E)-\d{2}$")


class tag_policy(SuiteVisitor):

    def visit_test(self, test):
        tags = {str(tag).lower() for tag in test.tags}
        problems = []
        if len(tags & TYPE_TAGS) != 1:
            problems.append(f"exactly one type tag ({', '.join(sorted(TYPE_TAGS))})")
        if len(tags & PRIORITY_TAGS) != 1:
            problems.append(f"exactly one priority tag ({', '.join(sorted(PRIORITY_TAGS))})")
        if not any(ID_PATTERN.match(str(tag)) for tag in test.tags):
            problems.append("a test-case ID tag, e.g. USR-01")
        if problems:
            test.setup.config(name="Fail", args=("Tag policy: this test needs " + "; ".join(problems),))
