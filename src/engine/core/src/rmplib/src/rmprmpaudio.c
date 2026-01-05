#include <math.h>
#include <string.h>
#include <stdlib.h>

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "../include/rmp_audio.h"

// RMPAudio context structure
typedef struct {
	ma_context context;
	ma_device device;
	ma_decoder decoder;
	ma_bool32 is_initialized;
	ma_bool32 is_device_active;
	ma_bool32 is_paused;
	ma_bool32 loop_enabled;
	float master_volume;
	float playback_speed;

	// for visualization
	float* freq_data;
	size_t freq_data_size;
	ma_bool32 enable_visualization;

	// playback state
	ma_uint64 current_position;
	ma_uint64 total_length;
	ma_bool32 playback_finished;

} RmpAudioCtx;

static RmpAudioCtx rAudio = {0};

static void cleanup_audio_context(void);
static void reset_decoder_position(void);
static ma_result initialize_device(void);

// the data callback
void enhanced_data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
	(void)pInput;

	if (!rAudio.is_initialized || rAudio.is_paused) {
		ma_silence_pcm_frames(pOutput, frameCount, pDevice->playback.format, pDevice->playback.channels);
		return;
	}

	ma_uint64 framesRead;
	ma_result result = ma_decoder_read_pcm_frames(&rAudio.decoder, pOutput, frameCount, &framesRead);

	if (result != MA_SUCCESS) {
		ma_silence_pcm_frames(pOutput, frameCount, pDevice->playback.format, pDevice->playback.channels);
		return;
	}

	rAudio.current_position += framesRead;

	if (framesRead < frameCount) {
		if (rAudio.loop_enabled) {
			reset_decoder_position();
			rAudio.current_position = 0;

			ma_uint64 remainingFrames = frameCount - framesRead;
			if (remainingFrames > 0) {
				void* pOutputOffset = (void*)((ma_uint8*)pOutput + (framesRead * ma_get_bytes_per_frame(pDevice->playback.format, pDevice->playback.channels)));
				ma_uint64 additionalFramesRead;
				ma_decoder_read_pcm_frames(&rAudio.decoder, pOutputOffset, remainingFrames, &additionalFramesRead);
				rAudio.current_position += additionalFramesRead;
				framesRead += additionalFramesRead;
			}
		} else {
			rAudio.playback_finished = MA_TRUE;
			ma_silence_pcm_frames((void*)((ma_uint8*)pOutput + (framesRead * ma_get_bytes_per_frame(pDevice->playback.format, pDevice->playback.channels))),
					frameCount - framesRead, pDevice->playback.format, pDevice->playback.channels);
		}
	}

	if (rAudio.master_volume != 1.0f && framesRead > 0) {
		ma_uint32 channels = pDevice->playback.channels;
		if (pDevice->playback.format == ma_format_f32) {
			float* samples = (float*)pOutput;
			for (ma_uint64 i = 0; i < framesRead * channels; i++) {
				samples[i] *= rAudio.master_volume;
			}
		}
	}

	if (rAudio.enable_visualization && rAudio.freq_data && framesRead > 0) {
		// simple frequency analysis (this is a basic implementation)
		// for production, you'd want to use fft
		if (pDevice->playback.format == ma_format_f32) {
			float* samples = (float*)pOutput;
			ma_uint32 channels = pDevice->playback.channels;

			memset(rAudio.freq_data, 0, rAudio.freq_data_size * sizeof(float));

			// basic frequency binning (simplified)
			size_t samples_per_bin = (framesRead * channels) / rAudio.freq_data_size;
			if (samples_per_bin > 0) {
				for (size_t bin = 0; bin < rAudio.freq_data_size; bin++) {
					float sum = 0.0f;
					size_t start_idx = bin * samples_per_bin;
					size_t end_idx = start_idx + samples_per_bin;

					for (size_t i = start_idx; i < end_idx && i < framesRead * channels; i++) {
						sum += fabsf(samples[i]);
					}

					rAudio.freq_data[bin] = sum / samples_per_bin;
				}
			}
		}
	}
}

