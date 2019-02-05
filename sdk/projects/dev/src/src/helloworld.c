#include "xil_printf.h"
#include "xaxidma.h"
#include "xparameters.h"
#include "xstatus.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xuartlite.h"

#include "demo.h"
#include "dma/dma.h"
#include "wav/wav.h"
#include "gpio/gpio.h"

#define VERBOSE 0

#define DDR_BASE_ADDR		XPAR_MIG7SERIES_0_BASEADDR
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)

void init_hw() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_0_USE_ICACHE
	Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_0_USE_DCACHE
	Xil_DCacheEnable();
#endif
#endif
}

void dma_forward(Demo *p_demo_inst) {
	// TODO: modify tone_generator.v to support 8 bit audio...
	static const u32 BUFFER_SIZE_WORDS = 256;
	static const u32 BUFFER_SIZE_BYTES = 1024; //BUFFER_SIZE_WORDS * sizeof(u32));
	xil_printf("entered dma_forward\r\n");
	u8 *buffer = malloc(BUFFER_SIZE_BYTES);
	memset(buffer, 0, BUFFER_SIZE_BYTES);
	xil_printf("  1.\r\n");

	for (int i=0; i<BUFFER_SIZE_WORDS; i++) {
		dma_receive(&(p_demo_inst->dma_inst), (UINTPTR)((u32)buffer + sizeof(u32) * i), 4);
	}

	xil_printf("  2.\r\n");

	if (VERBOSE) {
		xil_printf("data received:\r\n");
		for (u32 word = 0; word < BUFFER_SIZE_WORDS; word++) {
			xil_printf("    %08x\r\n", ((u32*)buffer)[word]);
		}
	}

	dma_send(&(p_demo_inst->dma_inst), (UINTPTR)buffer, BUFFER_SIZE_BYTES);

	xil_printf("  3.\r\n");

	free(buffer);
}

void dma_sw_tone_gen(Demo *p_demo_inst) {
	static const u32 buffer_size = 128;
	u32 accum = 0;
	UINTPTR buffer = (UINTPTR)malloc(buffer_size * sizeof(u8));
	memset((u32*)buffer, 0, buffer_size * sizeof(u8));

	while (p_demo_inst->mode == DEMO_MODE_SW_TONE_GEN) {
		for (u32 i=0; i<buffer_size; i++) {
			accum += 0x00B22D0E;
			((u8*)buffer)[i] = accum>>24;
		}

		dma_send(&(p_demo_inst->dma_inst), (UINTPTR)buffer, buffer_size);

		demo_update_mode(p_demo_inst);
	}

	free((u32*)buffer);

	xil_printf("Exiting SW tone gen mode\r\n");

	dma_reset(&(p_demo_inst->dma_inst));
}

u32 uart_recv (Demo *p_demo_inst, u8 *buffer, u32 length) {
	//TODO: add timeout logic
	u32 received_count = 0;
	while (received_count < length) {
		received_count += XUartLite_Recv(&(p_demo_inst->uart_inst), (u8*)((u32)buffer + received_count), 1);
	}
	return received_count;
}
u8 *buf2str(u8 buffer[], u8 str[], int length) {
	memcpy(str, buffer, length);
	str[length] = 0;
	return str;
}
u32 buf2u32(u8 buffer[4]) {
	return ((u32)buffer[3] << 24) | ((u32)buffer[2] << 16) | ((u32)buffer[1] << 8) | ((u32)buffer[0]);
}
u16 buf2u16(u8 buffer[2]) {
	return ((u16)buffer[1] << 8) | ((u16)buffer[0]);
}

typedef enum {
	ENDIAN_LE = 0,
	ENDIAN_BE
} Endian;

