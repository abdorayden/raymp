/****************************************************************************************/
/*  Copyright (c) 2025 Ray Den 								*/
/*  											*/ 
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
/*  of this software and associated documentation files (the "Software"), to deal 	*/
/*  in the Software without restriction, including without limitation the rights 	*/
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
/*  copies of the Software, and to permit persons to whom the Software is 		*/
/*  furnished to do so, subject to the following conditions: 				*/
/*  											*/ 
/*  The above copyright notice and this permission notice shall be included in 		*/
/*  all copies or substantial portions of the Software. 				*/
/*  											*/ 
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
/*  THE SOFTWARE. 									*/
/*  											*/ 
/****************************************************************************************/

/*
 *	rmpaudio.c is a neccesary bindings for lua rmp framework
 *	rmpaudio.c is part of raymp project
 * */

// TODO: make audio choose multi devices headphones and more ...

#include <math.h>
#include <string.h>
#include <stdlib.h>

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "simply.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


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

	// lua callback state
	int visualization_callback_ref;
	lua_State* callback_lua_state;

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

			if (rAudio.visualization_callback_ref != LUA_NOREF && rAudio.callback_lua_state) {
				lua_State* L = rAudio.callback_lua_state;

				// Check if lua state is still valid
				int top = lua_gettop(L);

				// Get the callback function
				lua_rawgeti(L, LUA_REGISTRYINDEX, rAudio.visualization_callback_ref);

				if (lua_isfunction(L, -1)) {
					// create frequency data table
					lua_createtable(L, (int)rAudio.freq_data_size, 0);
					for (size_t i = 0; i < rAudio.freq_data_size; i++) {
						lua_pushnumber(L, rAudio.freq_data[i]);
						lua_rawseti(L, -2, (int)i + 1);
					}

					// call the callback with protected call
					if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
						// handle error silently to avoid crashing audio thread
						lua_pop(L, 1);
					}
				} else {
					// Not a function, pop it
					lua_pop(L, 1);
				}

				// Restore stack
				lua_settop(L, top);
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

	// Clean up Lua callback reference
	if (rAudio.visualization_callback_ref != LUA_NOREF && rAudio.callback_lua_state) {
		luaL_unref(rAudio.callback_lua_state, LUA_REGISTRYINDEX, rAudio.visualization_callback_ref);
	}
	rAudio.visualization_callback_ref = LUA_NOREF;
	rAudio.callback_lua_state = NULL;
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

// lua bindings

// init function check and init the rmp audio ctx 
ALWAYS_INT lua_rmp_audio_init(STATE) {

	// we checked if the context is initialized or not 
	// and return true
	if (rAudio.is_initialized) {
		lua_pushboolean(L, 1);
		return 1;
	}

	memset(&rAudio, 0, sizeof(rAudio));
	rAudio.master_volume = 1.0f;
	rAudio.playback_speed = 1.0f;
	rAudio.visualization_callback_ref = LUA_NOREF;

	ma_result result = ma_context_init(NULL, 0, NULL, &rAudio.context);
	if (result != MA_SUCCESS) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Failed to initialize rmp audio context");
		return 2;
	}

	rAudio.is_initialized = MA_TRUE;
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_load(STATE) {

	// accept file path as argument in lua load function
	const char *filepath = luaL_checkstring(L, 1);

	// don't forget to initialize your audio system next timeee :)
	if (!rAudio.is_initialized) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "RMPAudio system not initialized");
		return 2;
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
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Failed to load audio file");
		return 2;
	}

	// get total length
	ma_decoder_get_length_in_pcm_frames(&rAudio.decoder, &rAudio.total_length);

	// initialize device
	result = initialize_device();
	if (result != MA_SUCCESS) {
		ma_decoder_uninit(&rAudio.decoder);
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Failed to initialize playback device");
		return 2;
	}

	reset_decoder_position();
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_play(STATE) {

	// u can't play the audio and no file are loaded
	if (!rAudio.is_device_active) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "No audio file loaded");
		return 2;
	}

	rAudio.is_paused = MA_FALSE;
	ma_result result = ma_device_start(&rAudio.device);

	lua_pushboolean(L, result == MA_SUCCESS ? 1 : 0); // lua function returns true if the sound start else false
	if (result != MA_SUCCESS) {
		lua_pushstring(L, "Failed to start playback"); // false , err
		return 2;
	}
	return 1;	// true
}

