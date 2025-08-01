#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <miniaudio.h>
#include <stdlib.h>

// Miniaudio context, device, and decoder
ma_context context;
ma_device device;
ma_decoder decoder;

// Lua function: Initialize miniaudio
static int lua_miniaudio_init(lua_State *L) {
    ma_result result = ma_context_init(NULL, 0, NULL, &context);
    if (result != MA_SUCCESS) {
        lua_pushstring(L, "Failed to initialize miniaudio context");
        lua_error(L);
    }
    return 0;
}

// Lua function: Load or reload a song
static int lua_miniaudio_load(lua_State *L) {
    const char *filepath = luaL_checkstring(L, 1); // Get file path from Lua

    // Uninitialize the existing decoder and device
    if (device.pContext != NULL) {
        ma_device_uninit(&device);
    }
    if (decoder.pBackend != NULL) {
        ma_decoder_uninit(&decoder);
    }

    // Load the new audio file
    ma_result result = ma_decoder_init_file(filepath, NULL, &decoder);
    if (result != MA_SUCCESS) {
        lua_pushstring(L, "Failed to load audio file");
        lua_error(L);
    }

    // Configure the device
    ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.playback.format = decoder.outputFormat;
    deviceConfig.playback.channels = decoder.outputChannels;
    deviceConfig.sampleRate = decoder.outputSampleRate;
    deviceConfig.dataCallback = ma_decoder_read_pcm_frames;
    deviceConfig.pUserData = &decoder;

    result = ma_device_init(NULL, &deviceConfig, &device);
    if (result != MA_SUCCESS) {
        ma_decoder_uninit(&decoder);
        lua_pushstring(L, "Failed to initialize playback device");
        lua_error(L);
    }

    lua_pushboolean(L, 1); // Return success
    return 1;
}

// Lua function: Play the loaded song
static int lua_miniaudio_play(lua_State *L) {
    ma_device_start(&device);
    lua_pushboolean(L, 1); // Return success
    return 1;
}

// Lua function: Stop playback
static int lua_miniaudio_stop(lua_State *L) {
    ma_device_stop(&device);
    return 0;
}

// Lua function: Set volume (0.0 to 1.0)
static int lua_miniaudio_set_volume(lua_State *L) {
    float volume = (float)luaL_checknumber(L, 1);
    ma_device_set_master_volume(&device, volume);
    return 0;
}

// Lua function: Seek to a specific position (in seconds)
static int lua_miniaudio_seek(lua_State *L) {
    double position = luaL_checknumber(L, 1); // Position in seconds
    ma_uint64 frame = (ma_uint64)(position * decoder.outputSampleRate);
    ma_decoder_seek_to_pcm_frame(&decoder, frame);
    return 0;
}

// Lua function: Get current position (in seconds)
static int lua_miniaudio_get_position(lua_State *L) {
    ma_uint64 frame;
    ma_decoder_get_cursor_in_pcm_frames(&decoder, &frame);
    double position = (double)frame / decoder.outputSampleRate;
    lua_pushnumber(L, position);
    return 1;
}

// Lua function: Set playback speed (1.0 = normal speed)
static int lua_miniaudio_set_speed(lua_State *L) {
    double speed = luaL_checknumber(L, 1);
    ma_decoder_set_read_pcm_frames_callback(&decoder, ma_decoder_read_pcm_frames);
    ma_decoder_set_seek_to_pcm_frame_callback(&decoder, ma_decoder_seek_to_pcm_frame);
    ma_decoder_set_output_sample_rate(&decoder, (ma_uint32)(decoder.outputSampleRate * speed));
    return 0;
}

// Lua function: Clean up miniaudio
static int lua_miniaudio_cleanup(lua_State *L) {
    ma_device_uninit(&device);
    ma_decoder_uninit(&decoder);
    ma_context_uninit(&context);
    return 0;
}

// Register Lua functions
static const luaL_Reg miniaudio_lib[] = {
    {"init", lua_miniaudio_init},
    {"load", lua_miniaudio_load},
    {"play", lua_miniaudio_play},
    {"stop", lua_miniaudio_stop},
    {"set_volume", lua_miniaudio_set_volume},
    {"seek", lua_miniaudio_seek},
    {"get_position", lua_miniaudio_get_position},
    {"set_speed", lua_miniaudio_set_speed},
    {"cleanup", lua_miniaudio_cleanup},
    {NULL, NULL}
};

// Lua module entry point
int luaopen_miniaudio(lua_State *L) {
    luaL_newlib(L, miniaudio_lib);
    return 1;
}
