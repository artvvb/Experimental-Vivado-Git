/*
 * demo.h
 *
 *  Created on: Jan 28, 2019
 *      Author: arthur
 */

#ifndef SRC_DEMO_H_
#define SRC_DEMO_H_

#include "xaxidma.h"
#include "xuartlite.h"
#include "xil_printf.h"
#include "wav/wav.h"
#include "gpio/gpio.h"
#include "dma/dma.h"

typedef enum DemoMode {
	DEMO_MODE_PAUSED = 0,
	DEMO_MODE_HW_TONE_GEN,
	DEMO_MODE_SW_TONE_GEN,
	DEMO_MODE_RECV_WAV_FILE,
	DEMO_MODE_PLAY_WAV_FILE
} DemoMode;

typedef struct {
	XAxiDma dma_inst;
	Gpio gpio_inst;
	XUartLite uart_inst;
	DemoMode mode;
	WavFile wav_file;
} Demo;

XStatus demo_init(Demo *p_demo_inst);

GpioIn_Data demo_update_mode(Demo *p_demo_inst);

#endif /* SRC_DEMO_H_ */
