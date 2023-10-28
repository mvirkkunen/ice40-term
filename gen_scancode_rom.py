#!/usr/bin/env python

import ast

# https://www.win.tue.nl/~aeb/linux/kbd/scancodes-10.html
# | scancode | default  | shift | altgr | altgr_shift | ctrl | name         |

def unescape(s):
    if "\\" in s:
        return ast.literal_eval(f"b\"{s}\"")
    else:
        return s.encode("utf-8")

keys = [[b""] * 6 for _ in range(0x80)]

with open("scancode_table.md", "r") as f:
    lines = f.readlines()

    for row in lines[2:]:
        row = [f.strip() for f in row.strip(" |\r\n").split("|")]
        if len(row) != 7:
            continue

        code = int(row[0].replace("-", ""), 16)
        if code < 0x80:
            for i in range(5):
                if row[i + 1]:
                    keys[code][i] = unescape(row[i + 1])
        elif code & 0xff00 == 0xe000 and code & 0xff < 0x80:
            if row[1]:
                keys[code & 0xff][5] = unescape(row[1])

with open("build/scancode_rom.bin", "wb") as f:
    for s in range(6):
        for k in range(0x80):
            f.write(keys[k][s].ljust(8, b"\xff"))

