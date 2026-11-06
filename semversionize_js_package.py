#!/usr/bin/env python3

"""
Normalizes generated JavaScript client NPM package version from
"year.month.minor" format (e.g., modern 25.1, legacy 21.02.3) commonly used in
Onedata to version compatible with Semver (e.g., 25.1.0, 21.2.3).

Compatible with Python 3.7+.
"""

__author__ = "Jakub Liput"
__copyright__ = "Copyright (C) 2024 ACK CYFRONET AGH, Copyright (C) 2026 Onedata (onedata.org)"
__license__ = "This software is released under the MIT license cited in LICENSE.txt"

import argparse
import json
import re

MAJOR_VERSION_RE = re.compile(r"^(\d+).*")
TWO_POSITIONAL_CALVER_RE = re.compile(r"^(\d+)\.(\d+)$")
THREE_POSITIONAL_CALVER_RE = re.compile(r"^(\d+)\.([^.]+?)\.(\d+)$")
FOUR_POSITIONAL_TAGGED_CALVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+-(?:alpha|beta|rc))\.(\d+)$")
CALVER_SHORTENED_TAG_RE = re.compile(r"^(\d)+(-(alpha|beta|rc))$")
LEGACY_MAJOR_MINOR_RE = re.compile(r"^(\d+)\.(\d+)$")
LEGACY_VERSION_RE = re.compile(r"(\d+\.\d+)\.(.+)")
LEGACY_TAGGED_MINOR_RE = re.compile(r"^(\d+-(rc|beta|alpha))(\d+)$")

# Default path to package.json - can be set with first exec argument
DEFAULT_PACKAGE_JSON_PATH = "generated/javascript/package.json"


def compile_version_string(major, minor, patch=0, tag_version=None):
    result_version = f"{major}.{minor}.{patch}"
    if tag_version:
        result_version += f".{tag_version}"
    return result_version


def parse_legacy_version(version_string):
    match_result = LEGACY_VERSION_RE.match(version_string)
    if match_result is None:
        return None

    return {
        "major": match_result.group(1),
        "minor": match_result.group(2),
    }


def semversionize_modern(version_string):
    # Two-positional, e.g., 25.1.
    two_match = TWO_POSITIONAL_CALVER_RE.match(version_string)
    if two_match is not None:
        return compile_version_string(two_match.group(1), two_match.group(2))

    # Three-positional, e.g., 25.1.2 or 25.1-rc.1.
    three_match = THREE_POSITIONAL_CALVER_RE.match(version_string)
    if three_match is not None:
        major = three_match.group(1)
        initial_minor = three_match.group(2)
        patch_or_tag_version = three_match.group(3)

        if initial_minor.isdigit():
            minor = initial_minor
            patch = patch_or_tag_version
            tag_version = None
        else:
            minor_match = CALVER_SHORTENED_TAG_RE.match(initial_minor)
            if minor_match is None:
                return None
            minor = minor_match.group(1)
            patch = f"0{minor_match.group(2)}"
            tag_version = patch_or_tag_version

        return compile_version_string(major, minor, patch, tag_version)

    # Full semver with version tag, e.g., 25.1.2-rc.3.
    four_match = FOUR_POSITIONAL_TAGGED_CALVER_RE.match(version_string)
    if four_match is not None:
        return compile_version_string(
            four_match.group(1),
            four_match.group(2),
            four_match.group(3),
            four_match.group(4),
        )

    return None


def semversionize_legacy(version_string):
    legacy_version_data = parse_legacy_version(version_string)
    if legacy_version_data is None:
        return None

    major_match = LEGACY_MAJOR_MINOR_RE.match(legacy_version_data["major"])
    if major_match is None:
        return None

    major = major_match.group(1)
    minor = int(major_match.group(2))
    legacy_minor = legacy_version_data["minor"]

    if str(legacy_minor).isdigit():
        patch = legacy_minor
        tag_version = None
    else:
        minor_match = LEGACY_TAGGED_MINOR_RE.match(str(legacy_minor))
        if minor_match is None:
            return None
        patch = minor_match.group(1)
        tag_version = minor_match.group(3)

    return compile_version_string(major, minor, patch, tag_version)


def semversionize(version_string):
    if not version_string:
        return None

    major_match = MAJOR_VERSION_RE.match(version_string)
    if major_match is None:
        return None

    major_version = int(major_match[1])

    # Support for legacy versions (eg. 21.02.3, 21.02-rc1, 21.02-beta1,
    # 21.02-alpha1).
    if major_version <= 21:
        return semversionize_legacy(version_string)

    return semversionize_modern(version_string)



def replace_package_json_version(json_string):
    package_data = json.loads(json_string)
    version = package_data["version"]
    semversion = semversionize(version)
    if semversion is None:
        raise ValueError(f"Unsupported version format: {version}")

    package_data["version"] = semversion
    return json.dumps(package_data, indent="  ")


def main():
    parser = argparse.ArgumentParser(description=__doc__)

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
