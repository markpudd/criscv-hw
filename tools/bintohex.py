import sys




#  This is pretty crude way of claclulating the checksum
def chksum(st):
    bytes= bytearray.fromhex(st[1:])
    sum=0
    for b in bytes:
        sum+=b
    return (((sum&0xff)^0xff)+1)&0xff


def printRow(row, b1,b2):
    outst =':02'
    outst+='{:04x}'.format(row )
    outst+='00'
    if(b1 !='' or b2 !=''):
        outst+=b1.encode('hex')
        outst+=b2.encode('hex')
    else:
        outst+='0000'
    outst+='{:02x}'.format(chksum(outst))
    print(outst.upper())


elf = open(sys.argv[1],"rb")

for i in range(0,4096):
    b1 = elf.read(1)
    b2 = elf.read(1)
    b3 = elf.read(1)
    b4 = elf.read(1)
    printRow(i*2,b1,b2)
    printRow(i*2+1,b3,b4)

print(':00000001FF')