static void cleanup_audio_context(void) {
	if (rAudio.is_device_active) {
		ma_device_uninit(&rAudio.device);
		rAudio.is_device_active = MA_FALSE;
	}

	if (rAudio.decoder.pBackend != NULL) {
		ma_decoder_uninit(&rAudio.decoder);
	}

	if (rAudio.is_initialized) {
		ma_context_uninit(&rAudio.context);
		rAudio.is_initialized = MA_FALSE;
	}

	if (rAudio.freq_data) {
		free(rAudio.freq_data);
		rAudio.freq_data = NULL;
	}

	rAudio.freq_data_size = 0;
	rAudio.enable_visualization = MA_FALSE;
}

static void reset_decoder_position(void) {
	ma_decoder_seek_to_pcm_frame(&rAudio.decoder, 0);
	rAudio.current_position = 0;
	rAudio.playback_finished = MA_FALSE;
}

static ma_result initialize_device(void) {
	if (rAudio.is_device_active) {
		ma_device_uninit(&rAudio.device);
		rAudio.is_device_active = MA_FALSE;
	}

	ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
	deviceConfig.playback.format = rAudio.decoder.outputFormat;
	deviceConfig.playback.channels = rAudio.decoder.outputChannels;
	deviceConfig.sampleRate = (ma_uint32)(rAudio.decoder.outputSampleRate * rAudio.playback_speed);
	deviceConfig.dataCallback = enhanced_data_callback;
	deviceConfig.pUserData = &rAudio;

	ma_result result = ma_device_init(&rAudio.context, &deviceConfig, &rAudio.device);
	if (result == MA_SUCCESS) {
		rAudio.is_device_active = MA_TRUE;
	}

	return result;
}

bool rmp_audio_init(void) {
	// we checked if the context is initialized or not
	// and return true
	if (rAudio.is_initialized) {
		return true;
	}

	memset(&rAudio, 0, sizeof(rAudio));
	rAudio.master_volume = 1.0f;
	rAudio.playback_speed = 1.0f;

	ma_result result = ma_context_init(NULL, 0, NULL, &rAudio.context);
	if (result != MA_SUCCESS) {
		return false;
	}

	rAudio.is_initialized = MA_TRUE;
	return true;
}

bool rmp_audio_load(const char* filepath) {
	if (!filepath) {
		return false;
	}

	// don't forget to initialize your audio system next timeee :)
	if (!rAudio.is_initialized) {
		return false;
	}

	// stop current playback if u load new audio file
	if (rAudio.is_device_active) {
		ma_device_stop(&rAudio.device);
		ma_device_uninit(&rAudio.device);
		rAudio.is_device_active = MA_FALSE;
	}

	// uninitialize previous decoder from the ctx
	if (rAudio.decoder.pBackend != NULL) {
		ma_decoder_uninit(&rAudio.decoder);
	}

	// load new file (the file we get above)
	ma_result result = ma_decoder_init_file(filepath, NULL, &rAudio.decoder);
	if (result != MA_SUCCESS) {
		return false;
	}

	// get total length
	ma_decoder_get_length_in_pcm_frames(&rAudio.decoder, &rAudio.total_length);

	// initialize device
	result = initialize_device();
	if (result != MA_SUCCESS) {
		ma_decoder_uninit(&rAudio.decoder);
		return false;
	}

	reset_decoder_position();
	return true;
}

bool rmp_audio_play(void) {
	// u can't play the audio and no file are loaded
	if (!rAudio.is_device_active) {
		return false;
	}

	rAudio.is_paused = MA_FALSE;
	ma_result result = ma_device_start(&rAudio.device);

	return result == MA_SUCCESS;
}

bool rmp_audio_pause(void) {
	if (!rAudio.is_device_active) {
		return false;
	}

	rAudio.is_paused = MA_TRUE;
	return true;
}

bool rmp_audio_resume(void) {
	if (!rAudio.is_device_active) {
		return false;
	}

	rAudio.is_paused = MA_FALSE;
	return true;
}

bool rmp_audio_stop(void) {
	if (rAudio.is_device_active) {
		ma_device_stop(&rAudio.device);
		reset_decoder_position();
	}

	return true;
}

bool rmp_audio_set_volume(float volume) {
	rAudio.master_volume = fmaxf(0.0f, fminf(1.0f, volume));
	return true;
}

