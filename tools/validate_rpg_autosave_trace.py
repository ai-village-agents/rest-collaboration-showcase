#!/usr/bin/env python3
"""Helper CLI to validate RPG autosave traces for rest-collaboration-showcase against the shared schema."""

import argparse
import json
import sys
import urllib.error
import urllib.request

try:
    from jsonschema import Draft202012Validator
except Exception:
    print(
        "Requirement already satisfied: jsonschema in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (4.22.0)\n"
        "Requirement already satisfied: attrs>=22.2.0 in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (25.4.0)\n"
        "Requirement already satisfied: jsonschema-specifications>=2023.03.6 in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (2025.9.1)\n"
        "Requirement already satisfied: referencing>=0.28.4 in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (0.36.2)\n"
        "Requirement already satisfied: rpds-py>=0.7.1 in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (0.27.1)\n"
        "Requirement already satisfied: typing-extensions>=4.4.0 in "
        "/home/computeruse/.pyenv/versions/3.11.6/lib/python3.11/site-packages (4.15.0)",
        file=sys.stderr,
    )
    sys.exit(3)


def load_schema(schema_url: str) -> dict:
    """Fetch and parse the JSON schema from the given URL."""
    try:
        with urllib.request.urlopen(schema_url) as response:
            return json.load(response)
    except urllib.error.URLError as exc:
        print(f"Failed to fetch schema from {schema_url}: {exc}", file=sys.stderr)
        sys.exit(2)
    except Exception as exc:
        print(f"Failed to load schema from {schema_url}: {exc}", file=sys.stderr)
        sys.exit(2)


def load_trace(trace_path: str):
    """Load the trace JSON file."""
    try:
        with open(trace_path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        print(f"Failed to parse JSON from {trace_path}: {exc}", file=sys.stderr)
        sys.exit(1)
    except OSError as exc:
        print(f"Failed to read {trace_path}: {exc}", file=sys.stderr)
        sys.exit(1)


def format_error_path(error) -> str:
    """Convert an error path to a simple JSON Pointer-like string."""
    parts = [str(piece) for piece in error.absolute_path]
    return "/" + "/".join(parts) if parts else "/"


def validate_trace(instance, validator: Draft202012Validator):
    """Return a list of validation errors."""
    return sorted(validator.iter_errors(instance), key=lambda err: tuple(err.absolute_path))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate an RPG autosave trace JSON file against the shared schema."
    )
    parser.add_argument("trace_path", help="Path to the autosave trace JSON file to validate.")
    parser.add_argument(
        "--schema-url",
        default="https://ai-village-agents.github.io/schemas/rpg-autosave-trace-v0.1.json",
        help="Override the schema URL if needed.",
    )
    args = parser.parse_args(argv)

    schema = load_schema(args.schema_url)
    validator = Draft202012Validator(schema)

    instance = load_trace(args.trace_path)
    errors = validate_trace(instance, validator)

    if not errors:
        print(f"VALID {args.trace_path}")
        return 0

    print(f"INVALID {args.trace_path}")
    for error in errors:
        path = format_error_path(error)
        print(f"- {path}: {error.message}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
