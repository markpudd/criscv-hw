#!/usr/bin/env python3
"""Emit an Intel HEX image with 32-bit words, for Quartus memory init.

One record per 32-bit word:

    :04 <word address> 00 <4 data bytes> <checksum>

The address field is a WORD index, not a byte offset -- that is what
Quartus expects for memories wider than 8 bits.

Byte order within a word defaults to file order, matching the 16-bit
script this replaces. Pass -s to reverse it (most significant byte
first), which is Quartus's normal convention and removes the need for a
byte swap in the RTL.
"""

import argparse
import sys

BYTES_PER_WORD = 4
MAX_WORD_ADDR = 0xFFFF  # 16-bit address field; beyond this needs type 04 records
EOF_RECORD = ":00000001FF"


def checksum(payload):
    """Two's complement of the low byte of the sum, as Intel HEX defines it."""
    return (-sum(payload)) & 0xFF


def record(addr, data, rectype=0x00):
    payload = bytes([len(data), (addr >> 8) & 0xFF, addr & 0xFF, rectype]) + data
    return ":" + (payload + bytes([checksum(payload)])).hex().upper()


def convert(src, out, swap=False, depth=None):
    addr = 0
    while True:
        chunk = src.read(BYTES_PER_WORD)
        if not chunk:
            break

        if len(chunk) < BYTES_PER_WORD:
            print(
                f"warning: trailing {len(chunk)} byte(s) zero-padded to a full word",
                file=sys.stderr,
            )
            chunk = chunk.ljust(BYTES_PER_WORD, b"\0")

        if addr > MAX_WORD_ADDR:
            raise ValueError(
                f"word address {addr} exceeds the 16-bit address field; "
                "extended linear address records would be needed"
            )
        if depth is not None and addr >= depth:
            raise ValueError(
                f"input holds more than {depth} words and would overrun the memory"
            )

        out.write(record(addr, chunk[::-1] if swap else chunk) + "\n")
        addr += 1

    out.write(EOF_RECORD + "\n")
    return addr


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Convert a flat binary into a 32-bit-word Intel HEX image."
    )
    ap.add_argument("input", help="flat binary, e.g. the output of objcopy -O binary")
    ap.add_argument("-o", "--output", help="output file (default: stdout)")
    ap.add_argument(
        "-s",
        "--swap",
        action="store_true",
        help="reverse bytes within each word (MSB first)",
    )
    ap.add_argument(
        "-d",
        "--depth",
        type=int,
        default=None,
        help="memory depth in words; fail rather than overrun it",
    )
    args = ap.parse_args(argv)

    out = open(args.output, "w") if args.output else sys.stdout
    try:
        with open(args.input, "rb") as src:
            words = convert(src, out, swap=args.swap, depth=args.depth)
    except ValueError as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    finally:
        if args.output:
            out.close()

    print(f"{words} words ({words * 4} bytes)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())