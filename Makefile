
# Turn on increased build verbosity by defining BUILD_VERBOSE in your main
# Makefile or in your environment. You can also use V=1 on the make command
# line.

ifeq ("$(origin V)", "command line")
BUILD_VERBOSE=$(V)
endif
ifndef BUILD_VERBOSE
BUILD_VERBOSE = 0
endif
ifeq ($(BUILD_VERBOSE),0)
Q = @
else
Q =
endif
# Since this is a new feature, advertise it
ifeq ($(BUILD_VERBOSE),0)
$(info Use make V=1 or set BUILD_VERBOSE in your environment to increase build verbosity.)
endif

BUILD ?= build

RM = rm
ECHO = @echo

CROSS_COMPILE = arm-none-eabi-

AS = $(CROSS_COMPILE)as
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE = $(CROSS_COMPILE)size

TOP = ../../../../../..
INC =  -I../Inc
INC += -I$(TOP)/Drivers/STM32F4xx_HAL_Driver/Inc
INC += -I$(TOP)/Drivers/CMSIS/Device/ST/STM32F4xx/Include
INC += -I$(TOP)/Drivers/BSP/STM32F4-Discovery
INC += -I$(TOP)/Drivers/CMSIS/Include

CFLAGS_CORTEX_M4 = -mthumb -mtune=cortex-m4 -mabi=aapcs-linux -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -fsingle-precision-constant -Wdouble-promotion
CFLAGS = $(INC) -D STM32F407xx -Wall -ansi -std=gnu99 $(CFLAGS_CORTEX_M4) $(COPT)

#Debugging/Optimization
ifeq ($(DEBUG), 1)
CFLAGS += -g -DPENDSV_DEBUG
COPT = -O0
else
COPT += -Os -DNDEBUG
endif

LDFLAGS = --nostdlib -T STM32F407VG_FLASH.ld -Map=$(@:.elf=.map) --cref

OBJ = \
	build/startup_stm32f407xx.o \
	build/main.o \
	build/stm32f4xx_it.o \
	build/system_stm32f4xx.o \
	build/stm32f4_discovery.o \
	build/stm32f4xx_hal.o \
	build/stm32f4xx_hal_cortex.o \
	build/stm32f4xx_hal_dma.o \
	build/stm32f4xx_hal_gpio.o \
	build/stm32f4xx_hal_i2c.o \
	build/stm32f4xx_hal_rcc.o \
	build/stm32f4xx_hal_spi.o \

all: $(BUILD)/flash.elf

define compile_c
$(ECHO) "CC $<"
$(Q)$(CC) $(CFLAGS) -c -MD -o $@ $<
@# The following fixes the dependency file.
@# See http://make.paulandlesley.org/autodep.html for details.
@cp $(@:.o=.d) $(@:.o=.P); \
  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
      -e '/^$$/ d' -e 's/$$/ :/' < $(@:.o=.d) >> $(@:.o=.P); \
  rm -f $(@:.o=.d)
endef

$(OBJ): | $(BUILD)
$(BUILD):
	mkdir -p $@

vpath %.s .
$(BUILD)/%.o: %.s
	$(ECHO) "AS $<"
	$(Q)$(AS) -o $@ $<

vpath %.c ../Src $(TOP)/Drivers/BSP/STM32F4-Discovery $(TOP)/Drivers/STM32F4xx_HAL_Driver/Src
$(BUILD)/%.o: %.c
	$(call compile_c)

pgm: $(BUILD)/flash.bin
	dfu-util -a 0 -D $^ -s 0x8000000:leave

$(BUILD)/flash.bin: $(BUILD)/flash.elf
	$(OBJCOPY) -O binary $^ $@

$(BUILD)/flash.elf: $(OBJ)
	$(ECHO) "LINK $@"
	$(Q)$(LD) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)
	$(Q)$(SIZE) $@

clean:
	$(RM) -rf $(BUILD)
.PHONY: clean

-include $(OBJ:.o=.P)
