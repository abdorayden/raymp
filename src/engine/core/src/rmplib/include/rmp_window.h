#ifndef RMP_WINDOW_H_
#define RMP_WINDOW_H_

#include <stdbool.h>

// Window API functions

/**
 * Enable or disable raw mode for terminal input
 * @param enable: true to enable raw mode, false to disable
 * @return: true on success, false on failure
 */
bool rmp_window_raw_mode(bool enable);

/**
 * Get the terminal size
 * @param[out] rows: pointer to store number of rows
 * @param[out] cols: pointer to store number of columns
 * @return: true on success, false on failure
 */
bool rmp_window_get_size(int* rows, int* cols);

#endif // RMP_WINDOW_H_