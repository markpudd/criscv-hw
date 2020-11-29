import sys
import os
from PIL import Image


size = 76800 + 768;

out = open(sys.argv[2],"wb")
im = Image.open(sys.argv[1])
im = im.resize((320, 240)).convert("P")


out.write("RVF".encode('utf-8'))

out.write((1).to_bytes(1, byteorder='little', signed=False))



out.write("./pic.raw".ljust(20, '\0').encode('utf-8'))
out.write((size).to_bytes(4, byteorder='little', signed=False))

pb = im.getpalette()
for i in range(0,256):
    out.write(pb[i*3].to_bytes(1, byteorder='little', signed=False))
    out.write(pb[i*3+1].to_bytes(1, byteorder='little', signed=False))
    out.write(pb[i*3+2].to_bytes(1, byteorder='little', signed=False))
    out.write((255).to_bytes(1, byteorder='little', signed=False))

for y in range(0,240):
    for x in range(0,320):
      out.write(im.getpixel((x,y)).to_bytes(1, byteorder='little', signed=False))  