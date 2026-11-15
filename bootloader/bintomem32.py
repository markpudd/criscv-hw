#!/usr/bin/env python3
"""bintomem32.py - convert a raw binary into a Vivado XPM .mem file.

One 32-bit word per line, 8 hex digits, starting at word address 0.
Default packing is little-endian (byte 4n in bits [7:0]), which makes each
line read exactly like the instruction words objdump prints.
-s swaps to big-endian packing (byte 4n in bits [31:24]).

Usage: python3 bintomem32.py [-s] boot.bin > boot.mem
"""
import struct
import sys

args = sys.argv[1:]
swap = "-s" in args
files = [a for a in args if a != "-s"]
if len(files) != 1:
    sys.exit(__doc__)

data = open(files[0], "rb").read()
data += b"\0" * (-len(data) % 4)        # pad to a whole word
fmt = ">I" if swap else "<I"
for (word,) in struct.iter_unpack(fmt, data):
    print("%08x" % word)