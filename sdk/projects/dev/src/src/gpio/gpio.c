#include "gpio.h"

XStatus gpio_init(Gpio *p_gpio_inst, u16 gpio_out_device_id, u16 gpio_in_device_id) {
	XStatus status;

	status = XGpio_Initialize(&(p_gpio_inst->gpio_out_inst), gpio_out_device_id);
	if (status != XST_SUCCESS) return XST_FAILURE;
	XGpio_SetDataDirection(&(p_gpio_inst->gpio_out_inst), 1, 0x00); // RGB LED
	XGpio_SetDataDirection(&(p_gpio_inst->gpio_out_inst), 2, 0x0000); // LED
	xil_printf("%08x %08x\r\n",
			XGpio_GetDataDirection(&(p_gpio_inst->gpio_out_inst), 1),
			XGpio_GetDataDirection(&(p_gpio_inst->gpio_out_inst), 2)
	);

	status = XGpio_Initialize(&(p_gpio_inst->gpio_in_inst), gpio_in_device_id);
	if (status != XST_SUCCESS) return XST_FAILURE;
	XGpio_SetDataDirection(&(p_gpio_inst->gpio_in_inst), 1, 0x00); // BUTTON
	XGpio_SetDataDirection(&(p_gpio_inst->gpio_in_inst), 2, 0xFFFF); // SWITCH
	xil_printf("%08x %08x\r\n",
			XGpio_GetDataDirection(&(p_gpio_inst->gpio_in_inst), 1),
			XGpio_GetDataDirection(&(p_gpio_inst->gpio_in_inst), 2)
	);

	p_gpio_inst->last_data.button_ne = 0;
	p_gpio_inst->last_data.button_pe = 0;
	p_gpio_inst->last_data.buttons = 0;
	p_gpio_inst->last_data.switch_ne = 0;
	p_gpio_inst->last_data.switch_pe = 0;
	p_gpio_inst->last_data.switches = 0;

	return XST_SUCCESS;
}

GpioIn_Data gpio_get_data(Gpio *p_gpio_inst) {
	GpioIn_Data data;
	data.buttons = XGpio_DiscreteRead(&(p_gpio_inst->gpio_in_inst), 1);
	data.switches = XGpio_DiscreteRead(&(p_gpio_inst->gpio_in_inst), 2);
	data.button_pe = (data.buttons) & (~p_gpio_inst->last_data.buttons);
	data.button_ne = (~data.buttons) & (p_gpio_inst->last_data.buttons);
	data.switch_pe = (data.switches) & (~p_gpio_inst->last_data.switches);
	data.switch_ne = (~data.switches) & (p_gpio_inst->last_data.switches);
	p_gpio_inst->last_data = data;
	return data;
}
