import sys
import os


size = os.path.getsize(sys.argv[1])
elf = open(sys.argv[1],"rb")
out = open(sys.argv[2],"wb")


out.write("RVF".encode('utf-8'))

out.write((1).to_bytes(1, byteorder='little', signed=False))



out.write("./doom1.wad".ljust(20, '\0').encode('utf-8'))
out.write((size).to_bytes(4, byteorder='little', signed=False))

for i in range(0,size):
    out.write(elf.read(1))