ALWAYS_INT lua_rmp_audio_pause(STATE) {
	if (!rAudio.is_device_active) {
		lua_pushboolean(L, 0);
		return 1;
	}

	rAudio.is_paused = MA_TRUE;
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_resume(STATE) {
	if (!rAudio.is_device_active) {
		lua_pushboolean(L, 0);
		return 1;
	}

	rAudio.is_paused = MA_FALSE;
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_stop(STATE) {
	if (rAudio.is_device_active) {
		ma_device_stop(&rAudio.device);
		reset_decoder_position();
	}

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_set_volume(STATE) {
	float volume = (float)luaL_checknumber(L, 1);
	rAudio.master_volume = fmaxf(0.0f, fminf(1.0f, volume));
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_get_volume(STATE) {
	lua_pushnumber(L, rAudio.master_volume);
	return 1;
}

ALWAYS_INT lua_rmp_audio_set_speed(STATE) {
	float speed = (float)luaL_checknumber(L, 1);
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

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_seek(STATE) {
	double position_seconds = luaL_checknumber(L, 1);

	if (rAudio.decoder.pBackend == NULL) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "No audio file loaded");
		return 2;
	}

	if (rAudio.decoder.outputSampleRate <= 0) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Invalid sample rate");
		return 2;
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
		lua_pushboolean(L, 1);
		return 1;
	} else {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Seek operation failed");
		return 2;
	}
}

ALWAYS_INT lua_rmp_audio_get_position(STATE) {
	if (rAudio.decoder.pBackend != NULL && rAudio.decoder.outputSampleRate > 0) {
		double position_seconds = (double)rAudio.current_position / rAudio.decoder.outputSampleRate;
		lua_pushnumber(L, position_seconds);
	} else {
		lua_pushnumber(L, 0.0);
	}
	return 1;
}

ALWAYS_INT lua_rmp_audio_get_duration(STATE) {
	if (rAudio.decoder.pBackend != NULL && rAudio.decoder.outputSampleRate > 0) {
		double duration_seconds = (double)rAudio.total_length / rAudio.decoder.outputSampleRate;
		lua_pushnumber(L, duration_seconds);
	} else {
		lua_pushnumber(L, 0.0);
	}
	return 1;
}

ALWAYS_INT lua_rmp_audio_is_playing(STATE) {
	ma_bool32 is_playing = rAudio.is_device_active && 
		ma_device_is_started(&rAudio.device) && 
		!rAudio.is_paused && 
		!rAudio.playback_finished;
	lua_pushboolean(L, is_playing);
	return 1;
}

ALWAYS_INT lua_rmp_audio_is_finished(STATE) {
	lua_pushboolean(L, rAudio.playback_finished);
	return 1;
}

ALWAYS_INT lua_rmp_audio_set_loop(STATE) {
	rAudio.loop_enabled = lua_toboolean(L, 1);
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_get_loop(STATE) {
	lua_pushboolean(L, rAudio.loop_enabled);
	return 1;
}

ALWAYS_INT lua_rmp_audio_is_valid(STATE) {
	lua_pushboolean(L, rAudio.decoder.pBackend != NULL);
	return 1;
}

ALWAYS_INT lua_rmp_audio_get_metadata(STATE) {
	lua_createtable(L, 0, 4);

	if (rAudio.decoder.pBackend != NULL) {
		lua_pushstring(L, "sample_rate");
		lua_pushinteger(L, rAudio.decoder.outputSampleRate);
		lua_settable(L, -3);

		lua_pushstring(L, "channels");
		lua_pushinteger(L, rAudio.decoder.outputChannels);
		lua_settable(L, -3);

		lua_pushstring(L, "format");
		lua_pushstring(L, ma_get_format_name(rAudio.decoder.outputFormat));
		lua_settable(L, -3);

		lua_pushstring(L, "duration");
		if (rAudio.decoder.outputSampleRate > 0) {
			double duration = (double)rAudio.total_length / rAudio.decoder.outputSampleRate;
			lua_pushnumber(L, duration);
		} else {
			lua_pushnumber(L, 0.0);
		}
		lua_settable(L, -3);
	}

	return 1;
}

ALWAYS_INT lua_rmp_audio_get_device_info(STATE) {
	lua_createtable(L, 0, 3);

	if (rAudio.is_device_active) {
		lua_pushstring(L, "name");
		lua_pushstring(L, rAudio.device.playback.name);
		lua_settable(L, -3);

		lua_pushstring(L, "sample_rate");
		lua_pushinteger(L, rAudio.device.sampleRate);
		lua_settable(L, -3);

		lua_pushstring(L, "channels");
		lua_pushinteger(L, rAudio.device.playback.channels);
		lua_settable(L, -3);
	}

	return 1;
}

ALWAYS_INT lua_rmp_audio_enable_visualization(STATE) {
	int freq_bins = luaL_optinteger(L, 1, 64);
	freq_bins = freq_bins > 0 ? freq_bins : 64;
	freq_bins = freq_bins > 1024 ? 1024 : freq_bins; // Limit max bins

	if (rAudio.freq_data) {
		free(rAudio.freq_data);
		rAudio.freq_data = NULL;
	}

	rAudio.freq_data = (float*)calloc(freq_bins, sizeof(float));
	if (!rAudio.freq_data) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Failed to allocate frequency data");
		return 2;
	}

	rAudio.freq_data_size = freq_bins;
	rAudio.enable_visualization = MA_TRUE;
	rAudio.callback_lua_state = L;

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_disable_visualization(STATE) {
	rAudio.enable_visualization = MA_FALSE;

	if (rAudio.freq_data) {
		free(rAudio.freq_data);
		rAudio.freq_data = NULL;
	}

	rAudio.freq_data_size = 0;

	if (rAudio.visualization_callback_ref != LUA_NOREF && rAudio.callback_lua_state) {
		luaL_unref(L, LUA_REGISTRYINDEX, rAudio.visualization_callback_ref);
		rAudio.visualization_callback_ref = LUA_NOREF;
	}

	rAudio.callback_lua_state = NULL;

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_set_visualization_callback(STATE) {
	if (!lua_isfunction(L, 1)) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Callback must be a function");
		return 2;
	}

	// remove previous callback reference
	if (rAudio.visualization_callback_ref != LUA_NOREF && rAudio.callback_lua_state) {
		luaL_unref(L, LUA_REGISTRYINDEX, rAudio.visualization_callback_ref);
	}

	// store new callback reference
	lua_pushvalue(L, 1);
	rAudio.visualization_callback_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	rAudio.callback_lua_state = L;

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_rmp_audio_get_frequency_data(STATE) {
	if (!rAudio.enable_visualization || !rAudio.freq_data) {
		lua_pushnil(L);
		return 1;
	}

	lua_createtable(L, (int)rAudio.freq_data_size, 0);
	for (size_t i = 0; i < rAudio.freq_data_size; i++) {
		lua_pushnumber(L, rAudio.freq_data[i]);
		lua_rawseti(L, -2, (int)i + 1);
	}

	return 1;
}

ALWAYS_INT lua_rmp_audio_cleanup(STATE) {
	cleanup_audio_context();
	lua_pushboolean(L, 1);
	return 1;
}

// Lua function registry
static const luaL_Reg rmp_audio_lib[] = {
	// Core functions
	{"Init", lua_rmp_audio_init},
	{"Load", lua_rmp_audio_load},
	{"Play", lua_rmp_audio_play},
	{"Pause", lua_rmp_audio_pause},
	{"Resume", lua_rmp_audio_resume},
	{"Stop", lua_rmp_audio_stop},
	{"Cleanup", lua_rmp_audio_cleanup},

	// Playback control
	{"SetVolume", lua_rmp_audio_set_volume},
	{"GetVolume", lua_rmp_audio_get_volume},
	{"SetSpeed", lua_rmp_audio_set_speed},
	{"Seek", lua_rmp_audio_seek},
	{"GetPosition", lua_rmp_audio_get_position},
	{"GetDuration", lua_rmp_audio_get_duration},

	// Loop control
	{"SetLoop", lua_rmp_audio_set_loop},
	{"GetLoop", lua_rmp_audio_get_loop},

	// Status queries
	{"IsPlaying", lua_rmp_audio_is_playing},
	{"IsFinished", lua_rmp_audio_is_finished},
	{"IsValid", lua_rmp_audio_is_valid},

	// Information
	{"GetMetadata", lua_rmp_audio_get_metadata},
	{"GetDeviceInfo", lua_rmp_audio_get_device_info},

	// Visualization
	// FIXME: lua_rmp_audio_enable_visualization it seg fault it
	// FIXME: lua_rmp_audio_set_visualization_callback i thing i don't need this function
	// TODO:  lua_rmp_audio_get_frequency_data works but it need to fill the freq data
	// TODO:  lua_rmp_audio_disable_visualization change the body with new implementation
	{"EnableVisualization", lua_rmp_audio_enable_visualization},
	{"DisableVisualization", lua_rmp_audio_disable_visualization},
	{"SetVisualizationCallback", lua_rmp_audio_set_visualization_callback},
	{"GetFrequencyData", lua_rmp_audio_get_frequency_data},

	{NULL, NULL}
};

int luaopen_rmp_rmpaudio(STATE) {
	luaL_newlib(L, rmp_audio_lib);
	return 1;
}
