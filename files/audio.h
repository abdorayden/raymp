/*
 *	Audio.h is header only lib and part of raymp software
 *
 *	I stole all this code from raylib raudio.c file (raylib is a simple and easy-to-use library to enjoy videogames programming.)
 *	Link : https://www.raylib.com/
 *	Github Repo : https://github.com/raysan5/raylib
 *	Raylib Version : raylib v5.0
 *	RayLib LICENSE :
 *			Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
 *
 *	   This software is provided "as-is", without any express or implied warranty. In no event
 *	   will the authors be held liable for any damages arising from the use of this software.
 *	   
 *	   Permission is granted to anyone to use this software for any purpose, including commercial
 *	   applications, and to alter it and redistribute it freely, subject to the following restrictions:
 *	   
 *	     1. The origin of this software must not be misrepresented; you must not claim that you
 *	     wrote the original software. If you use this software in a product, an acknowledgment
 *	     in the product documentation would be appreciated but is not required.
 *	   
 *	     2. Altered source versions must be plainly marked as such, and must not be misrepresented
 *	     as being the original software.
 *	   
 *	     3. This notice may not be removed or altered from any source distribution.
 *
 * 	
 * 	it's really understandable function and hight level
 * */


#ifndef AUDIO_H_
#define AUDIO_H_

//#define MINIAUDIO_IMPLEMENTATION
//#include "./third_party/miniaudio.h"

typedef void (*AudioCallback)(void *bufferData, unsigned int frames);

#define TEXT_BYTES_PER_LINE     20

#ifndef AUDIO_DEVICE_FORMAT
    #define AUDIO_DEVICE_FORMAT    ma_format_f32    
#endif

#ifndef AUDIO_DEVICE_CHANNELS
    #define AUDIO_DEVICE_CHANNELS              2   
#endif

#ifndef AUDIO_DEVICE_SAMPLE_RATE
    #define AUDIO_DEVICE_SAMPLE_RATE           0  
#endif

#ifndef MAX_AUDIO_BUFFER_POOL_CHANNELS
    #define MAX_AUDIO_BUFFER_POOL_CHANNELS    16 
#endif

typedef enum{
	init_success = 0,

	init_context_f = -1,
	init_playback_device_f = -2,
	init_create_mutex_mixing_f = -3,
	init_start_playback_device = -4,
	init_not_initialized = -5,

	sound_create_buffer = -6 ,
	sound_format_conversion = -7,

}Error;

char* get_err(Error code){
	switch(code){
		case init_context_f : {
			return "AUDIO: Failed to initialize context";
		}
		case init_playback_device_f : {
			return "AUDIO: Failed to initialize playback device";	
		}
	        case init_create_mutex_mixing_f : {
			return "AUDIO: Failed to create mutex for mixing";	
		}
                case init_start_playback_device : {
			return "AUDIO: Failed to start playback device";
		}
		case init_not_initialized : {
			return "AUDIO: Device could not be closed, not currently initialized";
		}

		case sound_create_buffer : {
			return "SOUND: Failed to create buffer";
		}
		case sound_format_conversion : {
			return "SOUND: Failed format conversion";
		}
	}
}

typedef struct rAudioProcessor rAudioProcessor;

struct rAudioProcessor {
    AudioCallback process; 
    rAudioProcessor *next;  
    rAudioProcessor *prev;          
};

typedef struct rAudioBuffer rAudioBuffer;

struct rAudioBuffer {
    ma_data_converter converter;    

    AudioCallback callback;         
    rAudioProcessor *processor;     

    float volume;                   
    float pitch;                    
    float pan;                      

    bool playing;                   
    bool paused;                    
    bool looping;                   
    int usage;                      

    bool isSubBufferProcessed[2];   
    unsigned int sizeInFrames;      
    unsigned int frameCursorPos;    
    unsigned int framesProcessed;   

    unsigned char *data; 

    rAudioBuffer *next;             
    rAudioBuffer *prev;             
};

typedef rAudioBuffer AudioBuffer;

typedef struct AudioData {
    struct {
        ma_context context;         
        ma_device device;           
        ma_mutex lock;              
        bool isReady;               
        size_t pcmBufferSize;       
        void *pcmBuffer;            
    } System;
    struct {
        AudioBuffer *first;         
        AudioBuffer *last;          
        int defaultSize;            
    } Buffer;
    rAudioProcessor *mixedProcessor;
} AudioData;

static AudioData AUDIO = {
    .Buffer.defaultSize = 0,
    .mixedProcessor = NULL
};

typedef enum {
	AUDIO_BUFFER_USAGE_STATIC = 0,
	AUDIO_BUFFER_USAGE_STREAM
} AudioBufferUsage;

typedef struct Wave {
    unsigned int frameCount;    
    unsigned int sampleRate;    
    unsigned int sampleSize;    
    unsigned int channels;      
    void *data;                 
} Wave;

typedef struct AudioStream {
    rAudioBuffer *buffer;       
    rAudioProcessor *processor; 

    unsigned int sampleRate;    
    unsigned int sampleSize;    
    unsigned int channels;      
} AudioStream;

typedef struct Sound {
    AudioStream stream;         
    unsigned int frameCount;    
} Sound;

Error InitAudioDevice(void);
Error CloseAudioDevice(void);
bool IsAudioDeviceReady(void);
void SetMasterVolume(float volume);
float GetMasterVolume(void);
bool IsAudioStreamReady(AudioStream stream);

void UnloadFileData(unsigned char *data);
Wave LoadWave(const char *fileName);
Wave LoadWaveFromMemory(const char *fileType, const unsigned char *fileData, int dataSize);
bool IsWaveReady(Wave wave);
Error LoadSound(const char *fileName, Sound* sound);
Error LoadSoundFromWave(Wave wave , Sound* sound);
Sound LoadSoundAlias(Sound source);
bool IsSoundReady(Sound sound);
void UpdateSound(Sound sound, const void *data, int sampleCount);
void UnloadWave(Wave wave);
void UnloadSound(Sound sound);
void UnloadSoundAlias(Sound alias);
bool ExportWave(Wave wave, const char *fileName);
void UnloadAudioStream(AudioStream stream);
void UpdateAudioStream(AudioStream stream, const void *data, int frameCount);
// TODO: add Seek Sound Funcion
bool IsAudioStreamProcessed(AudioStream stream);
void PlayAudioStream(AudioStream stream);
void PauseAudioStream(AudioStream stream);
void ResumeAudioStream(AudioStream stream);
bool IsAudioStreamPlaying(AudioStream stream);
void StopAudioStream(AudioStream stream);
void DetachAudioMixedProcessor(AudioCallback process);
void AttachAudioMixedProcessor(AudioCallback process);
void DetachAudioStreamProcessor(AudioStream stream, AudioCallback process);
void AttachAudioStreamProcessor(AudioStream stream, AudioCallback process);
void SetAudioStreamCallback(AudioStream stream, AudioCallback callback);
void SetAudioStreamBufferSizeDefault(int size);
void SetAudioStreamVolume(AudioStream stream, float volume);
void SetAudioStreamPitch(AudioStream stream, float pitch);
void SetAudioStreamPan(AudioStream stream, float pan);

AudioBuffer *LoadAudioBuffer(ma_format format, ma_uint32 channels, ma_uint32 sampleRate, ma_uint32 sizeInFrames, int usage);
void UnloadAudioBuffer(AudioBuffer *buffer);

bool IsAudioBufferPlaying(AudioBuffer *buffer);
void PlayAudioBuffer(AudioBuffer *buffer);
void StopAudioBuffer(AudioBuffer *buffer);
void PauseAudioBuffer(AudioBuffer *buffer);
void ResumeAudioBuffer(AudioBuffer *buffer);
void SetAudioBufferVolume(AudioBuffer *buffer, float volume);
void SetAudioBufferPitch(AudioBuffer *buffer, float pitch);
void SetAudioBufferPan(AudioBuffer *buffer, float pan);
void TrackAudioBuffer(AudioBuffer *buffer);
void UntrackAudioBuffer(AudioBuffer *buffer);