u32 buf2unsigned(u8 buffer[], u32 bytes, Endian endian) {
	if (bytes > 4) return 0; // TODO: error
	u32 num = 0;
	if (endian == ENDIAN_LE) {
		for (u32 i=0; i<bytes; i++) {
			num |= ((u32)buffer[i]) << (i<<3);
		}
	} else {
		for (u32 i=bytes-1; i>=0; i--) {
			num |= ((u32)buffer[i]) << (i<<3);
		}
	}
	return num;
}

void switch_endianness(u8 buffer[], u32 bytes) {
	u8 *head_ptr = buffer;
	u8 *tail_ptr = buffer+bytes-1;
	while (head_ptr < tail_ptr) {
		u8 temp = *head_ptr;
		*head_ptr = *tail_ptr;
		*tail_ptr = temp;
		head_ptr++;
		tail_ptr--;
	}
}

void play_wav(Demo *p_demo_inst) {
	if (p_demo_inst->wav_file.file_ptr == 0) {
		xil_printf("The demo needs a file before playing one back\r\n");
		p_demo_inst->mode = DEMO_MODE_PAUSED;
		return;
	}

	xil_printf("Preparing for playback\r\n");

	// create dma buffer, downscale audio depth to 8bit.
	u8 *ptr = p_demo_inst->wav_file.data_buffer_ptr;
	u32 bytes_per_sample = p_demo_inst->wav_file.p_format->bits_per_sample >> 3;
	u32 block_align = p_demo_inst->wav_file.p_format->block_align;
	u32 dma_data_length = p_demo_inst->wav_file.p_data->data_chunk_size * sizeof(u8) / bytes_per_sample;
	u8 *dma_data = (u8*)malloc(dma_data_length);
	// TODO: modify sampling function to support non 16-bit wav files
// FIXME??? some kind of halt, plz debug
	for (int i=0; i < dma_data_length; i++) {
//		buf_switch_endianness(&(wav_data[i]), 2);
		u32 sample = buf2unsigned(ptr, bytes_per_sample, ENDIAN_BE);
		ptr += block_align; // note that we discard all samples not in the first channel, in the case of non-mono audio
		switch(bytes_per_sample) {
		case 1: dma_data[i] = sample; break;
		case 2: dma_data[i] = (u8)((u16)(sample + 32768) >> 8); break; // s16 to u8 conversion
		case 3: break;
		case 4: break;
		}
	}

	xil_printf("Waiting for transfer complete\r\n");

	dma_send(&(p_demo_inst->dma_inst), (UINTPTR)dma_data, dma_data_length);

	xil_printf("Transfer complete!\r\n");

	free(dma_data);

	p_demo_inst->mode = DEMO_MODE_PAUSED;
	xil_printf("Exiting playback mode\r\n");
	return;
}

