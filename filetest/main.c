#include "ndsarm9.h"
#include "console.h"

struct io_interface {
	unsigned long ul_iotype;
	unsigned long ul_features;
	int (*fn_startup)(void);
	int (*fn_ininserted)(void);
	int (*fn_readsectors)(int sector, int numsecs, void* buffer);
	int (*fn_writesectors)(int sector, int numsecs, void* buffer);
	int (*fn_clearstatus)(void);
	int (*fn_shutdown)(void);
};

extern struct io_interface _io_dldi;

int main()
{
	console_init();

//	puts("Hello, world\n", MAIN_SCREEN);
	putline("Hello ArcDOS!", 0);

	_io_dldi.fn_startup();

	_io_dldi.fn_readsectors(0, 1, 0x2100000);

	putline("It sorta worked!", 3);

	while (1);
}
