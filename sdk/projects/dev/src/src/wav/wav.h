#ifndef SRC_WAV_WAV_H_
#define SRC_WAV_WAV_H_


typedef struct {
	u8 riff[4];
	u32 overall_size; // u32
	u8 wave[4];
} Wav_Header;
typedef struct {
	u8 fmt_chunk_marker[4];
	u32 fmt_chunk_size; // u32
	u16 format_type; // u16
	u16 channels; // u16
	u32 sample_rate; // u32
	u32 byte_rate; // u32
	u16 block_align; // u16
	u16 bits_per_sample; // u16
} Wav_FormatHeader;
typedef struct {
	u8 data_chunk_header[4];
	u32 data_chunk_size; // u32
} Wav_DataHeader;

typedef struct {
	u8 *file_ptr;
	Wav_Header *p_header;
	Wav_FormatHeader *p_format;
	Wav_DataHeader *p_data;
	u8 *data_buffer_ptr;
} WavFile;

#endif /* SRC_WAV_WAV_H_ */
