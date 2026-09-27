import sys
import os
from PIL import Image


size = 76800 + 768;

out = open(sys.argv[2],"wb")




out.write("RVF".encode('utf-8'))

out.write((1).to_bytes(1, byteorder='little', signed=False))



out.write("./pic.raw".ljust(20, '\0').encode('utf-8'))
out.write((size).to_bytes(4, byteorder='little', signed=False))


for i in range(0,256):
    out.write((i).to_bytes(1, byteorder='little', signed=False))
    out.write((i).to_bytes(1, byteorder='little', signed=False))
    out.write((i).to_bytes(1, byteorder='little', signed=False))
    out.write((i).to_bytes(1, byteorder='little', signed=False))

for y in range(0,240):
    for x in range(0,320):
      c = x
      if(c>255):
          c = 255
      out.write((c).to_bytes(1, byteorder='little', signed=False))  