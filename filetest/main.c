#include "ndsarm9.h"
#include "console.h"

int main()
{
	console_init();

//	puts("Hello, world\n", MAIN_SCREEN);
	putline("Hello", 23);

	while (1);
}
