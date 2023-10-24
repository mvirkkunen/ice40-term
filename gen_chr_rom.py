#!/usr/bin/env python3

from binascii import hexlify
from PIL import Image

data = []

with Image.open("font.png") as im:
    pixels = list(im.getdata())

    for c in range(0, 256):
        for y in range(0, 16):
            byte = 0
            for x in range(0, 8):
                p = pixels[((c // 32) * 16 + y) * (8 * 32) + (c % 32) * 8 + x]
                byte >>= 1
                byte |= 0x80 if p[0] > 128 else 0x00
            data.append(byte)

with open("build/chr_rom.hex", "wb") as f:
    f.write(hexlify(bytes(data), b" "))
