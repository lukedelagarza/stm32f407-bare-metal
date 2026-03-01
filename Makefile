# Toolchain
CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE    = arm-none-eabi-size

# MCU settings
MCU = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard

# Project
TARGET    = main
BUILD_DIR = build
LDSCRIPT  = STM32F407VGTX_FLASH.ld

# Sources
C_SRCS  = main.c
AS_SRCS = startup_stm32f407xx.s

# Object files
C_OBJS  = $(addprefix $(BUILD_DIR)/, $(C_SRCS:.c=.o))
AS_OBJS = $(addprefix $(BUILD_DIR)/, $(AS_SRCS:.s=.o))
OBJS    = $(C_OBJS) $(AS_OBJS)

# Compiler flags
CFLAGS  = $(MCU) -Wall -Wextra -Werror -g -O0
CFLAGS += -ffreestanding

# Linker flags
LDFLAGS   = $(MCU) -T $(LDSCRIPT) -nostdlib
LDFLAGS  += -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref

# ---- Rules ----

all: $(BUILD_DIR)/$(TARGET).bin

# Create binary
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Linker
$(BUILD_DIR)/$(TARGET).elf: $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	$(SIZE) $@

# Compile C
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile assembly
$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(MCU) -c $< -o $@

# Utility targets
.PHONY: all clean flash

clean:
	rm -rf $(BUILD_DIR)

flash: $(BUILD_DIR)/$(TARGET).bin
	st-flash write $< 0x08000000
