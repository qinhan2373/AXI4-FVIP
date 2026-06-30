#!/usr/bin/env python3
"""Summarize properties recorded in an SBY JUnit XML report."""

import argparse
import collections
import glob
import os
import sys
import xml.etree.ElementTree as ET


def find_xml(path):
    if os.path.isfile(path):
        return path

    direct = sorted(glob.glob(os.path.join(path, "*.xml")))
    if direct:
        return direct[0]

    recursive = sorted(glob.glob(os.path.join(path, "**", "*.xml"), recursive=True))
    if recursive:
        return recursive[0]

    raise FileNotFoundError("no SBY XML report found under: " + path)


def source_file(location):
    if not location:
        return "<unknown>"
    if ".sv:" in location:
        return location.split(".sv:", 1)[0] + ".sv"
    return location.split(":", 1)[0]


def suite_properties(suite):
    props = {}
    props_node = suite.find("properties")
    if props_node is None:
        return props
    for prop in props_node.findall("property"):
        props[prop.get("name", "")] = prop.get("value", "")
    return props


def testcase_status(testcase, suite_passed):
    if testcase.find("failure") is not None:
        return "FAILED"
    if testcase.find("error") is not None:
        return "ERROR"
    if testcase.find("skipped") is not None:
        return "SKIPPED"
    if testcase.get("type") == "ASSERT" and suite_passed:
        return "PROVEN"
    return "PASS"


def format_summary(xml_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    suites = list(root.findall("testsuite"))
    if not suites and root.tag == "testsuite":
        suites = [root]
    if not suites:
        raise ValueError("no testsuite element found in: " + xml_path)

    lines = []
    for suite in suites:
        props = suite_properties(suite)
        suite_status = props.get("status", "UNKNOWN")
        suite_name = suite.get("name", "<unnamed>")
        suite_passed = suite_status == "PASS"

        typed_cases = [
            tc for tc in suite.findall("testcase")
            if tc.get("type") in {"ASSERT", "COVER", "ASSUME"}
        ]
        by_type = collections.Counter(tc.get("type") for tc in typed_cases)
        status_by_type = collections.defaultdict(collections.Counter)
        file_by_type = collections.defaultdict(collections.Counter)

        for tc in typed_cases:
            kind = tc.get("type")
            status = testcase_status(tc, suite_passed)
            status_by_type[kind][status] += 1
            file_by_type[kind][source_file(tc.get("location", ""))] += 1

        lines.append("SBY property summary")
        lines.append(f"  xml    : {xml_path}")
        lines.append(f"  suite  : {suite_name}")
        lines.append(f"  status : {suite_status}")
        if suite.get("time") is not None:
            lines.append(f"  time   : {suite.get('time')}s")
        lines.append("")

        for kind in ("ASSERT", "ASSUME", "COVER"):
            if by_type[kind] == 0:
                continue
            status_text = ", ".join(
                f"{name.lower()}={count}"
                for name, count in sorted(status_by_type[kind].items())
            )
            lines.append(f"{kind}: {by_type[kind]} ({status_text})")
            for filename, count in sorted(file_by_type[kind].items()):
                lines.append(f"  {count:4d} {filename}")
            lines.append("")

        if suite_passed and by_type["ASSERT"]:
            lines.append("Proven assertions:")
        elif by_type["ASSERT"]:
            lines.append("Assertions:")

        for tc in sorted(
            (tc for tc in typed_cases if tc.get("type") == "ASSERT"),
            key=lambda item: (source_file(item.get("location", "")), item.get("id", "")),
        ):
            status = testcase_status(tc, suite_passed)
            prop_id = tc.get("id") or "<unnamed>"
            location = tc.get("location") or "<unknown>"
            lines.append(f"  {status:7s} {location}  {prop_id}")

        cover_cases = [tc for tc in typed_cases if tc.get("type") == "COVER"]
        skipped_covers = [tc for tc in cover_cases if testcase_status(tc, suite_passed) == "SKIPPED"]
        if skipped_covers:
            lines.append("")
            lines.append(
                "Note: skipped COVER entries in an SBY prove task are not coverage results; "
                "run the cover task to prove reachability."
            )
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Print a readable assertion/cover summary from an SBY XML report."
    )
    parser.add_argument("path", help="SBY work directory or XML report path")
    parser.add_argument(
        "--write",
        metavar="FILE",
        help="also write the summary to FILE",
    )
    args = parser.parse_args()

    try:
        xml_path = find_xml(args.path)
        summary = format_summary(xml_path)
    except Exception as err:
        print(f"error: {err}", file=sys.stderr)
        return 1

    sys.stdout.write(summary)
    if args.write:
        with open(args.write, "w", encoding="utf-8") as handle:
            handle.write(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
