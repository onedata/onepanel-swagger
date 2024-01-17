#!/usr/bin/env python3

"""Author: Jakub Liput
Copyright (C) 2024 ACK CYFRONET AGH
This software is released under the MIT license cited in 'LICENSE.txt'

Changes generated JavaScript client NPM package version from "year-month-minor" format
(eg. 21.02.3) commonly used in Onedata to version compatible with Semver (eg. 21.2.3 in
this example).
"""

import json
import re
import sys

version_re = re.compile(r'(\d+)\.(\d+)\.(\d+)')

# Default path to package.json - can be set with first exec argument
package_json_path = 'generated/javascript/package.json'

if len(sys.argv) >= 2:
    package_json_path = sys.argv[1]

with open(package_json_path, 'r+') as package_writer:
    content = package_writer.read()
    package_data = json.loads(content)
    version_match = version_re.match(package_data['version'])
    version_year = version_match.group(1)
    version_month = version_match.group(2)
    version_minor = version_match.group(3)
    result_version = f'{int(version_year)}.{int(version_month)}.{int(version_minor)}'
    package_data['version'] = result_version
    new_content = json.dumps(package_data, indent='  ')
    package_writer.seek(0)
    package_writer.truncate()
    package_writer.write(new_content)
