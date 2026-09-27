# Tools #

There are a few tools here to help build various thing.

* bintohex.py - this converts bin to HEX file.  This is used to creat the bootloader memory file.
* genim.py - Generates a test grayscale image for the vga code
* outtobin.py - Takes a binary built by the gcc toolchain and adds some headers for the bootloader
* filetobin.py - Takes a file and upload to 0xc00000 which can then be accesed via standard functions
* pictobin.py - Takes an image file and creates binary to upload via bootloader