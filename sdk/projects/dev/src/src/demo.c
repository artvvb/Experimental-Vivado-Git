#include "demo.h"

XStatus demo_init(Demo *p_demo_inst) {
	XStatus status;

	status = gpio_init(&(p_demo_inst->gpio_inst), XPAR_GPIO_OUT_DEVICE_ID, XPAR_GPIO_IN_DEVICE_ID);

	XUartLite_Initialize(&(p_demo_inst->uart_inst), XPAR_AXI_UARTLITE_0_DEVICE_ID);
	XUartLite_DisableInterrupt(&(p_demo_inst->uart_inst));

	status = dma_init(&(p_demo_inst->dma_inst), XPAR_AXI_DMA_0_DEVICE_ID);
	if (status != XST_SUCCESS) return XST_FAILURE;

	p_demo_inst->wav_file.file_ptr = 0;
	p_demo_inst->mode = DEMO_MODE_PAUSED;

	return XST_SUCCESS;
}

GpioIn_Data demo_update_mode(Demo *p_demo_inst) {
	GpioIn_Data data = gpio_get_data(&(p_demo_inst->gpio_inst));

	switch (p_demo_inst->mode) {
	case DEMO_MODE_PAUSED:
		// buttons: 0b00000 = DRLUC
		switch (data.button_pe) {
		case 0x01: p_demo_inst->mode = DEMO_MODE_PAUSED;        xil_printf("Demo paused\r\n");                       break; // BUTTON C
		case 0x02: p_demo_inst->mode = DEMO_MODE_HW_TONE_GEN;   xil_printf("Demo generating 261 Hz tone in HW\r\n"); break; // BUTTON U
		case 0x04: p_demo_inst->mode = DEMO_MODE_RECV_WAV_FILE; xil_printf("Demo prepared to receive wav file\r\n"); break; // BUTTON L
		case 0x08: p_demo_inst->mode = DEMO_MODE_PLAY_WAV_FILE; xil_printf("Demo playing back wav file\r\n");        break; // BUTTON R
		case 0x10: p_demo_inst->mode = DEMO_MODE_SW_TONE_GEN;   xil_printf("Demo generating 261 Hz tone in SW\r\n"); break; // BUTTON D
		}
		break;
	case DEMO_MODE_SW_TONE_GEN:
		if (data.button_pe != 0) // press any button to cancel
			p_demo_inst->mode = DEMO_MODE_PAUSED;
		break;
	default:
		break;
	}

	return data;
}
