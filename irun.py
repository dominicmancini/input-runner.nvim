"""
#!/usr/bin/env python3
richrun.py — universal Rich runner for Python files.

Usage:
  richrun.py /abs/path/to/file.py [-- args...]

- Always pass an absolute path to a .py file.
- richrun.py detects if the file belongs to a package:
    * If inside a package → runs with runpy.run_module so imports work.
    * Otherwise           → runs with runpy.run_path.
- Rich pretty printing, tracebacks, and logging are enabled globally.
"""

import argparse
import builtins
import logging
import os
from pathlib import Path
import runpy
import sys
import importlib.util
import code

# ---- Rich setup ----
from rich import print as rprint, pretty
from rich.traceback import install as rich_traceback_install
from rich.logging import RichHandler


def install_rich():
    pretty.install()
    rich_traceback_install(show_locals=True, indent_guides=True, width=120)
    builtins.print = rprint  # override print globally
    if not logging.getLogger().handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(message)s",
            datefmt="[%X]",
            handlers=[
                RichHandler(rich_tracebacks=True, tracebacks_show_locals=True)
            ],
        )


# ---- Helpers ----
def find_package_root(file: Path) -> tuple[Path | None, str | None]:
    """
    Walk up from file until __init__.py stops.
    Return (pkg_root_dir, dotted_module_name) if inside a package.
    """
    if not file.exists():
        return None, None

    cur = file.parent
    parts = [file.stem]
    while (cur / "__init__.py").exists():
        parts.insert(0, cur.name)
        cur = cur.parent

    if len(parts) > 1:  # at least one package level
        pkg_root = cur
        module_name = ".".join(parts)
        return pkg_root, module_name
    return None, None


# ---- Main ----
def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("file", help="Absolute path to a Python file")
    parser.add_argument("args",
                        nargs=argparse.REMAINDER,
                        help="Arguments for the target script")
    ns = parser.parse_args(argv)

    file = Path(ns.file).resolve()
    if file.suffix != ".py" or not file.exists():
        sys.stderr.write(f"richrun.py: {file} is not a valid .py file\n")
        return 1

    target_args = ns.args[1:] if ns.args[:1] == ["--"] else ns.args

    install_rich()

    pkg_root, module_name = find_package_root(file)

    if module_name:
        # Inside a package → run as module
        sys.path.insert(0, str(pkg_root))
        sys.argv = [str(file), *target_args]
        try:
            runpy.run_module(module_name, run_name="__main__")
        except SystemExit as e:
            return int(e.code) if isinstance(e.code, int) else 1
    else:
        # Standalone script
        sys.argv = [str(file), *target_args]
        os.chdir(file.parent)
        try:
            runpy.run_path(str(file), run_name="__main__")
        except SystemExit as e:
            return int(e.code) if isinstance(e.code, int) else 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