float rmp_audio_get_volume(void) {
	return rAudio.master_volume;
}

bool rmp_audio_set_speed(float speed) {
	speed = fmaxf(0.25f, fminf(4.0f, speed));

	if (speed != rAudio.playback_speed) {
		rAudio.playback_speed = speed;

		// Reinitialize device with new sample rate
		if (rAudio.is_device_active && rAudio.decoder.pBackend != NULL) {
			ma_bool32 was_playing = ma_device_is_started(&rAudio.device);

			ma_result result = initialize_device();
			if (result == MA_SUCCESS && was_playing && !rAudio.is_paused) {
				ma_device_start(&rAudio.device);
			}
		}
	}

	return true;
}

bool rmp_audio_seek(double position_seconds) {
	if (rAudio.decoder.pBackend == NULL) {
		return false;
	}

	if (rAudio.decoder.outputSampleRate <= 0) {
		return false;
	}

	// Convert seconds to PCM frames
	ma_uint64 target_frame = (ma_uint64)(position_seconds * rAudio.decoder.outputSampleRate);

	// Clamp to valid range
	if (target_frame > rAudio.total_length) {
		target_frame = rAudio.total_length;
	}

	ma_result result = ma_decoder_seek_to_pcm_frame(&rAudio.decoder, target_frame);
	if (result == MA_SUCCESS) {
		rAudio.current_position = target_frame;
		rAudio.playback_finished = MA_FALSE;
		return true;
	} else {
		return false;
	}
}

double rmp_audio_get_position(void) {
	if (rAudio.decoder.pBackend != NULL && rAudio.decoder.outputSampleRate > 0) {
		return (double)rAudio.current_position / rAudio.decoder.outputSampleRate;
	} else {
		return 0.0;
	}
}

double rmp_audio_get_duration(void) {
	if (rAudio.decoder.pBackend != NULL && rAudio.decoder.outputSampleRate > 0) {
		return (double)rAudio.total_length / rAudio.decoder.outputSampleRate;
	} else {
		return 0.0;
	}
}

bool rmp_audio_is_playing(void) {
	ma_bool32 is_playing = rAudio.is_device_active &&
		ma_device_is_started(&rAudio.device) &&
		!rAudio.is_paused &&
		!rAudio.playback_finished;
	return is_playing;
}

bool rmp_audio_is_finished(void) {
	return rAudio.playback_finished;
}

void rmp_audio_set_loop(bool loop) {
	rAudio.loop_enabled = loop;
}

bool rmp_audio_get_loop(void) {
	return rAudio.loop_enabled;
}

bool rmp_audio_is_valid(void) {
	return rAudio.decoder.pBackend != NULL;
}

bool rmp_audio_enable_visualization(int freq_bins) {
	freq_bins = freq_bins > 0 ? freq_bins : 64;
	freq_bins = freq_bins > 1024 ? 1024 : freq_bins; // Limit max bins

	if (rAudio.freq_data) {
		free(rAudio.freq_data);
		rAudio.freq_data = NULL;
	}

	rAudio.freq_data = (float*)calloc(freq_bins, sizeof(float));
	if (!rAudio.freq_data) {
		return false;
	}

	rAudio.freq_data_size = freq_bins;
	rAudio.enable_visualization = MA_TRUE;

	return true;
}

bool rmp_audio_disable_visualization(void) {
	rAudio.enable_visualization = MA_FALSE;

	if (rAudio.freq_data) {
		free(rAudio.freq_data);
		rAudio.freq_data = NULL;
	}

	rAudio.freq_data_size = 0;

	return true;
}

bool rmp_audio_get_frequency_data(float* data, int* size) {
	if (!rAudio.enable_visualization || !rAudio.freq_data || !data || !size) {
		return false;
	}

	if (*size < (int)rAudio.freq_data_size) {
		return false;
	}

	memcpy(data, rAudio.freq_data, rAudio.freq_data_size * sizeof(float));
	*size = (int)rAudio.freq_data_size;
	return true;
}

bool rmp_audio_cleanup(void) {
	cleanup_audio_context();
	return true;
}