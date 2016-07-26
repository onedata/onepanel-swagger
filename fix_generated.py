#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re, sys

DIR = "generated/cowboy"

for n in os.listdir(DIR):
    with open(os.path.join(DIR, n), "r+") as f:
        # Fix multiline comments.
        lines = f.readlines()
        new_lines = []
        for line in lines:
            if '\\n' in line.rstrip():
                pos = line.find('%%')
                if pos >= 0:
                    parts = filter(lambda p: p, line[pos + 3:].rstrip().split('\\n'))
                    parts = map(lambda p: ' ' * pos + '%% ' + p + '\n', parts)
                    new_lines.extend(parts)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        lines = ''.join(new_lines)

        # Fix syntax and substitute invalid character sequences.
        lines = re.sub(r',(\s*[}\]\)])', '\g<1>', lines)
        lines = re.sub('\\&\\#39\\;', '\'', lines)
        lines = re.sub('\\&\\#x3D\\;\\&gt\\;', '=>', lines)
        lines = re.sub('\\&\\#x60\\;', '`', lines)

        # Write new file.
        f.seek(0)
        f.truncate()
        f.write(lines)