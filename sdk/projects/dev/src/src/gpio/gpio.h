#ifndef SRC_GPIO_GPIO_H_
#define SRC_GPIO_GPIO_H_

#include "xstatus.h"
#include "xil_types.h"
#include "xgpio.h"

typedef struct GpioIn_Data {
	u8 buttons;
	u16 switches;
	u8 button_pe;
	u8 button_ne;
	u16 switch_pe;
	u16 switch_ne;
} GpioIn_Data;

typedef struct Gpio {
	XGpio gpio_out_inst;
	XGpio gpio_in_inst;
	GpioIn_Data last_data;
} Gpio;

XStatus gpio_init(Gpio *p_gpio_inst, u16 gpio_out_device_id, u16 gpio_in_device_id);

GpioIn_Data gpio_get_data(Gpio *p_gpio_inst);

#endif /* SRC_GPIO_GPIO_H_ */
