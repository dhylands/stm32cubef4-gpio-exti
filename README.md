To use:

Grab a copy of the STM32Cube code from here: http://www.st.com/web/en/catalog/tools/PF259243#

Note that the latest version will probably be different from the version number below
(so update your path accordingly).

```
cd STM32Cube_FW_F4_V1.1.0/Projects/STM32F4-Discovery/Examples/GPIO/GPIO_EXTI
git clone https://github.com/dhylands/stm32cubef4-gpio-exti gcc
cd gcc
make
```

Put board in DFU mode
```
make pgm
```
