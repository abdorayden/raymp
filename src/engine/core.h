/*
 *	This core.h file containes all implementation of standerd functions 
 *	to draw on terminal and access internet ...
 *
 * */

#ifndef RMP_CORE
#define RMP_CORE

#ifdef ALL

	#ifndef box
		#define box
	#endif
	
	#ifndef line
		#define line
	#endif
	
	#ifndef col
		#define col
	#endif
	
	#ifndef log
		#define log
	#endif
	
	#ifndef colour
		#define colour
	#endif

#endif

////////////

#ifdef box
void Box(void);
#endif

#ifdef line
void Line(void);
#endif

#ifdef col
void Col(void);
#endif

#ifdef log // popup logging message note error
void Log(void);
#endif

#ifdef colour
void SetColour(void);
#endif

#ifdef mov_cursor_enable
	#define move_cursor
#endif


#endif //RMP_CORE
