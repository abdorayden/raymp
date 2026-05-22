#include "term.h"
#include <stdio.h>

bool rmp_to_raw_mode(RDNApi* api)
{
    bool enable = true;
    api->to_boolean(api , -1 , &enable);
    api->pop(api, 1);

#ifndef _WIN32

	if (enable && !raw_mode_enabled) {
        struct termios raw;
		if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
            api->push_boolean(api , false);
			return true;
		}

		raw = orig_termios;
		raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
		raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
		raw.c_cflag |= (CS8);
		raw.c_oflag &= ~(OPOST);
		raw.c_cc[VMIN] = 1;
		raw.c_cc[VTIME] = 0;

		if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
            api->push_boolean(api , false);
			return true;
		}
		raw_mode_enabled = 1;
    } else if (!enable && raw_mode_enabled) {
		tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
		raw_mode_enabled = 0;
	}
#else
	HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);

	if (enable && !raw_mode_enabled) {
		GetConsoleMode(hIn, &orig_mode);
		SetConsoleMode(hIn, orig_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT));

		GetConsoleScreenBufferInfo(hOut, &orig_csbi);
		COORD size = {9999, 9999};
		SetConsoleScreenBufferSize(hOut, size);

		raw_mode_enabled = 1;
	} else if (!enable && raw_mode_enabled) {
		SetConsoleMode(hIn, orig_mode);
		SetConsoleScreenBufferSize(hOut, orig_csbi.dwSize);
		raw_mode_enabled = 0;
	}

#endif /* ifndef _WIN32 */

    api->push_boolean(api , true);
    return true;
}

bool rmp_get_term_size(RDNApi* api)
{
#ifndef _WIN32
	struct winsize w;
	if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1) {
        api->push_null(api);
        api->push_null(api);
		return true;
	}
    api->push_integer(api , (long)w.ws_row);
    api->push_integer(api , (long)w.ws_col);
#else
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hOut == INVALID_HANDLE_VALUE || hOut == NULL) {
        api->push_null(api);
        api->push_null(api);
		return true;
    }

	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (!GetConsoleScreenBufferInfo(hOut, &csbi)) {
        api->push_null(api);
        api->push_null(api);
		return true;
	}

	SHORT rows = (SHORT)(csbi.srWindow.Bottom - csbi.srWindow.Top + 1);
	SHORT cols = (SHORT)(csbi.srWindow.Right  - csbi.srWindow.Left + 1);

    api->push_integer(api , (long)rows);
    api->push_integer(api , (long)cols);
#endif
    return true;
}

bool init_terminal(RDNApi* api)
{
#ifdef _WIN32
	if (!initialized) {
		hStdin = GetStdHandle(STD_INPUT_HANDLE);
		GetConsoleMode(hStdin, &oldMode);
		SetConsoleMode(hStdin, ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT);
		initialized = true;
	}
#else 
	if (!initialized) {
		tcgetattr(STDIN_FILENO, &orig_termios);
		struct termios new_termios = orig_termios;
		new_termios.c_lflag &= ~(ICANON | ECHO);
		new_termios.c_cc[VMIN] = 0;
		new_termios.c_cc[VTIME] = 0;
		tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);
		initialized = true;
	}
#endif

    api->push_boolean(api, true);
    return true;
}
bool restore_terminal(RDNApi* api)
{
#ifdef _WIN32
	if (initialized) {
		SetConsoleMode(hStdin, oldMode);
		initialized = false;
	}
#else 
	if (initialized) {
		tcsetattr(STDIN_FILENO, TCSANOW, &orig_termios);
		initialized = false;
	}
#endif
    api->push_boolean(api, true);
    return true;
}

bool rmp_term_clear(RDNApi* api)
{
    fputs("\x1b[2J\x1b[H", stdout);
    fflush(stdout);
    api->push_boolean(api, true);
    return true;
}

bool rmp_term_hide_cursor(RDNApi* api)
{
    fputs("\x1b[?25l", stdout);
    fflush(stdout);
    api->push_boolean(api, true);
    return true;
}

bool rmp_term_show_cursor(RDNApi* api)
{
    fputs("\x1b[?25h", stdout);
    fflush(stdout);
    api->push_boolean(api, true);
    return true;
}
