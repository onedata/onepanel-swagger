#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script processes generated erlang files to
- translate html-escaped characters into their raw form needed in the source code
- fix syntax errors (e.g. trailing commas)
- ensure line wrapping in comments
"""

import os, re, sys, textwrap

DIR = "generated/cowboy"

for n in os.listdir(DIR):
    if n.endswith(".erl"):
        with open(os.path.join(DIR, n), "r+") as f:
            # Fix multiline comments.
            lines = f.readlines()
            new_lines = []
            for line in lines:
                pos = line.find('%% ')
                if pos != -1 and '%%%' not in line:
                    parts = textwrap.wrap(line[pos + 3:], 77 - pos, break_long_words=False)
                    parts = map(lambda p: ' ' * pos + '%% ' + p + '\n', parts)
                    new_lines.extend(parts)
                else:
                    new_lines.append(line)
            lines = ''.join(new_lines)

            # Fix syntax and substitute invalid character sequences.
            lines = re.sub(r',(\s*[}\]\)])', r'\g<1>', lines)
            lines = re.sub(r'\&\#39\;', r"'", lines)
            lines = re.sub(r'\&\#x3D\;\&gt\;', r'=>', lines)
            lines = re.sub(r'\&\#x3D\;', r'=', lines)
            lines = re.sub(r'\&\#x60\;', r'`', lines)
            lines = re.sub(r'\s{\s', r' {', lines)
            lines = re.sub(r'\#{\s([^\s])', r'#{\g<1>', lines)
            lines = re.sub(r'([^\s])\s}', r'\g<1>}', lines)
            # remove space before EOL
            lines = re.sub(r' +\n', r'\n', lines)
            # remove space between consecutive } brackets
            lines = re.sub(r'\} +\}', r'}}', lines)
            # ensure no space before a comma
            lines = re.sub(r'\s+,', r',', lines)
            # ensure space after comma
            lines = re.sub(r',([^\s])', r', \g<1>', lines)
            lines = lines.replace('\\n', '')

            # Write new file.
            f.seek(0)
            f.truncate()
            f.write(lines)