void recv_wav (Demo *p_demo_inst) {
	const u32 max_file_size = 0x7FFFFF; // 16.777 MB

	if (p_demo_inst->wav_file.file_ptr != 0) {
		free(p_demo_inst->wav_file.file_ptr);
		p_demo_inst->wav_file.file_ptr = 0;
		p_demo_inst->wav_file.p_header = 0;
		p_demo_inst->wav_file.p_format = 0;
		p_demo_inst->wav_file.p_data = 0;
		p_demo_inst->wav_file.data_buffer_ptr = 0;
	}

	p_demo_inst->wav_file.file_ptr = malloc(max_file_size); // this will take most of the heap haha
	u8 *ptr = p_demo_inst->wav_file.file_ptr;
	u8  str[5];

	xil_printf("If you are using Tera Term, click \"File->Send File\" now.\r\n"
			   " Select the WAV file you want to transfer.\r\n"
			   " Make sure that \"Binary\" is checked.\r\n"
			   " Click \"Open\" to send the file.\r\n");

	uart_recv(p_demo_inst, ptr, sizeof(Wav_Header));

	XUartLite_Send(&(p_demo_inst->uart_inst), (u8*)"receiving...\r\n", 14);

	p_demo_inst->wav_file.p_header = (Wav_Header*)(ptr);
	ptr += sizeof(Wav_Header);

	u32 file_size = p_demo_inst->wav_file.p_header->overall_size + 8;

	uart_recv(p_demo_inst, ptr, p_demo_inst->wav_file.p_header->overall_size - 4);

	realloc(p_demo_inst->wav_file.file_ptr, file_size);

	p_demo_inst->wav_file.p_format = (Wav_FormatHeader*)(ptr);
	ptr += 8 + p_demo_inst->wav_file.p_format->fmt_chunk_size;

	p_demo_inst->wav_file.p_data = (Wav_DataHeader*)(ptr);
//	switch_endianness((u8*)(&p_demo_inst->wav_file.p_data->data_chunk_size), sizeof(u32));
	ptr += sizeof(Wav_DataHeader); // ptr now pointing at raw data buffer

	xil_printf("file info:\r\n");
	xil_printf("  header:\r\n");
	xil_printf("    riff: '%s'\r\n", buf2str(p_demo_inst->wav_file.p_header->riff, str, 4));
	xil_printf("    overall_size: %d\r\n", p_demo_inst->wav_file.p_header->overall_size);
	xil_printf("    wave: '%s'\r\n", buf2str(p_demo_inst->wav_file.p_header->wave, str, 4));
	xil_printf("  format:\r\n");
	xil_printf("    fmt_chunk_marker: '%s'\r\n", buf2str(p_demo_inst->wav_file.p_format->fmt_chunk_marker, str, 4));
	xil_printf("    fmt_chunk_size: %d\r\n", p_demo_inst->wav_file.p_format->fmt_chunk_size);
	xil_printf("    format_type: %d\r\n", p_demo_inst->wav_file.p_format->format_type);
	xil_printf("    channels: %d\r\n", p_demo_inst->wav_file.p_format->channels);
	xil_printf("    sample_rate: %d\r\n", p_demo_inst->wav_file.p_format->sample_rate);
	xil_printf("    byte_rate: %d\r\n", p_demo_inst->wav_file.p_format->byte_rate);
	xil_printf("    block_align: %d\r\n", p_demo_inst->wav_file.p_format->block_align);
	xil_printf("    bits_per_sample: %d\r\n", p_demo_inst->wav_file.p_format->bits_per_sample);
	xil_printf("  data:\r\n");
	xil_printf("    fmt_chunk_marker: '%s'\r\n", buf2str(p_demo_inst->wav_file.p_data->data_chunk_header, str, 4));
	xil_printf("    data_chunk_size: %d\r\n", p_demo_inst->wav_file.p_data->data_chunk_size);

	p_demo_inst->mode = DEMO_MODE_PAUSED;
	xil_printf("Exiting receive mode\r\n");

	return;
}

void demo_hw_tone_gen(Demo *p_demo_inst) {
	//UNIMPLEMENTED
	p_demo_inst->mode = DEMO_MODE_PAUSED;
	return;
}

int main() {
	Demo device;
	XStatus status;

	init_hw();

	xil_printf("----------------------------------------\r\n");
	xil_printf("entering main\r\n");

	status = demo_init(&device);
	if (status != XST_SUCCESS) {
		xil_printf("ERROR: Demo not initialized correctly\r\n");
		return 1;
	} else
		xil_printf("Demo started\r\n");

	while (1) {
		demo_update_mode(&device);

		switch (device.mode) {
		case DEMO_MODE_PAUSED:        break;
		case DEMO_MODE_HW_TONE_GEN:   demo_hw_tone_gen(&device); break;//dma_forward(&device); break;
		case DEMO_MODE_RECV_WAV_FILE: recv_wav(&device);         break;
		case DEMO_MODE_PLAY_WAV_FILE: play_wav(&device); 		 break;
		case DEMO_MODE_SW_TONE_GEN:   dma_sw_tone_gen(&device);  break;
		}
	}

	xil_printf("exiting main\r\n");
	return 0;
}
