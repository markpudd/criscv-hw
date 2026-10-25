# bin2memh.py — raw little-endian binary -> $readmemh, one 32-bit word per line
import sys, struct
data = open(sys.argv[1], 'rb').read()
data += b'\0' * (-len(data) % 4)          # pad to a whole word
with open(sys.argv[2], 'w') as f:
    for (w,) in struct.iter_unpack('<I', data):
        f.write(f'{w:08x}\n')