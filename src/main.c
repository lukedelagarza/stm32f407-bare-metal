#include "stm32f407xx.h"

void __libc_init_array(void) {

}

void clock_init(void) {
    RCC->CR |= RCC_CR_HSEON;
    while (!(RCC->CR & RCC_CR_HSERDY));
    RCC->PLLCFGR &= ~(RCC_PLLCFGR_PLLM_Msk
                 |    RCC_PLLCFGR_PLLN_Msk
                 |    RCC_PLLCFGR_PLLP_Msk
                 |    RCC_PLLCFGR_PLLSRC_Msk
                 |    RCC_PLLCFGR_PLLQ_Msk);
    RCC->PLLCFGR |= (8U << RCC_PLLCFGR_PLLM_Pos)
                 |  (336U << RCC_PLLCFGR_PLLN_Pos)
                 |  (0U << RCC_PLLCFGR_PLLP_Pos)
                 |  RCC_PLLCFGR_PLLSRC_HSE
                 |  (7U << RCC_PLLCFGR_PLLQ_Pos);
    RCC->CR |= RCC_CR_PLLON;
    while (!(RCC->CR & RCC_CR_PLLRDY));
    FLASH->ACR |= FLASH_ACR_LATENCY_5WS
               |  FLASH_ACR_PRFTEN
               |  FLASH_ACR_ICEN
               |  FLASH_ACR_DCEN;
    RCC->CFGR |= RCC_CFGR_HPRE_DIV1
              |  RCC_CFGR_PPRE1_DIV4
              |  RCC_CFGR_PPRE2_DIV2;
    RCC->CFGR |= RCC_CFGR_SW_PLL;
    while (!(RCC->CFGR & RCC_CFGR_SWS_PLL));
    return;
}

void main(void) {
    clock_init();
    while (1) {

    }
}
