#ifndef RMP_AUDIO_H_
#define RMP_AUDIO_H_

#include <stdbool.h>

// Audio API functions

/**
 * Initialize the audio system
 * @return: true on success, false on failure
 */
bool rmp_audio_init(void);

/**
 * Load an audio file
 * @param filepath: path to the audio file to load
 * @return: true on success, false on failure
 */
bool rmp_audio_load(const char* filepath);

/**
 * Play the loaded audio file
 * @return: true on success, false on failure
 */
bool rmp_audio_play(void);

/**
 * Pause audio playback
 * @return: true on success, false on failure
 */
bool rmp_audio_pause(void);

/**
 * Resume audio playback
 * @return: true on success, false on failure
 */
bool rmp_audio_resume(void);

/**
 * Stop audio playback and reset position
 * @return: true on success, false on failure
 */
bool rmp_audio_stop(void);

/**
 * Set the master volume
 * @param volume: volume level (0.0 to 1.0)
 * @return: true on success, false on failure
 */
bool rmp_audio_set_volume(float volume);

/**
 * Get the current master volume
 * @return: current volume level (0.0 to 1.0)
 */
float rmp_audio_get_volume(void);

/**
 * Set the playback speed
 * @param speed: speed multiplier (0.25 to 4.0)
 * @return: true on success, false on failure
 */
bool rmp_audio_set_speed(float speed);

/**
 * Seek to a specific position in the audio
 * @param position_seconds: position in seconds
 * @return: true on success, false on failure
 */
bool rmp_audio_seek(double position_seconds);

/**
 * Get the current playback position
 * @return: current position in seconds
 */
double rmp_audio_get_position(void);

/**
 * Get the total duration of the audio
 * @return: total duration in seconds
 */
double rmp_audio_get_duration(void);

/**
 * Check if audio is currently playing
 * @return: true if playing, false otherwise
 */
bool rmp_audio_is_playing(void);

/**
 * Check if playback has finished
 * @return: true if finished, false otherwise
 */
bool rmp_audio_is_finished(void);

/**
 * Set whether to loop the audio
 * @param loop: true to enable looping, false to disable
 */
void rmp_audio_set_loop(bool loop);

/**
 * Get whether looping is enabled
 * @return: true if looping, false otherwise
 */
bool rmp_audio_get_loop(void);

/**
 * Check if an audio file is loaded and valid
 * @return: true if valid, false otherwise
 */
bool rmp_audio_is_valid(void);

/**
 * Enable audio visualization
 * @param freq_bins: number of frequency bins (default 64)
 * @return: true on success, false on failure
 */
bool rmp_audio_enable_visualization(int freq_bins);

/**
 * Disable audio visualization
 * @return: true on success, false on failure
 */
bool rmp_audio_disable_visualization(void);

/**
 * Get frequency data for visualization
 * @param[out] data: array to store frequency data
 * @param[in,out] size: size of the array on input, actual size filled on output
 * @return: true on success, false on failure
 */
bool rmp_audio_get_frequency_data(float* data, int* size);

/**
 * Clean up the audio system
 * @return: true on success, false on failure
 */
bool rmp_audio_cleanup(void);

#endif // RMP_AUDIO_H_
