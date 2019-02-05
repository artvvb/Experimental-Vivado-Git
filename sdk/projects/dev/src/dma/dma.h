#ifndef SRC_DMA_DMA_H_
#define SRC_DMA_DMA_H_

#include "../demo.h"
#include "xaxidma.h"
#include "xil_printf.h"

XStatus dma_init (XAxiDma *p_dma_inst, int dma_device_id);
u8 dma_receive_is_busy(XAxiDma *p_dma_inst);
XStatus dma_receive(XAxiDma *p_dma_inst, UINTPTR buffer, u32 length);
u8 dma_send_is_busy(XAxiDma *p_dma_inst);
XStatus dma_send(XAxiDma *p_dma_inst, UINTPTR buffer, u32 length);
void dma_reset(XAxiDma *p_dma_inst);

#endif /* SRC_DMA_DMA_H_ */
