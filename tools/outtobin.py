import sys
import os


size = os.path.getsize(sys.argv[1])
elf = open(sys.argv[1],"rb")
out = open(sys.argv[2],"wb")

#out.write((65).to_bytes(1, byteorder='big', signed=False))
#out.write((66).to_bytes(1, byteorder='big', signed=False))

out.write((size).to_bytes(4, byteorder='big', signed=False))

for i in range(0,size):
    out.write(elf.read(1))
