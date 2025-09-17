#define MINIAUDIO_IMPLEMENTATION
#include "../../../third_party/miniaudio.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

ma_context context;
ma_device device;
ma_decoder decoder;

void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
	(void)pInput;
	ma_decoder* pDecoder = (ma_decoder*)pDevice->pUserData;
	if (pDecoder == NULL) return;

	ma_uint64 framesRead;
	ma_decoder_read_pcm_frames(pDecoder, pOutput, frameCount, &framesRead);

	if (framesRead < frameCount) {
		ma_silence_pcm_frames(pOutput, frameCount - framesRead, pDevice->playback.format, pDevice->playback.channels);
	}
}

static int lua_miniaudio_init(lua_State *L) {
	ma_result result = ma_context_init(NULL, 0, NULL, &context);
	if (result != MA_SUCCESS) {
		lua_pushstring(L, "[RMPError] Failed to initialize miniaudio context");
		lua_error(L);
	}
	return 0;
}

// load or reload
static int lua_miniaudio_load(lua_State *L) {
	const char *filepath = luaL_checkstring(L, 1);

	if (device.pContext != NULL) {
		ma_device_uninit(&device);
	}
	if (decoder.pBackend != NULL) {
		ma_decoder_uninit(&decoder);
	}

	ma_result result = ma_decoder_init_file(filepath, NULL, &decoder);
	if (result != MA_SUCCESS) {
		lua_pushstring(L, "[RMPError] Failed to load audio file");
		lua_error(L);
	}

	ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
	deviceConfig.playback.format = decoder.outputFormat;
	deviceConfig.playback.channels = decoder.outputChannels;
	deviceConfig.sampleRate = decoder.outputSampleRate;
	deviceConfig.dataCallback = data_callback;
	deviceConfig.pUserData = &decoder;

	result = ma_device_init(NULL, &deviceConfig, &device);
	if (result != MA_SUCCESS) {
		ma_decoder_uninit(&decoder);
		lua_pushstring(L, "[RMPError] Failed to initialize playback device");
		lua_error(L);
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_play(lua_State *L) {
	ma_device_start(&device);
	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_stop(lua_State *L) {
	(void)L;
	ma_device_stop(&device);
	return 0;
}

// set volume (0.0 to 1.0)
static int lua_miniaudio_set_volume(lua_State *L) {
	float volume = (float)luaL_checknumber(L, 1);
	ma_device_set_master_volume(&device, volume);
	return 0;
}

static int lua_miniaudio_seek(lua_State *L) {
	double position = luaL_checknumber(L, 1);
	ma_uint64 frame = (ma_uint64)(position * decoder.outputSampleRate);
	ma_decoder_seek_to_pcm_frame(&decoder, frame);
	return 0;
}

static int lua_miniaudio_get_position(lua_State *L) {
	ma_uint64 frame;
	ma_decoder_get_cursor_in_pcm_frames(&decoder, &frame);
	double position = (double)frame / decoder.outputSampleRate;
	lua_pushnumber(L, position);
	return 1;
}

// Lua function: Set playback speed (1.0 = normal speed)
//static int lua_miniaudio_set_speed(lua_State *L) {
//    double speed = luaL_checknumber(L, 1);
//
//    // Create a new data source with the desired speed
//    ma_data_source_config dataSourceConfig = ma_data_source_config_init(ma_format_f32, decoder.outputChannels, decoder.outputSampleRate);
//    ma_data_source* pDataSource = malloc(sizeof(ma_data_source));
//    ma_result result = ma_data_source_init(&dataSourceConfig, pDataSource);
//    if (result != MA_SUCCESS) {
//        lua_pushstring(L, "Failed to initialize data source");
//        lua_error(L);
//    }
//
//    // Set the playback speed
//    ma_data_source_set_next(pDataSource, &decoder, speed);
//
//    // Update the device's data source
//    ma_device_set_data_source(&device, pDataSource);
//
//    lua_pushboolean(L, 1); // Return success
//    return 1;
//}

static int lua_miniaudio_cleanup(lua_State *L) {
	(void)L;
	ma_device_uninit(&device);
	ma_decoder_uninit(&decoder);
	ma_context_uninit(&context);
	return 0;
}

static int lua_miniaudio_is_playing(lua_State *L) {
	lua_pushboolean(L, ma_device_is_started(&device));
	return 1;

}

static int lua_miniaudio_get_duration(lua_State *L) {
	ma_uint64 totalFrames;
	ma_result result = ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);

	if (result != MA_SUCCESS) {
		lua_pushstring(L, "[RMPError] Failed to get total duration");
		lua_error(L);
	}

	double duration = (double)totalFrames / decoder.outputSampleRate;
	lua_pushnumber(L, duration);
	return 1;
}

// get the current volume (0.0 to 1.0)
static int lua_miniaudio_get_volume(lua_State *L) {
	float volume;
	ma_result result = ma_device_get_master_volume(&device, &volume);

	if (result != MA_SUCCESS) {
		lua_pushstring(L, "[RMPError] Failed to get volume");
		lua_error(L);
	}

	lua_pushnumber(L, volume);
	return 1;
}

static int lua_miniaudio_pause(lua_State *L) {
	ma_device_stop(&device);
	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_resume(lua_State *L) {
	ma_device_start(&device);
	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_get_metadata(lua_State *L) {
	lua_newtable(L);

	lua_pushstring(L, "sample_rate");
	lua_pushinteger(L, decoder.outputSampleRate);
	lua_settable(L, -3);

	lua_pushstring(L, "channels");
	lua_pushinteger(L, decoder.outputChannels);
	lua_settable(L, -3);

	lua_pushstring(L, "format");
	lua_pushstring(L, ma_get_format_name(decoder.outputFormat));
	lua_settable(L, -3);

	return 1;
}

static int lua_miniaudio_get_device_info(lua_State *L) {
	lua_newtable(L);

	lua_pushstring(L, "name");
	lua_pushstring(L, device.playback.name);
	lua_settable(L, -3);

	lua_pushstring(L, "sample_rate");
	lua_pushinteger(L, device.sampleRate);
	lua_settable(L, -3);

	lua_pushstring(L, "channels");
	lua_pushinteger(L, device.playback.channels);
	lua_settable(L, -3);

	return 1;
}

static int lua_miniaudio_is_valid(lua_State *L) {
	lua_pushboolean(L, decoder.pBackend != NULL);
	return 1;
}

int is_playing = 0;

static int lua_miniaudio_set_speed(lua_State *L) {
	double speed = luaL_checknumber(L, 1);

	if (ma_device_is_started(&device)) {
		ma_device_stop(&device);
	}

	ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
	deviceConfig.playback.format = decoder.outputFormat;
	deviceConfig.playback.channels = decoder.outputChannels;
	deviceConfig.sampleRate = (ma_uint32)(decoder.outputSampleRate * speed);
	deviceConfig.dataCallback = data_callback;
	deviceConfig.pUserData = &decoder;

	ma_result result = ma_device_init(NULL, &deviceConfig, &device);
	if (result != MA_SUCCESS) {
		lua_pushstring(L, "[RMPError] Failed to initialize playback device");
		lua_error(L);
	}

	if (is_playing) {
		ma_device_start(&device);
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_play_to_end(lua_State *L) {
	if (!ma_device_is_started(&device)) {
		ma_device_start(&device);
	}

	ma_uint64 totalFrames;
	ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);

	double duration = (double)totalFrames / decoder.outputSampleRate;

	usleep((useconds_t)(duration * 1000000));

	ma_device_stop(&device);
	lua_pushboolean(L, 1);
	return 1;
}

static int lua_miniaudio_is_finished(lua_State *L) {
	if (!ma_device_is_started(&device)) {
		ma_uint64 cursor;
		ma_uint64 totalFrames;

		ma_decoder_get_cursor_in_pcm_frames(&decoder, &cursor);
		ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);

		lua_pushboolean(L, cursor >= totalFrames - 2);
	} else {
		lua_pushboolean(L, 0);
	}
	return 1;
}
// rmpaudio.c
// Register Lua functions
static const luaL_Reg miniaudio_lib[] = {
	{"Init", lua_miniaudio_init},
	{"IsAtTheEnd", lua_miniaudio_is_finished},
	{"PlayUntilFinished", lua_miniaudio_play_to_end},
	{"Load", lua_miniaudio_load},
	{"IsValid", lua_miniaudio_is_valid},
	{"GetAudioDeviceInformation", lua_miniaudio_get_device_info},
	{"SetSpeed", lua_miniaudio_set_speed},

	{"Pause", lua_miniaudio_pause},
	{"Resume", lua_miniaudio_resume},

	{"Play", lua_miniaudio_play},
	{"Stop", lua_miniaudio_stop},
	{"SetVolume", lua_miniaudio_set_volume},
	{"Seek", lua_miniaudio_seek},
	{"GetPosition", lua_miniaudio_get_position},
	{"IsPlaying", lua_miniaudio_is_playing},
	// {"set_speed", lua_miniaudio_set_speed},
	{"GetDuration", lua_miniaudio_get_duration},
	{"GetMetaData", lua_miniaudio_get_metadata},
	{"GetVolume", lua_miniaudio_get_volume},
	{"Clean", lua_miniaudio_cleanup},
	{NULL, NULL}
};
// Lua module entry point
int luaopen_rmp_rmpaudio(lua_State *L) {
	luaL_newlib(L, miniaudio_lib);
	return 1;
}
