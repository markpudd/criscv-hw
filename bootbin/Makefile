CROSS_COMPILE ?= /opt/riscv/bin/riscv64-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy

BUILD_DIR ?= build
CPPFLAGS += -Iff16/source
             

# GCC 12+ needs _zicsr for the csrw/csrrsi in boot.c and stdfn.c.
# On an older toolchain use: make ARCH=rv32i
ARCH ?= rv32im

CFLAGS  = -march=$(ARCH)  -mno-div -mabi=ilp32 -mstrict-align -Os -DNORMALUNIX -DNEWLIB
LDFLAGS = -march=$(ARCH) -mabi=ilp32 -Wl,-N -Wl,-Map=$(BUILD_DIR)/boot.map
LDLIBS  = -lm

CFLAGS  += -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables
LDFLAGS += -Wl,--gc-sections --specs=nano.specs 

BOOT_BASE ?= 0xC00000
LDFLAGS += -Wl,-Ttext-segment=$(BOOT_BASE)
# The ECALL handler runs with the *program's* gp, so the bootloader must not
# use gp-relative addressing for its globals (FatFs state, fd table).
LDFLAGS += -Wl,--no-relax

# Add your linker script here to place boot.bin away from 0x10000, e.g.
# LDFLAGS += -T boot.ld

OBJECTS = $(BUILD_DIR)/boot.o $(BUILD_DIR)/stdfn.o $(BUILD_DIR)/ymodem.o \
          $(BUILD_DIR)/ff.o $(BUILD_DIR)/sddisk.o $(BUILD_DIR)/diskio_sddisk.o $(BUILD_DIR)/ffunicode.o
TARGET = $(BUILD_DIR)/boot.elf
BIN    = $(BUILD_DIR)/boot.bin




FF_HDRS = ff16/source/ff.h ff16/source/ffconf.h

.PHONY: all clean

all: $(BIN)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/boot.o: boot.c stdfn.h ymodem.h $(FF_HDRS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# stdfn MUST be -O0: syscall() reads the saved a0-a7 at fixed stack offsets
# (60(sp)..88(sp)) that only match the -O0 prologue. The later -O0 overrides -Os.
$(BUILD_DIR)/stdfn.o: stdfn.c stdfn.h $(FF_HDRS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -O0 -c $< -o $@

$(BUILD_DIR)/ymodem.o: ymodem.c ymodem.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/ff.o: ff16/source/ff.c $(FF_HDRS) ff16/source/diskio.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/sddisk.o: sddisk.c sddisk.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/ffunicode.o: ff16/source/ffunicode.c $(FF_HDRS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/diskio_sddisk.o: diskio_sddisk.c sddisk.h ff16/source/ff.h ff16/source/diskio.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@


$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(BIN): $(TARGET)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD_DIR)