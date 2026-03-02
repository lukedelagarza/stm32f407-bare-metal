# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make          # Build — produces build/main.elf and build/main.bin
make clean    # Remove build/ directory
make flash    # Flash build/main.bin to the MCU via st-flash (requires st-link)
```

Build output goes to `build/`. The linker also emits `build/main.map` for symbol/section inspection.

Key compiler flags (set in Makefile):
- `-Icmsis` — include path for CMSIS/device headers
- `-DSTM32F407xx` — enables device-specific register definitions in `stm32f407xx.h`
- `-MMD -MP` — auto-generate `.d` dependency files in `build/` for incremental rebuilds

## Target Hardware

- **MCU**: STM32F407VGTx (ARM Cortex-M4F)
- **Dev Board**: STM32F4-Discovery (UM1472)
- **Toolchain**: `arm-none-eabi-gcc`
- **Memory**: 1 MB Flash @ `0x08000000`, 128 KB RAM @ `0x20000000`, 64 KB CCMRAM @ `0x10000000`
- **FPU**: hard float ABI (`-mfpu=fpv4-sp-d16 -mfloat-abi=hard`)
- **Flashing**: `st-flash write build/main.bin 0x08000000`

## Architecture

This is a bare-metal project with **no standard library** (`-nostdlib`, `-ffreestanding`). There is no RTOS or HAL layer.

**Boot sequence** (defined in `startup_stm32f407xx.s`):
1. `Reset_Handler` sets the stack pointer to `_estack`
2. Calls `SystemInit` (defined in `cmsis/system_stm32f4xx.c` — enables FPU, relocates vector table; does NOT configure clocks)
3. Copies `.data` from Flash to RAM, zero-fills `.bss`
4. Calls `__libc_init_array` (stub in `src/main.c`)
5. Branches to `main()`

**Key files**:
- `src/main.c` — application entry point; provides `__libc_init_array()` stub and `clock_init()`
- `cmsis/system_stm32f4xx.c` — provides `SystemInit()` and `SystemCoreClockUpdate()`
- `cmsis/` — CMSIS headers (`stm32f407xx.h`, `core_cm4.h`, etc.) + `system_stm32f4xx.c` (SystemInit, SystemCoreClockUpdate)
- `include/` — project-local headers (empty; add custom headers here)
- `startup/startup_stm32f407xx.s` — vector table and `Reset_Handler`; all unhandled IRQs alias to `Default_Handler` (infinite loop)
- `startup/STM32F407VGTX_FLASH.ld` — linker script defining memory regions and section placement
- `Makefile` — build rules; add new `.c` files to `C_SRCS` and new `.s` files to `AS_SRCS`

**Clock configuration** (in `src/main.c`):
`clock_init()` is called from `main()` and configures the PLL for 168 MHz SYSCLK:
- HSE: 8 MHz → PLL M=8, N=336, P=2 → SYSCLK = 168 MHz
- HCLK: 168 MHz (AHB DIV1), PCLK1: 42 MHz (APB1 DIV4), PCLK2: 84 MHz (APB2 DIV2)
- Flash latency: 5 wait states

To change the clock speed, modify `clock_init()` in `src/main.c`.

## Adding Peripherals / IRQ Handlers

To handle an interrupt, define a function with the exact IRQ handler name listed in `startup_stm32f407xx.s` (e.g., `void TIM2_IRQHandler(void)`). The weak alias in the startup file will be overridden automatically.

To place code or data in CCMRAM, use `__attribute__((section(".ccmram")))`. Note: initialized variables in CCMRAM require startup code changes to copy init values from Flash.

## IDE / LSP Support

`compile_commands.json` (in the project root) is used by clangd for IntelliSense and
diagnostics. It is generated automatically during `make`. `.clangd` contains clangd
configuration (e.g., target triple, compiler flags).

## Reference Documentation

- **UM1472** — STM32F4-Discovery User Manual (board schematic, LED pins, button pins)
- **RM0090** — STM32F4xx Reference Manual (GPIO, RCC, timers, and all other peripheral registers)
- **STM32F405xx/STM32F407xx Datasheet** — pin definitions, alternate function table, electrical characteristics
