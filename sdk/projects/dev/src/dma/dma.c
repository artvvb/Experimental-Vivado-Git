#include "dma.h"

XStatus dma_init (XAxiDma *p_dma_inst, int dma_device_id) {
// Local variables
	XStatus status = 0;
	XAxiDma_Config* cfg_ptr;

	// Look up hardware configuration for device
	cfg_ptr = XAxiDma_LookupConfig(dma_device_id);
	if (!cfg_ptr)
	{
		xil_printf("ERROR! No hardware configuration found for AXI DMA with device id %d.\r\n", dma_device_id);
		return XST_FAILURE;
	}

	// Initialize driver
	status = XAxiDma_CfgInitialize(p_dma_inst, cfg_ptr);
	if (status != XST_SUCCESS)
	{
		xil_printf("ERROR! Initialization of AXI DMA failed with %d\r\n", status);
		return XST_FAILURE;
	}

	// Test for Scatter Gather
	if (XAxiDma_HasSg(p_dma_inst))
	{
		xil_printf("ERROR! Device configured as SG mode.\r\n");
		return XST_FAILURE;
	}

	// Disable all interrupts for both channels
	XAxiDma_IntrDisable(p_dma_inst, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(p_dma_inst, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

	// Reset DMA
	XAxiDma_Reset(p_dma_inst);
	while (!XAxiDma_ResetIsDone(p_dma_inst));

	xil_printf("Note: MaxTransferLen=%d\r\n", p_dma_inst->TxBdRing.MaxTransferLen);

	return XST_SUCCESS;
}

u8 dma_receive_is_busy(XAxiDma *p_dma_inst) {
	return XAxiDma_Busy(p_dma_inst, XAXIDMA_DEVICE_TO_DMA);
}
XStatus dma_receive(XAxiDma *p_dma_inst, UINTPTR buffer, u32 length) {
	XStatus status;

	Xil_DCacheFlushRange(buffer, length);

	status = XAxiDma_SimpleTransfer(p_dma_inst, buffer, length, XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) {
		xil_printf("ERROR: failed to kick off S2MM transfer\r\n");
		return XST_FAILURE;
	}

	u32 busy = 0;
	do {
		busy = XAxiDma_Busy(p_dma_inst, XAXIDMA_DEVICE_TO_DMA);
	} while (busy);

	if ((XAxiDma_ReadReg(p_dma_inst->RegBase, XAXIDMA_RX_OFFSET+XAXIDMA_SR_OFFSET) & XAXIDMA_IRQ_ERROR_MASK) != 0) {
		xil_printf("ERROR: AXI DMA returned an error during the S2MM transfer\r\n");
		return XST_FAILURE;
	}

	Xil_DCacheFlushRange(buffer, length);

	return XST_SUCCESS;
}
u8 dma_send_is_busy(XAxiDma *p_dma_inst) {
	return XAxiDma_Busy(p_dma_inst, XAXIDMA_DMA_TO_DEVICE);
}
XStatus dma_send(XAxiDma *p_dma_inst, UINTPTR buffer, u32 length) {
	XStatus status;

	Xil_DCacheFlushRange(buffer, length);

	status = XAxiDma_SimpleTransfer(p_dma_inst, buffer, length, XAXIDMA_DMA_TO_DEVICE);

	if (status != XST_SUCCESS)
		xil_printf("ERROR: failed to kick off MM2S transfer\r\n");

	while (XAxiDma_Busy(p_dma_inst, XAXIDMA_DMA_TO_DEVICE));

	if ((XAxiDma_ReadReg(p_dma_inst->RegBase, XAXIDMA_TX_OFFSET+XAXIDMA_SR_OFFSET) & XAXIDMA_IRQ_ERROR_MASK) != 0) {
		xil_printf("ERROR: AXI DMA returned an error during the MM2S transfer\r\n");
		return XST_FAILURE;
	}

	Xil_DCacheFlushRange((UINTPTR)buffer, length);

	return XST_SUCCESS;
}
void dma_reset(XAxiDma *p_dma_inst) {
	XAxiDma_Reset(p_dma_inst);
	while (!XAxiDma_ResetIsDone(p_dma_inst));
}
