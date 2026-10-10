"""Robot Framework variable file that loads environment settings.

Usage (already in config/robot.args):
    --variablefile libraries/config_loader.py

The environment comes from the ENV environment variable (default ``dev``) and selects
``config/<ENV>.yaml``. Every key becomes an upper-case Robot variable, for example
``base_url`` becomes ``${BASE_URL}``.

Precedence, highest first:
    1. ``--variable NAME:value`` on the command line (Robot applies it after this file)
    2. Environment variables, e.g. ``BASE_URL=http://serverest:3000``
    3. ``config/<ENV>.yaml``
"""

import os
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"


def get_variables(env: str | None = None) -> dict:
    env = env or os.getenv("ENV", "dev")
    config_file = CONFIG_DIR / f"{env}.yaml"
    if not config_file.is_file():
        available = sorted(path.stem for path in CONFIG_DIR.glob("*.yaml"))
        raise ValueError(f"Unknown environment '{env}'. Available: {', '.join(available)}")

    settings = yaml.safe_load(config_file.read_text(encoding="utf-8")) or {}
    variables = {"ENV": env}
    for key, default in settings.items():
        name = key.upper()
        override = os.getenv(name)
        variables[name] = default if override is None else _coerce(override, default)
    return variables


def _coerce(value: str, default):
    """Converts an environment-variable string to the type used in the YAML file."""
    if isinstance(default, bool):
        return value.strip().lower() in ("1", "true", "yes", "on")
    if isinstance(default, int):
        return int(value)
    if isinstance(default, float):
        return float(value)
    return value
