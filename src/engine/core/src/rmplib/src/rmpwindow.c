#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "../include/rmp_window.h"

#ifndef _WIN32
// POSIX
#include <sys/ioctl.h>
#include <unistd.h>
#include <termios.h>   // for struct winsize on some platforms

static struct termios orig_termios;
static int raw_mode_enabled = 0;

bool rmp_window_raw_mode(bool enable) {
	if (enable && !raw_mode_enabled) {
		struct termios raw;

		if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
			return false;
		}

		raw = orig_termios;
		raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
		raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
		raw.c_cflag |= (CS8);
		raw.c_oflag &= ~(OPOST);
		raw.c_cc[VMIN] = 1;
		raw.c_cc[VTIME] = 0;

		if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
			return false;
		}

		raw_mode_enabled = 1;
	}
	else if (!enable && raw_mode_enabled) {
		tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
		raw_mode_enabled = 0;
	}

	return true;
}

bool rmp_window_get_size(int* rows, int* cols) {
	if (!rows || !cols) {
		return false;
	}
	
	struct winsize w;
	if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1) {
		*rows = 0;
		*cols = 0;
		return false;
	}
	*rows = (int)w.ws_row;
	*cols = (int)w.ws_col;
	return true;
}

#else
// Windows
#include <windows.h>

static CONSOLE_SCREEN_BUFFER_INFO orig_csbi;
static DWORD orig_mode;
static int raw_mode_enabled = 0;

bool rmp_window_raw_mode(bool enable) {
	HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);

	if (enable && !raw_mode_enabled) {
		GetConsoleMode(hIn, &orig_mode);
		SetConsoleMode(hIn, orig_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT));

		GetConsoleScreenBufferInfo(hOut, &orig_csbi);
		COORD size = {9999, 9999};
		SetConsoleScreenBufferSize(hOut, size);

		raw_mode_enabled = 1;
	}
	else if (!enable && raw_mode_enabled) {
		SetConsoleMode(hIn, orig_mode);
		SetConsoleScreenBufferSize(hOut, orig_csbi.dwSize);
		raw_mode_enabled = 0;
	}

	return true;
}

bool rmp_window_get_size(int* rows, int* cols) {
	if (!rows || !cols) {
		return false;
	}
	
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hOut == INVALID_HANDLE_VALUE || hOut == NULL) {
		*rows = 0;
		*cols = 0;
		return false;
	}

	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (!GetConsoleScreenBufferInfo(hOut, &csbi)) {
		*rows = 0;
		*cols = 0;
		return false;
	}

	SHORT r = (SHORT)(csbi.srWindow.Bottom - csbi.srWindow.Top + 1);
	SHORT c = (SHORT)(csbi.srWindow.Right  - csbi.srWindow.Left + 1);

	*rows = (int)r;
	*cols = (int)c;
	return true;
}
#endif