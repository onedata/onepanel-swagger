#!/usr/bin/env python3

"""
Changes generated JavaScript client NPM package version from "year.month.minor" format
(eg. 21.02.3) commonly used in Onedata to version compatible with Semver (eg. 21.2.3 in
this example).

Compatible with Python 3.7+
"""

__author__ = "Jakub Liput"
__copyright__ = "Copyright (C) 2024 ACK CYFRONET AGH"
__license__ = "This software is released under the MIT license cited in LICENSE.txt"

import argparse
import json
import re

VERSION_RE = re.compile(r"(?P<year>\d+)\.(?P<month>\d+)\.(?P<minor>\d+)")

# Default path to package.json - can be set with first exec argument
DEFAULT_PACKAGE_JSON_PATH = "generated/javascript/package.json"


def version_to_semver(version_string):
    version_match = VERSION_RE.match(version_string)
    version_year = version_match.group("year")
    version_month = version_match.group("month")
    version_minor = version_match.group("minor")
    return f"{int(version_year)}.{int(version_month)}.{int(version_minor)}"


def replace_package_json_version(json_string):
    package_data = json.loads(json_string)
    package_data["version"] = version_to_semver(package_data["version"])
    return json.dumps(package_data, indent="  ")


def main():
    parser = argparse.ArgumentParser(
        description="Changes generated JavaScript client NPM package version from "
        + '"year-month-minor" format (eg. 21.02.3) commonly used in Onedata to version '
        + "compatible with Semver (eg. 21.2.3 in this example)."
        + "errors.",
    )

    parser.add_argument(
        "package_json_path",
        nargs="?",
        default=DEFAULT_PACKAGE_JSON_PATH,
        help="Path to package.json to change it's version.",
    )

    args = parser.parse_args()

    with open(args.package_json_path, "r+", encoding="UTF-8") as package_writer:
        content = package_writer.read()
        new_content = replace_package_json_version(content)
        package_writer.seek(0)
        package_writer.truncate()
        package_writer.write(new_content)


if __name__ == "__main__":
    main()