void MixAudioFrames(float *framesOut, const float *framesIn, ma_uint32 frameCount, AudioBuffer *buffer);
void OnLog(void *pUserData, ma_uint32 level, const char *pMessage);
void OnSendAudioDataToDevice(ma_device *pDevice, void *pFramesOut, const void *pFramesInput, ma_uint32 frameCount);
bool IsAudioBufferPlayingInLockedState(AudioBuffer *buffer);
void StopAudioBufferInLockedState(AudioBuffer *buffer);
void UpdateAudioStreamInLockedState(AudioStream stream, const void *data, int frameCount);
bool IsFileExtension(const char *fileName, const char *ext);
const char *GetFileExtension(const char *fileName);
const char *strprbrk(const char *s, const char *charset);
const char *GetFileName(const char *filePath);
const char *GetFileNameWithoutExt(const char *filePath);
unsigned char *LoadFileData(const char *fileName, int *dataSize);
bool SaveFileData(const char *fileName, void *data, int dataSize);
bool SaveFileText(const char *fileName, char *text);

bool ExportWaveAsCode(Wave wave, const char *fileName);

void PlaySound(Sound sound);
void StopSound(Sound sound);
void PauseSound(Sound sound);
void ResumeSound(Sound sound);
bool IsSoundPlaying(Sound sound);
void SetSoundVolume(Sound sound, float volume);
void SetSoundPitch(Sound sound, float pitch);
void SetSoundPan(Sound sound, float pan);
Wave WaveCopy(Wave wave);
void WaveCrop(Wave *wave, int initSample, int finalSample);
void WaveFormat(Wave *wave, int sampleRate, int sampleSize, int channels);
float *LoadWaveSamples(Wave wave);
void UnloadWaveSamples(float *samples);
#endif //AUDIO_H_

#ifdef AUDIO_C_

#define MA_COINIT_VALUE  2

Error InitAudioDevice(void)
{
    ma_context_config ctxConfig = ma_context_config_init();
    ma_log_callback_init(OnLog, NULL);

    ma_result result = ma_context_init(NULL, 0, &ctxConfig, &AUDIO.System.context);
    if (result != MA_SUCCESS)
    {
        return init_context_f;
    }

    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.pDeviceID = NULL;  // NULL for the default playback AUDIO.System.device
    config.playback.format = AUDIO_DEVICE_FORMAT;
    config.playback.channels = AUDIO_DEVICE_CHANNELS;
    config.capture.pDeviceID = NULL;  // NULL for the default capture AUDIO.System.device
    config.capture.format = ma_format_s16;
    config.capture.channels = 1;
    config.sampleRate = AUDIO_DEVICE_SAMPLE_RATE;
    config.dataCallback = OnSendAudioDataToDevice;
    config.pUserData = NULL;

    result = ma_device_init(&AUDIO.System.context, &config, &AUDIO.System.device);
    if (result != MA_SUCCESS)
    {
        ma_context_uninit(&AUDIO.System.context);
        return init_playback_device_f;
    }

    if (ma_mutex_init(&AUDIO.System.lock) != MA_SUCCESS)
    {
        ma_device_uninit(&AUDIO.System.device);
        ma_context_uninit(&AUDIO.System.context);
        return init_create_mutex_mixing_f;
    }

    result = ma_device_start(&AUDIO.System.device);
    if (result != MA_SUCCESS)
    {
        ma_device_uninit(&AUDIO.System.device);
        ma_context_uninit(&AUDIO.System.context);
        return init_start_playback_device;
    }
    AUDIO.System.isReady = true;
    return init_success;
}

void UnloadFileData(unsigned char *data)
{
    free(data);
}

Error CloseAudioDevice(void)
{
    if (AUDIO.System.isReady)
    {
        ma_mutex_uninit(&AUDIO.System.lock);
        ma_device_uninit(&AUDIO.System.device);
        ma_context_uninit(&AUDIO.System.context);

        AUDIO.System.isReady = false;
        free(AUDIO.System.pcmBuffer);
        AUDIO.System.pcmBuffer = NULL;
        AUDIO.System.pcmBufferSize = 0;
	return init_success;
    }
    else return init_not_initialized;
}

bool IsAudioDeviceReady(void)
{
    return AUDIO.System.isReady;
}

void SetMasterVolume(float volume)
{
    ma_device_set_master_volume(&AUDIO.System.device, volume);
}

float GetMasterVolume(void)
{
    float volume = 0.0f;
    ma_device_get_master_volume(&AUDIO.System.device, &volume);
    return volume;
}

AudioBuffer *LoadAudioBuffer(ma_format format, ma_uint32 channels, ma_uint32 sampleRate, ma_uint32 sizeInFrames, int usage)
{
    AudioBuffer *audioBuffer = (AudioBuffer *)calloc(1, sizeof(AudioBuffer));

    if (audioBuffer == NULL)
    {
        //TRACELOG(LOG_WARNING, "AUDIO: Failed to allocate memory for buffer");
        return NULL;
    }

    if (sizeInFrames > 0) audioBuffer->data = calloc(sizeInFrames*channels*ma_get_bytes_per_sample(format), 1);

    ma_data_converter_config converterConfig = ma_data_converter_config_init(format, AUDIO_DEVICE_FORMAT, channels, AUDIO_DEVICE_CHANNELS, sampleRate, AUDIO.System.device.sampleRate);
    converterConfig.allowDynamicSampleRate = true;

    ma_result result = ma_data_converter_init(&converterConfig, NULL, &audioBuffer->converter);

    if (result != MA_SUCCESS)
    {
        //TRACELOG(LOG_WARNING, "AUDIO: Failed to create data conversion pipeline");
        free(audioBuffer);
        return NULL;
    }

    audioBuffer->volume = 1.0f;
    audioBuffer->pitch = 1.0f;
    audioBuffer->pan = 0.5f;

    audioBuffer->callback = NULL;
    audioBuffer->processor = NULL;

    audioBuffer->playing = false;
    audioBuffer->paused = false;
    audioBuffer->looping = false;

    audioBuffer->usage = usage;
    audioBuffer->frameCursorPos = 0;
    audioBuffer->sizeInFrames = sizeInFrames;

    audioBuffer->isSubBufferProcessed[0] = true;
    audioBuffer->isSubBufferProcessed[1] = true;

    TrackAudioBuffer(audioBuffer);

    return audioBuffer;
}

void UnloadAudioBuffer(AudioBuffer *buffer)
{
    if (buffer != NULL)
    {
        UntrackAudioBuffer(buffer);
        ma_data_converter_uninit(&buffer->converter, NULL);
        free(buffer->data);
        free(buffer);
    }
}

bool IsAudioBufferPlaying(AudioBuffer *buffer)
{
    bool result = false;
    ma_mutex_lock(&AUDIO.System.lock);
    result = IsAudioBufferPlayingInLockedState(buffer);
    ma_mutex_unlock(&AUDIO.System.lock);
    return result;
}

