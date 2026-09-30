#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
"""Behavioural tests for skills/typo3-typoscript-ref/scripts/rst2md.py.

Each case feeds a piece of TYPO3 reStructuredText to the converter and checks
the Markdown it produces. The last case runs the script as fetch-docs.sh does,
reading stdin and writing stdout.

Run from anywhere: python3 tests/rst2md.py
"""

import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "skills" / "typo3-typoscript-ref" / "scripts" / "rst2md.py"

spec = importlib.util.spec_from_file_location("rst2md", SCRIPT)
rst2md = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rst2md)

CASES = [
    (
        "underlined title becomes a level-1 heading",
        "Title\n=====\n\nText.\n",
        ["# Title", "Text."],
        [],
    ),
    (
        "overlined title becomes a heading",
        "=====\nTitle\n=====\n",
        ["# Title"],
        ["====="],
    ),
    (
        "dash underline becomes a level-2 heading",
        "Section\n-------\n",
        ["## Section"],
        [],
    ),
    (
        "tilde underline becomes a level-3 heading",
        "Sub\n~~~\n",
        ["### Sub"],
        [],
    ),
    (
        "code-block becomes a fenced block with its language",
        ".. code-block:: typoscript\n   :caption: setup.typoscript\n\n   page = PAGE\n   page.10 = TEXT\n\nAfter.\n",
        ["```typoscript\npage = PAGE\npage.10 = TEXT\n```", "After."],
        [":caption:"],
    ),
    (
        "note admonition becomes a blockquote",
        ".. note::\n    Mind the gap.\n",
        ["> **Note:**\n> Mind the gap."],
        [],
    ),
    (
        "versionadded keeps its argument",
        ".. versionadded:: 13.0\n    New option.\n",
        ["> **Added in: 13.0**", "> New option."],
        [],
    ),
    (
        "admonition body indented by three spaces keeps its text",
        ".. note::\n   Mind the gap.\n",
        ["> **Note:**\n> Mind the gap."],
        [],
    ),
    (
        "admonition keeps relative indentation of nested lines",
        ".. warning::\n   First line.\n\n   *  item\n      continued\n",
        ["> First line.", "> *  item", ">    continued"],
        [],
    ),
    (
        "double-backtick literal becomes a code span",
        "Use ``stdWrap.wrap`` here.\n",
        ["Use `stdWrap.wrap` here."],
        [],
    ),
    (
        "ref role with display text keeps the text",
        "See :ref:`the wrap function <stdwrap-wrap>`.\n",
        ["See the wrap function."],
        [":ref:", "stdwrap-wrap"],
    ),
    (
        "ref role without display text keeps the label",
        "See :ref:`stdwrap`.\n",
        ["See stdwrap."],
        [":ref:"],
    ),
    (
        "code roles become code spans",
        "Set :typoscript:`page.10` and :php:`$x`.\n",
        ["Set `page.10` and `$x`."],
        [":typoscript:", ":php:"],
    ),
    (
        "confval becomes a heading with a property table",
        ".. confval:: wrap\n   :name: stdwrap-wrap\n   :type: wrap\n   :Default: none\n\n   Wraps the content.\n",
        ["### wrap", "| Type | wrap |", "| Default | none |", "Wraps the content."],
        ["stdwrap-wrap"],
    ),
    (
        "toctree, include, image and index directives are dropped",
        ".. toctree::\n   :hidden:\n\n   Sub/Index\n\n.. include:: /Includes.rst.txt\n.. image:: a.png\n.. index:: stdWrap\n\nBody.\n",
        ["Body."],
        ["toctree", "Sub/Index", "Includes.rst.txt", "a.png", "index::"],
    ),
    (
        "reference targets and comments are dropped",
        ".. _stdwrap:\n\n.. This is a comment\n   spanning two lines.\n\nBody.\n",
        ["Body."],
        ["_stdwrap", "comment", "spanning"],
    ),
    (
        "literalinclude becomes a file pointer",
        ".. literalinclude:: _codesnippets/setup.typoscript\n   :language: typoscript\n",
        ["> See file: `_codesnippets/setup.typoscript`"],
        [":language:"],
    ),
    (
        "youtube becomes a link",
        ".. youtube:: abc123\n",
        ["> Video: https://www.youtube.com/watch?v=abc123"],
        [],
    ),
    (
        "unknown directives are dropped with their body",
        ".. card-grid::\n   :columns: 2\n\n   Card text.\n\nBody.\n",
        ["Body."],
        ["card-grid", "Card text."],
    ),
    (
        "navigation-title metadata is dropped",
        ":navigation-title: Short\n\nTitle\n=====\n",
        ["# Title"],
        ["navigation-title"],
    ),
]


def main() -> int:
    passed = failed = 0
    for name, source, present, absent in CASES:
        out = rst2md.convert_rst_to_md(source)
        problems = [f"missing {p!r}" for p in present if p not in out]
        problems += [f"unexpected {a!r}" for a in absent if a in out]
        if problems:
            failed += 1
            print(f"FAIL {name}")
            for problem in problems:
                print(f"     {problem}")
            print(f"     output: {out!r}")
        else:
            passed += 1
            print(f"ok   {name}")

    # Whitespace clean-up: no run of more than one blank line, no trailing
    # spaces, exactly one final newline.
    out = rst2md.convert_rst_to_md("A   \n\n\n\n\nB\n\n\n")
    if out == "A\n\nB\n":
        passed += 1
        print("ok   output is normalised")
    else:
        failed += 1
        print(f"FAIL output is normalised\n     output: {out!r}")

    # As fetch-docs.sh calls it: rST on stdin, Markdown on stdout.
    proc = subprocess.run(
        [sys.executable, str(SCRIPT)],
        input="Title\n=====\n\nUse ``x``.\n",
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode == 0 and proc.stdout == "# Title\n\nUse `x`.\n":
        passed += 1
        print("ok   script converts stdin to stdout")
    else:
        failed += 1
        print(
            f"FAIL script converts stdin to stdout\n"
            f"     exit {proc.returncode}, stdout {proc.stdout!r}, stderr {proc.stderr!r}"
        )

    print()
    print(f"rst2md.py: {passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
