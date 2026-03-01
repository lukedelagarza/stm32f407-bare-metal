# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make          # Build — produces build/main.elf and build/main.bin
make clean    # Remove build/ directory
make flash    # Flash build/main.bin to the MCU via st-flash (requires st-link)
```

Build output goes to `build/`. The linker also emits `build/main.map` for symbol/section inspection.

## Target Hardware

- **MCU**: STM32F407VGTx (ARM Cortex-M4F)
- **Toolchain**: `arm-none-eabi-gcc`
- **Memory**: 1 MB Flash @ `0x08000000`, 128 KB RAM @ `0x20000000`, 64 KB CCMRAM @ `0x10000000`
- **FPU**: hard float ABI (`-mfpu=fpv4-sp-d16 -mfloat-abi=hard`)
- **Flashing**: `st-flash write build/main.bin 0x08000000`

## Architecture

This is a bare-metal project with **no standard library** (`-nostdlib`, `-ffreestanding`). There is no RTOS or HAL layer.

**Boot sequence** (defined in `startup_stm32f407xx.s`):
1. `Reset_Handler` sets the stack pointer to `_estack`
2. Calls `SystemInit` (stub in `main.c` — add clock config here)
3. Copies `.data` from Flash to RAM, zero-fills `.bss`
4. Calls `__libc_init_array` (stub in `main.c`)
5. Branches to `main()`

**Key files**:
- `main.c` — application entry point; also provides `SystemInit()` and `__libc_init_array()` stubs
- `startup_stm32f407xx.s` — vector table and `Reset_Handler`; all unhandled IRQs alias to `Default_Handler` (infinite loop)
- `STM32F407VGTX_FLASH.ld` — linker script defining memory regions and section placement
- `Makefile` — build rules; add new `.c` files to `C_SRCS` and new `.s` files to `AS_SRCS`

## Adding Peripherals / IRQ Handlers

To handle an interrupt, define a function with the exact IRQ handler name listed in `startup_stm32f407xx.s` (e.g., `void TIM2_IRQHandler(void)`). The weak alias in the startup file will be overridden automatically.

To place code or data in CCMRAM, use `__attribute__((section(".ccmram")))`. Note: initialized variables in CCMRAM require startup code changes to copy init values from Flash.