// Play an audio buffer
// NOTE: Buffer is restarted to the start
// Use PauseAudioBuffer() and ResumeAudioBuffer() if the playback position should be maintained
void PlayAudioBuffer(AudioBuffer *buffer)
{
    if (buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        buffer->playing = true;
        buffer->paused = false;
        buffer->frameCursorPos = 0;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Stop an audio buffer from a program state without lock
void StopAudioBuffer(AudioBuffer *buffer)
{
    ma_mutex_lock(&AUDIO.System.lock);
    StopAudioBufferInLockedState(buffer);
    ma_mutex_unlock(&AUDIO.System.lock);
}

// Pause an audio buffer
void PauseAudioBuffer(AudioBuffer *buffer)
{
    if (buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        buffer->paused = true;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Resume an audio buffer
void ResumeAudioBuffer(AudioBuffer *buffer)
{
    if (buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        buffer->paused = false;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Set volume for an audio buffer
void SetAudioBufferVolume(AudioBuffer *buffer, float volume)
{
    if (buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        buffer->volume = volume;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Set pitch for an audio buffer
void SetAudioBufferPitch(AudioBuffer *buffer, float pitch)
{
    if ((buffer != NULL) && (pitch > 0.0f))
    {
        ma_mutex_lock(&AUDIO.System.lock);
        // Pitching is just an adjustment of the sample rate
        // Note that this changes the duration of the sound:
        //  - higher pitches will make the sound faster
        //  - lower pitches make it slower
        ma_uint32 outputSampleRate = (ma_uint32)((float)buffer->converter.sampleRateOut/pitch);
        ma_data_converter_set_rate(&buffer->converter, buffer->converter.sampleRateIn, outputSampleRate);

        buffer->pitch = pitch;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Set pan for an audio buffer
void SetAudioBufferPan(AudioBuffer *buffer, float pan)
{
    if (pan < 0.0f) pan = 0.0f;
    else if (pan > 1.0f) pan = 1.0f;

    if (buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        buffer->pan = pan;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Track audio buffer to linked list next position
void TrackAudioBuffer(AudioBuffer *buffer)
{
    ma_mutex_lock(&AUDIO.System.lock);
    {
        if (AUDIO.Buffer.first == NULL) AUDIO.Buffer.first = buffer;
        else
        {
            AUDIO.Buffer.last->next = buffer;
            buffer->prev = AUDIO.Buffer.last;
        }

        AUDIO.Buffer.last = buffer;
    }
    ma_mutex_unlock(&AUDIO.System.lock);
}

// Untrack audio buffer from linked list
void UntrackAudioBuffer(AudioBuffer *buffer)
{
    ma_mutex_lock(&AUDIO.System.lock);
    {
        if (buffer->prev == NULL) AUDIO.Buffer.first = buffer->next;
        else buffer->prev->next = buffer->next;

        if (buffer->next == NULL) AUDIO.Buffer.last = buffer->prev;
        else buffer->next->prev = buffer->prev;

        buffer->prev = NULL;
        buffer->next = NULL;
    }
    ma_mutex_unlock(&AUDIO.System.lock);
}

Wave LoadWave(const char *fileName)
{
    Wave wave = { 0 };

    int dataSize = 0;
    unsigned char *fileData = LoadFileData(fileName, &dataSize);

    if (fileData != NULL) wave = LoadWaveFromMemory(GetFileExtension(fileName), fileData, dataSize);

    UnloadFileData(fileData);
    return wave;
}

// Load wave from memory buffer, fileType refers to extension: i.e. ".wav"
// WARNING: File extension must be provided in lower-case
Wave LoadWaveFromMemory(const char *fileType, const unsigned char *fileData, int dataSize)
{
    Wave wave = { 0 };

    if (false) { }
    else if ((strcmp(fileType, ".wav") == 0) || (strcmp(fileType, ".WAV") == 0))
    {
        drwav wav = { 0 };
        bool success = drwav_init_memory(&wav, fileData, dataSize, NULL);

        if (success)
        {
            wave.frameCount = (unsigned int)wav.totalPCMFrameCount;
            wave.sampleRate = wav.sampleRate;
            wave.sampleSize = 16;
            wave.channels = wav.channels;
            wave.data = (short *)malloc(wave.frameCount*wave.channels*sizeof(short));

            // NOTE: We are forcing conversion to 16bit sample size on reading
            drwav_read_pcm_frames_s16(&wav, wav.totalPCMFrameCount, wave.data);
        }
        else //TRACELOG(LOG_WARNING, "WAVE: Failed to load WAV data");

        drwav_uninit(&wav);
    }
    //else if ((strcmp(fileType, ".ogg") == 0) || (strcmp(fileType, ".OGG") == 0))
    //{
    //    stb_vorbis *oggData = stb_vorbis_open_memory((unsigned char *)fileData, dataSize, NULL, NULL);

    //    if (oggData != NULL)
    //    {
    //        stb_vorbis_info info = stb_vorbis_get_info(oggData);

    //        wave.sampleRate = info.sample_rate;
    //        wave.sampleSize = 16;       // By default, ogg data is 16 bit per sample (short)
    //        wave.channels = info.channels;
    //        wave.frameCount = (unsigned int)stb_vorbis_stream_length_in_samples(oggData);  // NOTE: It returns frames!
    //        wave.data = (short *)malloc(wave.frameCount*wave.channels*sizeof(short));

    //        // NOTE: Get the number of samples to process (be careful! we ask for number of shorts, not bytes!)
    //        stb_vorbis_get_samples_short_interleaved(oggData, info.channels, (short *)wave.data, wave.frameCount*wave.channels);
    //        stb_vorbis_close(oggData);
    //    }
    //    else //TRACELOG(LOG_WARNING, "WAVE: Failed to load OGG data");
    //}
    else if ((strcmp(fileType, ".mp3") == 0) || (strcmp(fileType, ".MP3") == 0))
    {
        drmp3_config config = { 0 };
        unsigned long long int totalFrameCount = 0;

        // NOTE: We are forcing conversion to 32bit float sample size on reading
        wave.data = drmp3_open_memory_and_read_pcm_frames_f32(fileData, dataSize, &config, &totalFrameCount, NULL);
        wave.sampleSize = 32;

        if (wave.data != NULL)
        {
            wave.channels = config.channels;
            wave.sampleRate = config.sampleRate;
            wave.frameCount = (int)totalFrameCount;
        }
        //else //TRACELOG(LOG_WARNING, "WAVE: Failed to load MP3 data");

    }
    //else if ((strcmp(fileType, ".qoa") == 0) || (strcmp(fileType, ".QOA") == 0))
    //{
    //    qoa_desc qoa = { 0 };

    //    // NOTE: Returned sample data is always 16 bit?
    //    wave.data = qoa_decode(fileData, dataSize, &qoa);
    //    wave.sampleSize = 16;

    //    if (wave.data != NULL)
    //    {
    //        wave.channels = qoa.channels;
    //        wave.sampleRate = qoa.samplerate;
    //        wave.frameCount = qoa.samples;
    //    }
    //    else //TRACELOG(LOG_WARNING, "WAVE: Failed to load QOA data");

    //}
    else if ((strcmp(fileType, ".flac") == 0) || (strcmp(fileType, ".FLAC") == 0))
    {
        unsigned long long int totalFrameCount = 0;

        // NOTE: We are forcing conversion to 16bit sample size on reading
        wave.data = drflac_open_memory_and_read_pcm_frames_s16(fileData, dataSize, &wave.channels, &wave.sampleRate, &totalFrameCount, NULL);
        wave.sampleSize = 16;

        if (wave.data != NULL) wave.frameCount = (unsigned int)totalFrameCount;
        //else //TRACELOG(LOG_WARNING, "WAVE: Failed to load FLAC data");
    }
    //else //TRACELOG(LOG_WARNING, "WAVE: Data format not supported");

    //TRACELOG(LOG_INFO, "WAVE: Data loaded successfully (%i Hz, %i bit, %i channels)", wave.sampleRate, wave.sampleSize, wave.channels);

    return wave;
}

// Checks if wave data is ready
bool IsWaveReady(Wave wave)
{
    bool result = false;

    if ((wave.data != NULL) &&      // Validate wave data available
        (wave.frameCount > 0) &&    // Validate frame count
        (wave.sampleRate > 0) &&    // Validate sample rate is supported
        (wave.sampleSize > 0) &&    // Validate sample size is supported
        (wave.channels > 0)) result = true; // Validate number of channels supported

    return result;
}

// Load sound from file
// NOTE: The entire file is loaded to memory to be played (no-streaming)
int LoadSound(const char *fileName , Sound* sound)
{
    Wave wave = LoadWave(fileName);
    Err err;
    if((err = LoadSoundFromWave(wave , sound)) != 0){ 	
    		UnloadWave(wave);       // Sound is loaded, we can unload wave
	    return err; 
    }


    return 0;
}

// Load sound from wave data
// NOTE: Wave data must be unallocated manually
int LoadSoundFromWave(Wave wave , Sound* sound)
{
    if (wave.data != NULL)
    {
        ma_format formatIn = ((wave.sampleSize == 8)? ma_format_u8 : ((wave.sampleSize == 16)? ma_format_s16 : ma_format_f32));
        ma_uint32 frameCountIn = wave.frameCount;

        ma_uint32 frameCount = (ma_uint32)ma_convert_frames(NULL, 0, AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO.System.device.sampleRate, NULL, frameCountIn, formatIn, wave.channels, wave.sampleRate);
        //if (frameCount == 0) //TRACELOG(LOG_WARNING, "SOUND: Failed to get frame count for format conversion");

        AudioBuffer *audioBuffer = LoadAudioBuffer(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO.System.device.sampleRate, frameCount, AUDIO_BUFFER_USAGE_STATIC);
        if (audioBuffer == NULL)
        {
            //TRACELOG(LOG_WARNING, "SOUND: Failed to create buffer");
            return -5; // early return to avoid dereferencing the audioBuffer null pointer
        }

        frameCount = (ma_uint32)ma_convert_frames(audioBuffer->data, frameCount, AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO.System.device.sampleRate, wave.data, frameCountIn, formatIn, wave.channels, wave.sampleRate);
        if (frameCount == 0){ 
		//TRACELOG(LOG_WARNING, "SOUND: Failed format conversion");
		return -6;
	}

        sound->frameCount = frameCount;
        sound->stream.sampleRate = AUDIO.System.device.sampleRate;
        sound->stream.sampleSize = 32;
        sound->stream.channels = AUDIO_DEVICE_CHANNELS;
        sound->stream.buffer = audioBuffer;
    }

    return 0;
}

// Clone sound from existing sound data, clone does not own wave data
// NOTE: Wave data must be unallocated manually and will be shared across all clones
Sound LoadSoundAlias(Sound source)
{
    Sound sound = { 0 };

    if (source.stream.buffer->data != NULL)
    {
        AudioBuffer *audioBuffer = LoadAudioBuffer(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO.System.device.sampleRate, 0, AUDIO_BUFFER_USAGE_STATIC);

        if (audioBuffer == NULL)
        {
            //TRACELOG(LOG_WARNING, "SOUND: Failed to create buffer");
            return sound; // Early return to avoid dereferencing the audioBuffer null pointer
        }

        audioBuffer->sizeInFrames = source.stream.buffer->sizeInFrames;
        audioBuffer->volume = source.stream.buffer->volume;
        audioBuffer->data = source.stream.buffer->data;

        sound.frameCount = source.frameCount;
        sound.stream.sampleRate = AUDIO.System.device.sampleRate;
        sound.stream.sampleSize = 32;
        sound.stream.channels = AUDIO_DEVICE_CHANNELS;
        sound.stream.buffer = audioBuffer;
    }

    return sound;
}


// Checks if a sound is ready
bool IsSoundReady(Sound sound)
{
    bool result = false;

    if ((sound.frameCount > 0) &&           // Validate frame count
        (sound.stream.buffer != NULL) &&    // Validate stream buffer
        (sound.stream.sampleRate > 0) &&    // Validate sample rate is supported
        (sound.stream.sampleSize > 0) &&    // Validate sample size is supported
        (sound.stream.channels > 0)) result = true; // Validate number of channels supported

    return result;
}

// Unload wave data
void UnloadWave(Wave wave)
{
    free(wave.data);
    ////TRACELOG(LOG_INFO, "WAVE: Unloaded wave data from RAM");
}

// Unload sound
void UnloadSound(Sound sound)
{
    UnloadAudioBuffer(sound.stream.buffer);
    ////TRACELOG(LOG_INFO, "SOUND: Unloaded sound data from RAM");
}

void UnloadSoundAlias(Sound alias)
{
    // Untrack and unload just the sound buffer, not the sample data, it is shared with the source for the alias
    if (alias.stream.buffer != NULL)
    {
        UntrackAudioBuffer(alias.stream.buffer);
        ma_data_converter_uninit(&alias.stream.buffer->converter, NULL);
        free(alias.stream.buffer);
    }
}

// Update sound buffer with new data
void UpdateSound(Sound sound, const void *data, int frameCount)
{
    if (sound.stream.buffer != NULL)
    {
        StopAudioBuffer(sound.stream.buffer);

        memcpy(sound.stream.buffer->data, data, frameCount*ma_get_bytes_per_frame(sound.stream.buffer->converter.formatIn, sound.stream.buffer->converter.channelsIn));
    }
}

// Export wave data to file
bool ExportWave(Wave wave, const char *fileName)
{
    bool success = false;

    if (false) { }
    else if (IsFileExtension(fileName, ".wav"))
    {
        drwav wav = { 0 };
        drwav_data_format format = { 0 };
        format.container = drwav_container_riff;
        if (wave.sampleSize == 32) format.format = DR_WAVE_FORMAT_IEEE_FLOAT;
        else format.format = DR_WAVE_FORMAT_PCM;
        format.channels = wave.channels;
        format.sampleRate = wave.sampleRate;
        format.bitsPerSample = wave.sampleSize;

        void *fileData = NULL;
        size_t fileDataSize = 0;
        success = drwav_init_memory_write(&wav, &fileData, &fileDataSize, &format, NULL);
        if (success) success = (int)drwav_write_pcm_frames(&wav, wave.frameCount, wave.data);
        drwav_result result = drwav_uninit(&wav);

        if (result == DRWAV_SUCCESS) success = SaveFileData(fileName, (unsigned char *)fileData, (unsigned int)fileDataSize);

        drwav_free(fileData, NULL);
    }
    //else if (IsFileExtension(fileName, ".qoa"))
    //{
    //    if (wave.sampleSize == 16)
    //    {
    //        qoa_desc qoa = { 0 };
    //        qoa.channels = wave.channels;
    //        qoa.samplerate = wave.sampleRate;
    //        qoa.samples = wave.frameCount;

    //        int bytesWritten = qoa_write(fileName, wave.data, &qoa);
    //        if (bytesWritten > 0) success = true;
    //    }
    //    else ////TRACELOG(LOG_WARNING, "AUDIO: Wave data must be 16 bit per sample for QOA format export");
    //}
    else if (IsFileExtension(fileName, ".raw"))
    {
        // Export raw sample data (without header)
        // NOTE: It's up to the user to track wave parameters
        success = SaveFileData(fileName, wave.data, wave.frameCount*wave.channels*wave.sampleSize/8);
    }

    if (success) ////TRACELOG(LOG_INFO, "FILEIO: [%s] Wave data exported successfully", fileName);
    //else //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to export wave data", fileName);

    return success;
}

// Export wave sample data to code (.h)
bool ExportWaveAsCode(Wave wave, const char *fileName)
{
    bool success = false;


    int waveDataSize = wave.frameCount*wave.channels*wave.sampleSize/8;

    // NOTE: Text data buffer size is estimated considering wave data size in bytes
    // and requiring 12 char bytes for every byte; the actual size varies, but
    // the longest possible char being appended is "%.4ff,\n    ", which is 12 bytes.
    char *txtData = (char *)calloc(waveDataSize*12 + 2000, sizeof(char));

    int byteCount = 0;
    byteCount += sprintf(txtData + byteCount, "\n//////////////////////////////////////////////////////////////////////////////////\n");
    byteCount += sprintf(txtData + byteCount, "//                                                                              //\n");
    byteCount += sprintf(txtData + byteCount, "// WaveAsCode exporter v1.1 - Wave data exported as an array of bytes           //\n");
    byteCount += sprintf(txtData + byteCount, "//                                                                              //\n");
    byteCount += sprintf(txtData + byteCount, "// more info and bugs-report:  github.com/raysan5/raylib                        //\n");
    byteCount += sprintf(txtData + byteCount, "// feedback and support:       ray[at]raylib.com                                //\n");
    byteCount += sprintf(txtData + byteCount, "//                                                                              //\n");
    byteCount += sprintf(txtData + byteCount, "// Copyright (c) 2018-2024 Ramon Santamaria (@raysan5)                          //\n");
    byteCount += sprintf(txtData + byteCount, "//                                                                              //\n");
    byteCount += sprintf(txtData + byteCount, "//////////////////////////////////////////////////////////////////////////////////\n\n");

    // Get file name from path and convert variable name to uppercase
    char varFileName[256] = { 0 };
    strcpy(varFileName, GetFileNameWithoutExt(fileName));
    for (int i = 0; varFileName[i] != '\0'; i++) if (varFileName[i] >= 'a' && varFileName[i] <= 'z') { varFileName[i] = varFileName[i] - 32; }

    // Add wave information
    byteCount += sprintf(txtData + byteCount, "// Wave data information\n");
    byteCount += sprintf(txtData + byteCount, "#define %s_FRAME_COUNT      %u\n", varFileName, wave.frameCount);
    byteCount += sprintf(txtData + byteCount, "#define %s_SAMPLE_RATE      %u\n", varFileName, wave.sampleRate);
    byteCount += sprintf(txtData + byteCount, "#define %s_SAMPLE_SIZE      %u\n", varFileName, wave.sampleSize);
    byteCount += sprintf(txtData + byteCount, "#define %s_CHANNELS         %u\n\n", varFileName, wave.channels);

    // Write wave data as an array of values
    // Wave data is exported as byte array for 8/16bit and float array for 32bit float data
    // NOTE: Frame data exported is channel-interlaced: frame01[sampleChannel1, sampleChannel2, ...], frame02[], frame03[]
    if (wave.sampleSize == 32)
    {
        byteCount += sprintf(txtData + byteCount, "float %s_DATA[%i] = {\n", varFileName, waveDataSize/4);
        for (int i = 1; i < waveDataSize/4; i++) byteCount += sprintf(txtData + byteCount, ((i%TEXT_BYTES_PER_LINE == 0)? "%.4ff,\n    " : "%.4ff, "), ((float *)wave.data)[i - 1]);
        byteCount += sprintf(txtData + byteCount, "%.4ff };\n", ((float *)wave.data)[waveDataSize/4 - 1]);
    }
    else
    {
        byteCount += sprintf(txtData + byteCount, "unsigned char %s_DATA[%i] = { ", varFileName, waveDataSize);
        for (int i = 1; i < waveDataSize; i++) byteCount += sprintf(txtData + byteCount, ((i%TEXT_BYTES_PER_LINE == 0)? "0x%x,\n    " : "0x%x, "), ((unsigned char *)wave.data)[i - 1]);
        byteCount += sprintf(txtData + byteCount, "0x%x };\n", ((unsigned char *)wave.data)[waveDataSize - 1]);
    }

    // NOTE: Text data length exported is determined by '\0' (NULL) character
    success = SaveFileText(fileName, txtData);

    free(txtData);

    if (success != 0) //TRACELOG(LOG_INFO, "FILEIO: [%s] Wave as code exported successfully", fileName);
    //else //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to export wave as code", fileName);

    return success;
}

// Play a sound
void PlaySound(Sound sound)
{
    PlayAudioBuffer(sound.stream.buffer);
}

// Pause a sound
void PauseSound(Sound sound)
{
    PauseAudioBuffer(sound.stream.buffer);
}

// Resume a paused sound
void ResumeSound(Sound sound)
{
    ResumeAudioBuffer(sound.stream.buffer);
}

// Stop reproducing a sound
void StopSound(Sound sound)
{
    StopAudioBuffer(sound.stream.buffer);
}

// Check if a sound is playing
bool IsSoundPlaying(Sound sound)
{
    bool result = false;

    if (IsAudioBufferPlaying(sound.stream.buffer)) result = true;

    return result;
}

// Set volume for a sound
void SetSoundVolume(Sound sound, float volume)
{
    SetAudioBufferVolume(sound.stream.buffer, volume);
}

// Set pitch for a sound
void SetSoundPitch(Sound sound, float pitch)
{
    SetAudioBufferPitch(sound.stream.buffer, pitch);
}

// Set pan for a sound
void SetSoundPan(Sound sound, float pan)
{
    SetAudioBufferPan(sound.stream.buffer, pan);
}

// Convert wave data to desired format
void WaveFormat(Wave *wave, int sampleRate, int sampleSize, int channels)
{
    ma_format formatIn = ((wave->sampleSize == 8)? ma_format_u8 : ((wave->sampleSize == 16)? ma_format_s16 : ma_format_f32));
    ma_format formatOut = ((sampleSize == 8)? ma_format_u8 : ((sampleSize == 16)? ma_format_s16 : ma_format_f32));

    ma_uint32 frameCountIn = wave->frameCount;
    ma_uint32 frameCount = (ma_uint32)ma_convert_frames(NULL, 0, formatOut, channels, sampleRate, NULL, frameCountIn, formatIn, wave->channels, wave->sampleRate);

    if (frameCount == 0)
    {
        //TRACELOG(LOG_WARNING, "WAVE: Failed to get frame count for format conversion");
        return;
    }

    void *data = malloc(frameCount*channels*(sampleSize/8));

    frameCount = (ma_uint32)ma_convert_frames(data, frameCount, formatOut, channels, sampleRate, wave->data, frameCountIn, formatIn, wave->channels, wave->sampleRate);
    if (frameCount == 0)
    {
        //TRACELOG(LOG_WARNING, "WAVE: Failed format conversion");
        return;
    }

    wave->frameCount = frameCount;
    wave->sampleSize = sampleSize;
    wave->sampleRate = sampleRate;
    wave->channels = channels;

    free(wave->data);
    wave->data = data;
}

// Copy a wave to a new wave
Wave WaveCopy(Wave wave)
{
    Wave newWave = { 0 };

    newWave.data = malloc(wave.frameCount*wave.channels*wave.sampleSize/8);

    if (newWave.data != NULL)
    {
        // NOTE: Size must be provided in bytes
        memcpy(newWave.data, wave.data, wave.frameCount*wave.channels*wave.sampleSize/8);

        newWave.frameCount = wave.frameCount;
        newWave.sampleRate = wave.sampleRate;
        newWave.sampleSize = wave.sampleSize;
        newWave.channels = wave.channels;
    }

    return newWave;
}

// Crop a wave to defined frames range
// NOTE: Security check in case of out-of-range
void WaveCrop(Wave *wave, int initFrame, int finalFrame)
{
    if ((initFrame >= 0) && (initFrame < finalFrame) && ((unsigned int)finalFrame <= wave->frameCount))
    {
        int frameCount = finalFrame - initFrame;

        void *data = malloc(frameCount*wave->channels*wave->sampleSize/8);

        memcpy(data, (unsigned char *)wave->data + (initFrame*wave->channels*wave->sampleSize/8), frameCount*wave->channels*wave->sampleSize/8);

        free(wave->data);
        wave->data = data;
        wave->frameCount = (unsigned int)frameCount;
    }
    //else //TRACELOG(LOG_WARNING, "WAVE: Crop range out of bounds");
}

// Load samples data from wave as a floats array
// NOTE 1: Returned sample values are normalized to range [-1..1]
// NOTE 2: Sample data allocated should be freed with UnloadWaveSamples()
float *LoadWaveSamples(Wave wave)
{
    float *samples = (float *)malloc(wave.frameCount*wave.channels*sizeof(float));

    // NOTE: sampleCount is the total number of interlaced samples (including channels)

    for (unsigned int i = 0; i < wave.frameCount*wave.channels; i++)
    {
        if (wave.sampleSize == 8) samples[i] = (float)(((unsigned char *)wave.data)[i] - 128)/128.0f;
        else if (wave.sampleSize == 16) samples[i] = (float)(((short *)wave.data)[i])/32768.0f;
        else if (wave.sampleSize == 32) samples[i] = ((float *)wave.data)[i];
    }

    return samples;
}

// Unload samples data loaded with LoadWaveSamples()
void UnloadWaveSamples(float *samples)
{
    free(samples);
}

// Load audio stream (to stream audio pcm data)
AudioStream LoadAudioStream(unsigned int sampleRate, unsigned int sampleSize, unsigned int channels)
{
    AudioStream stream = { 0 };

    stream.sampleRate = sampleRate;
    stream.sampleSize = sampleSize;
    stream.channels = channels;

    ma_format formatIn = ((stream.sampleSize == 8)? ma_format_u8 : ((stream.sampleSize == 16)? ma_format_s16 : ma_format_f32));

    // The size of a streaming buffer must be at least double the size of a period
    unsigned int periodSize = AUDIO.System.device.playback.internalPeriodSizeInFrames;

    // If the buffer is not set, compute one that would give us a buffer good enough for a decent frame rate
    unsigned int subBufferSize = (AUDIO.Buffer.defaultSize == 0)? AUDIO.System.device.sampleRate/30 : AUDIO.Buffer.defaultSize;

    if (subBufferSize < periodSize) subBufferSize = periodSize;

    // Create a double audio buffer of defined size
    stream.buffer = LoadAudioBuffer(formatIn, stream.channels, stream.sampleRate, subBufferSize*2, AUDIO_BUFFER_USAGE_STREAM);

    if (stream.buffer != NULL)
    {
        stream.buffer->looping = true;    // Always loop for streaming buffers
        //TRACELOG(LOG_INFO, "STREAM: Initialized successfully (%i Hz, %i bit, %s)", stream.sampleRate, stream.sampleSize, (stream.channels == 1)? "Mono" : "Stereo");
    }
    else //TRACELOG(LOG_WARNING, "STREAM: Failed to load audio buffer, stream could not be created");

    return stream;
}

// Checks if an audio stream is ready
bool IsAudioStreamReady(AudioStream stream)
{
    return ((stream.buffer != NULL) &&    // Validate stream buffer
            (stream.sampleRate > 0) &&    // Validate sample rate is supported
            (stream.sampleSize > 0) &&    // Validate sample size is supported
            (stream.channels > 0));       // Validate number of channels supported
}

// Unload audio stream and free memory
void UnloadAudioStream(AudioStream stream)
{
    UnloadAudioBuffer(stream.buffer);

    //TRACELOG(LOG_INFO, "STREAM: Unloaded audio stream data from RAM");
}

// Update audio stream buffers with data
// NOTE 1: Only updates one buffer of the stream source: dequeue -> update -> queue
// NOTE 2: To dequeue a buffer it needs to be processed: IsAudioStreamProcessed()
void UpdateAudioStream(AudioStream stream, const void *data, int frameCount)
{
    ma_mutex_lock(&AUDIO.System.lock);
    UpdateAudioStreamInLockedState(stream, data, frameCount);
    ma_mutex_unlock(&AUDIO.System.lock);
}

// Check if any audio stream buffers requires refill
bool IsAudioStreamProcessed(AudioStream stream)
{
    if (stream.buffer == NULL) return false;

    bool result = false;
    ma_mutex_lock(&AUDIO.System.lock);
    result = stream.buffer->isSubBufferProcessed[0] || stream.buffer->isSubBufferProcessed[1];
    ma_mutex_unlock(&AUDIO.System.lock);
    return result;
}

// Play audio stream
void PlayAudioStream(AudioStream stream)
{
    PlayAudioBuffer(stream.buffer);
}

// Play audio stream
void PauseAudioStream(AudioStream stream)
{
    PauseAudioBuffer(stream.buffer);
}

// Resume audio stream playing
void ResumeAudioStream(AudioStream stream)
{
    ResumeAudioBuffer(stream.buffer);
}

// Check if audio stream is playing
bool IsAudioStreamPlaying(AudioStream stream)
{
    return IsAudioBufferPlaying(stream.buffer);
}

// Stop audio stream
void StopAudioStream(AudioStream stream)
{
    StopAudioBuffer(stream.buffer);
}

// Set volume for audio stream (1.0 is max level)
void SetAudioStreamVolume(AudioStream stream, float volume)
{
    SetAudioBufferVolume(stream.buffer, volume);
}

// Set pitch for audio stream (1.0 is base level)
void SetAudioStreamPitch(AudioStream stream, float pitch)
{
    SetAudioBufferPitch(stream.buffer, pitch);
}

// Set pan for audio stream
void SetAudioStreamPan(AudioStream stream, float pan)
{
    SetAudioBufferPan(stream.buffer, pan);
}

// Default size for new audio streams
void SetAudioStreamBufferSizeDefault(int size)
{
    AUDIO.Buffer.defaultSize = size;
}

// Audio thread callback to request new data
void SetAudioStreamCallback(AudioStream stream, AudioCallback callback)
{
    if (stream.buffer != NULL)
    {
        ma_mutex_lock(&AUDIO.System.lock);
        stream.buffer->callback = callback;
        ma_mutex_unlock(&AUDIO.System.lock);
    }
}

// Add processor to audio stream. Contrary to buffers, the order of processors is important
// The new processor must be added at the end. As there aren't supposed to be a lot of processors attached to
// a given stream, we iterate through the list to find the end. That way we don't need a pointer to the last element
void AttachAudioStreamProcessor(AudioStream stream, AudioCallback process)
{
    ma_mutex_lock(&AUDIO.System.lock);

    rAudioProcessor *processor = (rAudioProcessor *)calloc(1, sizeof(rAudioProcessor));
    processor->process = process;

    rAudioProcessor *last = stream.buffer->processor;

    while (last && last->next)
    {
        last = last->next;
    }
    if (last)
    {
        processor->prev = last;
        last->next = processor;
    }
    else stream.buffer->processor = processor;

    ma_mutex_unlock(&AUDIO.System.lock);
}

// Remove processor from audio stream
void DetachAudioStreamProcessor(AudioStream stream, AudioCallback process)
{
    ma_mutex_lock(&AUDIO.System.lock);

    rAudioProcessor *processor = stream.buffer->processor;

    while (processor)
    {
        rAudioProcessor *next = processor->next;
        rAudioProcessor *prev = processor->prev;

        if (processor->process == process)
        {
            if (stream.buffer->processor == processor) stream.buffer->processor = next;
            if (prev) prev->next = next;
            if (next) next->prev = prev;

            free(processor);
        }

        processor = next;
    }

    ma_mutex_unlock(&AUDIO.System.lock);
}

// Add processor to audio pipeline. Order of processors is important
// Works the same way as {Attach,Detach}AudioStreamProcessor() functions, except
// these two work on the already mixed output just before sending it to the sound hardware
void AttachAudioMixedProcessor(AudioCallback process)
{
    ma_mutex_lock(&AUDIO.System.lock);

    rAudioProcessor *processor = (rAudioProcessor *)calloc(1, sizeof(rAudioProcessor));
    processor->process = process;

    rAudioProcessor *last = AUDIO.mixedProcessor;

    while (last && last->next)
    {
        last = last->next;
    }
    if (last)
    {
        processor->prev = last;
        last->next = processor;
    }
    else AUDIO.mixedProcessor = processor;

    ma_mutex_unlock(&AUDIO.System.lock);
}

// Remove processor from audio pipeline
void DetachAudioMixedProcessor(AudioCallback process)
{
    ma_mutex_lock(&AUDIO.System.lock);

    rAudioProcessor *processor = AUDIO.mixedProcessor;

    while (processor)
    {
        rAudioProcessor *next = processor->next;
        rAudioProcessor *prev = processor->prev;

        if (processor->process == process)
        {
            if (AUDIO.mixedProcessor == processor) AUDIO.mixedProcessor = next;
            if (prev) prev->next = next;
            if (next) next->prev = prev;

            free(processor);
        }

        processor = next;
    }

    ma_mutex_unlock(&AUDIO.System.lock);
}


//----------------------------------------------------------------------------------
// Module specific Functions Definition
//----------------------------------------------------------------------------------

// Log callback function
void OnLog(void *pUserData, ma_uint32 level, const char *pMessage)
{
	(void)pUserData;
	(void)level;
	(void)pMessage;
    //TRACELOG(LOG_WARNING, "miniaudio: %s", pMessage);   // All log messages from miniaudio are errors
}

// Reads audio data from an AudioBuffer object in internal format
ma_uint32 ReadAudioBufferFramesInInternalFormat(AudioBuffer *audioBuffer, void *framesOut, ma_uint32 frameCount)
{
    // Using audio buffer callback
    if (audioBuffer->callback)
    {
        audioBuffer->callback(framesOut, frameCount);
        audioBuffer->framesProcessed += frameCount;

        return frameCount;
    }

    ma_uint32 subBufferSizeInFrames = (audioBuffer->sizeInFrames > 1)? audioBuffer->sizeInFrames/2 : audioBuffer->sizeInFrames;
    ma_uint32 currentSubBufferIndex = audioBuffer->frameCursorPos/subBufferSizeInFrames;

    if (currentSubBufferIndex > 1) return 0;

    // Another thread can update the processed state of buffers, so
    // we just take a copy here to try and avoid potential synchronization problems
    bool isSubBufferProcessed[2] = { 0 };
    isSubBufferProcessed[0] = audioBuffer->isSubBufferProcessed[0];
    isSubBufferProcessed[1] = audioBuffer->isSubBufferProcessed[1];

    ma_uint32 frameSizeInBytes = ma_get_bytes_per_frame(audioBuffer->converter.formatIn, audioBuffer->converter.channelsIn);

    // Fill out every frame until we find a buffer that's marked as processed. Then fill the remainder with 0
    ma_uint32 framesRead = 0;
    while (1)
    {
        // We break from this loop differently depending on the buffer's usage
        //  - For buffers, we simply fill as much data as we can
        //  - For streaming buffers we only fill half of the buffer that are processed
        //    Unprocessed halves must keep their audio data in-tact
        if (audioBuffer->usage == AUDIO_BUFFER_USAGE_STATIC)
        {
            if (framesRead >= frameCount) break;
        }
        else
        {
            if (isSubBufferProcessed[currentSubBufferIndex]) break;
        }

        ma_uint32 totalFramesRemaining = (frameCount - framesRead);
        if (totalFramesRemaining == 0) break;

        ma_uint32 framesRemainingInOutputBuffer;
        if (audioBuffer->usage == AUDIO_BUFFER_USAGE_STATIC)
        {
            framesRemainingInOutputBuffer = audioBuffer->sizeInFrames - audioBuffer->frameCursorPos;
        }
        else
        {
            ma_uint32 firstFrameIndexOfThisSubBuffer = subBufferSizeInFrames*currentSubBufferIndex;
            framesRemainingInOutputBuffer = subBufferSizeInFrames - (audioBuffer->frameCursorPos - firstFrameIndexOfThisSubBuffer);
        }

        ma_uint32 framesToRead = totalFramesRemaining;
        if (framesToRead > framesRemainingInOutputBuffer) framesToRead = framesRemainingInOutputBuffer;

        memcpy((unsigned char *)framesOut + (framesRead*frameSizeInBytes), audioBuffer->data + (audioBuffer->frameCursorPos*frameSizeInBytes), framesToRead*frameSizeInBytes);
        audioBuffer->frameCursorPos = (audioBuffer->frameCursorPos + framesToRead)%audioBuffer->sizeInFrames;
        framesRead += framesToRead;

        // If we've read to the end of the buffer, mark it as processed
        if (framesToRead == framesRemainingInOutputBuffer)
        {
            audioBuffer->isSubBufferProcessed[currentSubBufferIndex] = true;
            isSubBufferProcessed[currentSubBufferIndex] = true;

            currentSubBufferIndex = (currentSubBufferIndex + 1)%2;

            // We need to break from this loop if we're not looping
            if (!audioBuffer->looping)
            {
                StopAudioBufferInLockedState(audioBuffer);
                break;
            }
        }
    }

    // Zero-fill excess
    ma_uint32 totalFramesRemaining = (frameCount - framesRead);
    if (totalFramesRemaining > 0)
    {
        memset((unsigned char *)framesOut + (framesRead*frameSizeInBytes), 0, totalFramesRemaining*frameSizeInBytes);

        // For buffers we can fill the remaining frames with silence for safety, but we don't want
        // to report those frames as "read". The reason for this is that the caller uses the return value
        // to know whether a non-looping sound has finished playback
        if (audioBuffer->usage != AUDIO_BUFFER_USAGE_STATIC) framesRead += totalFramesRemaining;
    }

    return framesRead;
}

// Reads audio data from an AudioBuffer object in device format, returned data will be in a format appropriate for mixing
ma_uint32 ReadAudioBufferFramesInMixingFormat(AudioBuffer *audioBuffer, float *framesOut, ma_uint32 frameCount)
{
    // What's going on here is that we're continuously converting data from the AudioBuffer's internal format to the mixing format, which
    // should be defined by the output format of the data converter. We do this until frameCount frames have been output. The important
    // detail to remember here is that we never, ever attempt to read more input data than is required for the specified number of output
    // frames. This can be achieved with ma_data_converter_get_required_input_frame_count()
    ma_uint8 inputBuffer[4096] = { 0 };
    ma_uint32 inputBufferFrameCap = sizeof(inputBuffer)/ma_get_bytes_per_frame(audioBuffer->converter.formatIn, audioBuffer->converter.channelsIn);

    ma_uint32 totalOutputFramesProcessed = 0;
    while (totalOutputFramesProcessed < frameCount)
    {
        ma_uint64 outputFramesToProcessThisIteration = frameCount - totalOutputFramesProcessed;
        ma_uint64 inputFramesToProcessThisIteration = 0;

        (void)ma_data_converter_get_required_input_frame_count(&audioBuffer->converter, outputFramesToProcessThisIteration, &inputFramesToProcessThisIteration);
        if (inputFramesToProcessThisIteration > inputBufferFrameCap)
        {
            inputFramesToProcessThisIteration = inputBufferFrameCap;
        }

        float *runningFramesOut = framesOut + (totalOutputFramesProcessed*audioBuffer->converter.channelsOut);

        /* At this point we can convert the data to our mixing format. */
        ma_uint64 inputFramesProcessedThisIteration = ReadAudioBufferFramesInInternalFormat(audioBuffer, inputBuffer, (ma_uint32)inputFramesToProcessThisIteration);    /* Safe cast. */
        ma_uint64 outputFramesProcessedThisIteration = outputFramesToProcessThisIteration;
        ma_data_converter_process_pcm_frames(&audioBuffer->converter, inputBuffer, &inputFramesProcessedThisIteration, runningFramesOut, &outputFramesProcessedThisIteration);

        totalOutputFramesProcessed += (ma_uint32)outputFramesProcessedThisIteration; /* Safe cast. */

        if (inputFramesProcessedThisIteration < inputFramesToProcessThisIteration)
        {
            break;  /* Ran out of input data. */
        }

        /* This should never be hit, but will add it here for safety. Ensures we get out of the loop when no input nor output frames are processed. */
        if (inputFramesProcessedThisIteration == 0 && outputFramesProcessedThisIteration == 0)
        {
            break;
        }
    }

    return totalOutputFramesProcessed;
}

// Sending audio data to device callback function
// This function will be called when miniaudio needs more data
// NOTE: All the mixing takes place here
void OnSendAudioDataToDevice(ma_device *pDevice, void *pFramesOut, const void *pFramesInput, ma_uint32 frameCount)
{
    (void)pDevice;

    // Mixing is basically just an accumulation, we need to initialize the output buffer to 0
    memset(pFramesOut, 0, frameCount*pDevice->playback.channels*ma_get_bytes_per_sample(pDevice->playback.format));

    // Using a mutex here for thread-safety which makes things not real-time
    // This is unlikely to be necessary for this project, but may want to consider how you might want to avoid this
    ma_mutex_lock(&AUDIO.System.lock);
    {
        for (AudioBuffer *audioBuffer = AUDIO.Buffer.first; audioBuffer != NULL; audioBuffer = audioBuffer->next)
        {
            // Ignore stopped or paused sounds
            if (!audioBuffer->playing || audioBuffer->paused) continue;

            ma_uint32 framesRead = 0;

            while (1)
            {
                if (framesRead >= frameCount) break;

                // Just read as much data as we can from the stream
                ma_uint32 framesToRead = (frameCount - framesRead);

                while (framesToRead > 0)
                {
                    float tempBuffer[1024] = { 0 }; // Frames for stereo

                    ma_uint32 framesToReadRightNow = framesToRead;
                    if (framesToReadRightNow > sizeof(tempBuffer)/sizeof(tempBuffer[0])/AUDIO_DEVICE_CHANNELS)
                    {
                        framesToReadRightNow = sizeof(tempBuffer)/sizeof(tempBuffer[0])/AUDIO_DEVICE_CHANNELS;
                    }

                    ma_uint32 framesJustRead = ReadAudioBufferFramesInMixingFormat(audioBuffer, tempBuffer, framesToReadRightNow);
                    if (framesJustRead > 0)
                    {
                        float *framesOut = (float *)pFramesOut + (framesRead*AUDIO.System.device.playback.channels);
                        float *framesIn = tempBuffer;

                        // Apply processors chain if defined
                        rAudioProcessor *processor = audioBuffer->processor;
                        while (processor)
                        {
                            processor->process(framesIn, framesJustRead);
                            processor = processor->next;
                        }

                        MixAudioFrames(framesOut, framesIn, framesJustRead, audioBuffer);

                        framesToRead -= framesJustRead;
                        framesRead += framesJustRead;
                    }

                    if (!audioBuffer->playing)
                    {
                        framesRead = frameCount;
                        break;
                    }

                    // If we weren't able to read all the frames we requested, break
                    if (framesJustRead < framesToReadRightNow)
                    {
                        if (!audioBuffer->looping)
                        {
                            StopAudioBufferInLockedState(audioBuffer);
                            break;
                        }
                        else
                        {
                            // Should never get here, but just for safety,
                            // move the cursor position back to the start and continue the loop
                            audioBuffer->frameCursorPos = 0;
                            continue;
                        }
                    }
                }

                // If for some reason we weren't able to read every frame we'll need to break from the loop
                // Not doing this could theoretically put us into an infinite loop
                if (framesToRead > 0) break;
            }
        }
    }

    rAudioProcessor *processor = AUDIO.mixedProcessor;
    while (processor)
    {
        processor->process(pFramesOut, frameCount);
        processor = processor->next;
    }

    ma_mutex_unlock(&AUDIO.System.lock);
}

// Main mixing function, pretty simple in this project, just an accumulation
// NOTE: framesOut is both an input and an output, it is initially filled with zeros outside of this function
void MixAudioFrames(float *framesOut, const float *framesIn, ma_uint32 frameCount, AudioBuffer *buffer)
{
    const float localVolume = buffer->volume;
    const ma_uint32 channels = AUDIO.System.device.playback.channels;

    if (channels == 2)  // We consider panning
    {
        const float left = buffer->pan;
        const float right = 1.0f - left;

        // Fast sine approximation in [0..1] for pan law: y = 0.5f*x*(3 - x*x);
        const float levels[2] = { localVolume*0.5f*left*(3.0f - left*left), localVolume*0.5f*right*(3.0f - right*right) };

        float *frameOut = framesOut;
        const float *frameIn = framesIn;

        for (ma_uint32 frame = 0; frame < frameCount; frame++)
        {
            frameOut[0] += (frameIn[0]*levels[0]);
            frameOut[1] += (frameIn[1]*levels[1]);

            frameOut += 2;
            frameIn += 2;
        }
    }
    else  // We do not consider panning
    {
        for (ma_uint32 frame = 0; frame < frameCount; frame++)
        {
            for (ma_uint32 c = 0; c < channels; c++)
            {
                float *frameOut = framesOut + (frame*channels);
                const float *frameIn = framesIn + (frame*channels);

                // Output accumulates input multiplied by volume to provided output (usually 0)
                frameOut[c] += (frameIn[c]*localVolume);
            }
        }
    }
}

// Check if an audio buffer is playing, assuming the audio system mutex has been locked
bool IsAudioBufferPlayingInLockedState(AudioBuffer *buffer)
{
    bool result = false;

    if (buffer != NULL) result = (buffer->playing && !buffer->paused);

    return result;
}

// Stop an audio buffer, assuming the audio system mutex has been locked
void StopAudioBufferInLockedState(AudioBuffer *buffer)
{
    if (buffer != NULL)
    {
        if (IsAudioBufferPlayingInLockedState(buffer))
        {
            buffer->playing = false;
            buffer->paused = false;
            buffer->frameCursorPos = 0;
            buffer->framesProcessed = 0;
            buffer->isSubBufferProcessed[0] = true;
            buffer->isSubBufferProcessed[1] = true;
        }
    }
}

// Update audio stream, assuming the audio system mutex has been locked
void UpdateAudioStreamInLockedState(AudioStream stream, const void *data, int frameCount)
{
    if (stream.buffer != NULL)
    {
        if (stream.buffer->isSubBufferProcessed[0] || stream.buffer->isSubBufferProcessed[1])
        {
            ma_uint32 subBufferToUpdate = 0;

            if (stream.buffer->isSubBufferProcessed[0] && stream.buffer->isSubBufferProcessed[1])
            {
                // Both buffers are available for updating
                // Update the first one and make sure the cursor is moved back to the front
                subBufferToUpdate = 0;
                stream.buffer->frameCursorPos = 0;
            }
            else
            {
                // Just update whichever sub-buffer is processed
                subBufferToUpdate = (stream.buffer->isSubBufferProcessed[0])? 0 : 1;
            }

            ma_uint32 subBufferSizeInFrames = stream.buffer->sizeInFrames/2;
            unsigned char *subBuffer = stream.buffer->data + ((subBufferSizeInFrames*stream.channels*(stream.sampleSize/8))*subBufferToUpdate);

            // Total frames processed in buffer is always the complete size, filled with 0 if required
            stream.buffer->framesProcessed += subBufferSizeInFrames;

            // Does this API expect a whole buffer to be updated in one go?
            // Assuming so, but if not will need to change this logic
            if (subBufferSizeInFrames >= (ma_uint32)frameCount)
            {
                ma_uint32 framesToWrite = (ma_uint32)frameCount;

                ma_uint32 bytesToWrite = framesToWrite*stream.channels*(stream.sampleSize/8);
                memcpy(subBuffer, data, bytesToWrite);

                // Any leftover frames should be filled with zeros
                ma_uint32 leftoverFrameCount = subBufferSizeInFrames - framesToWrite;

                if (leftoverFrameCount > 0) memset(subBuffer + bytesToWrite, 0, leftoverFrameCount*stream.channels*(stream.sampleSize/8));

                stream.buffer->isSubBufferProcessed[subBufferToUpdate] = false;
            }
        }
    }
}

bool IsFileExtension(const char *fileName, const char *ext)
{
    bool result = false;
    const char *fileExt;

    if ((fileExt = strrchr(fileName, '.')) != NULL)
    {
        if (strcmp(fileExt, ext) == 0) result = true;
    }

    return result;
}

// Get pointer to extension for a filename string (includes the dot: .png)
const char *GetFileExtension(const char *fileName)
{
    const char *dot = strrchr(fileName, '.');

    if (!dot || dot == fileName) return NULL;

    return dot;
}

// String pointer reverse break: returns right-most occurrence of charset in s
const char *strprbrk(const char *s, const char *charset)
{
    const char *latestMatch = NULL;
    for (; s = strpbrk(s, charset), s != NULL; latestMatch = s++) { }
    return latestMatch;
}

// Get pointer to filename for a path string
const char *GetFileName(const char *filePath)
{
    const char *fileName = NULL;
    if (filePath != NULL) fileName = strprbrk(filePath, "\\/");

    if (!fileName) return filePath;

    return fileName + 1;
}

// Get filename string without extension (uses string)
const char *GetFileNameWithoutExt(const char *filePath)
{
    #define MAX_FILENAMEWITHOUTEXT_LENGTH   256

    char fileName[MAX_FILENAMEWITHOUTEXT_LENGTH] = { 0 };
    memset(fileName, 0, MAX_FILENAMEWITHOUTEXT_LENGTH);

    if (filePath != NULL) strcpy(fileName, GetFileName(filePath));   // Get filename with extension

    int size = (int)strlen(fileName);   // Get size in bytes

    for (int i = 0; (i < size) && (i < MAX_FILENAMEWITHOUTEXT_LENGTH); i++)
    {
        if (fileName[i] == '.')
        {
            // NOTE: We break on first '.' found
            fileName[i] = '\0';
            break;
        }
    }

    return fileName;
}

// Load data from file into a buffer
unsigned char *LoadFileData(const char *fileName, int *dataSize)
{
    unsigned char *data = NULL;
    *dataSize = 0;

    if (fileName != NULL)
    {
        FILE *file = fopen(fileName, "rb");

        if (file != NULL)
        {
            // WARNING: On binary streams SEEK_END could not be found,
            // using fseek() and ftell() could not work in some (rare) cases
            fseek(file, 0, SEEK_END);
            int size = ftell(file);
            fseek(file, 0, SEEK_SET);

            if (size > 0)
            {
                data = (unsigned char *)malloc(size*sizeof(unsigned char));

                // NOTE: fread() returns number of read elements instead of bytes, so we read [1 byte, size elements]
                unsigned int count = (unsigned int)fread(data, sizeof(unsigned char), size, file);
                *dataSize = count;

                //if (count != size) //TRACELOG(LOG_WARNING, "FILEIO: [%s] File partially loaded", fileName);
                //else //TRACELOG(LOG_INFO, "FILEIO: [%s] File loaded successfully", fileName);
            }
            //else //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to read file", fileName);

            fclose(file);
        }
        //else //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to open file", fileName);
    }
    //else //TRACELOG(LOG_WARNING, "FILEIO: File name provided is not valid");

    return data;
}

// Save data to file from buffer
bool SaveFileData(const char *fileName, void *data, int dataSize)
{
    if (fileName != NULL)
    {
        FILE *file = fopen(fileName, "wb");

        if (file != NULL)
        {
            unsigned int count = (unsigned int)fwrite(data, sizeof(unsigned char), dataSize, file);

            //if (count == 0) //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to write file", fileName);
            //else if (count != dataSize) //TRACELOG(LOG_WARNING, "FILEIO: [%s] File partially written", fileName);
            //else //TRACELOG(LOG_INFO, "FILEIO: [%s] File saved successfully", fileName);

            fclose(file);
        }
        else
        {
            //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to open file", fileName);
            return false;
        }
    }
    else
    {
        //TRACELOG(LOG_WARNING, "FILEIO: File name provided is not valid");
        return false;
    }

    return true;
}

// Save text data to file (write), string must be '\0' terminated
bool SaveFileText(const char *fileName, char *text)
{
    if (fileName != NULL)
    {
        FILE *file = fopen(fileName, "wt");

        if (file != NULL)
        {
            int count = fprintf(file, "%s", text);

            //if (count == 0) //TRACELOG(LOG_WARNING, "FILEIO: [%s] Failed to write text file", fileName);
            //else //TRACELOG(LOG_INFO, "FILEIO: [%s] Text file saved successfully", fileName);

            fclose(file);
        }
        else
        {
            return false;
        }
    }
    else
    {
        return false;
    }

    return true;
}
#undef AudioBuffer
#endif // AUDIO_C_
