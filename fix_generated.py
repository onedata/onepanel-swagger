#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re, sys, textwrap

DIR = "generated/cowboy"

for n in os.listdir(DIR):
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
        lines = re.sub(r',(\s*[}\]\)])', '\g<1>', lines)
        lines = re.sub('\\&\\#39\\;', '\'', lines)
        lines = re.sub('\\&\\#x3D\\;\\&gt\\;', '=>', lines)
        lines = re.sub('\\&\\#x60\\;', '`', lines)
        lines = lines.replace('\\n', '')

        # Write new file.
        f.seek(0)
        f.truncate()
        f.write(lines)