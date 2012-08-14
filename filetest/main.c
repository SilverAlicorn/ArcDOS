#include "ndsarm9.h"
#include "console.h"

struct io_interface {
	unsigned long iotype;
	unsigned long features;
	int (*startup)(void);
	int (*ininserted)(void);
	int (*readsectors)(int sector, int numsecs, void* buffer);
	int (*writesectors)(int sector, int numsecs, void* buffer);
	int (*clearstatus)(void);
	int (*shutdown)(void);
};

extern struct io_interface _io_dldi;

int main()
{
	console_init();

//	puts("Hello, world\n", MAIN_SCREEN);
	putline("Hello ArcDOS!", 0);

	_io_dldi.startup();
	
	char buffer[512];
	char partition[10];

	_io_dldi.readsectors(0, 1, buffer);
	if ((buffer[510] == 0x55) && (buffer[511] == 0xaa)){
		putline("MBR VALID", 2);

		/* Check for boot flag on partition 1 */
		if (buffer[446] == 0x80)
			putline("Partition bootable", 3);
		else if (buffer[446] == 0x00)
			putline("Partition not bootable", 3);
		else
			putline("Boot flag invalid", 3);

		char lbaout[8];
		int lba = buffer[457];
		lba = lba << 8;
		lba |= buffer[456];
		lba = lba << 8;
		lba |= buffer[455];
		lba = lba << 8;
		lba |= buffer[454];

		int p1start = lba;

		hex2ascii(&lba, lbaout);
		putline("Partition 1 LBA:", 5);
		putline(lbaout, 6);
		
		lba = buffer[461];
		lba = lba << 8;
		lba |= buffer[460];
		lba = lba << 8;
		lba |= buffer[459];
		lba = lba << 8;
		lba |= buffer[458];

		hex2ascii(&lba, lbaout);
		putline("Partition 1 size:", 7);
		putline(lbaout, 8);
		
		_io_dldi.readsectors(p1start, 1, buffer);
		hex2ascii(&buffer[21], lbaout);
		putline("Partition 1 media descriptor:", 9);
		putline(lbaout, 10);

	}
	else
		putline("NO VALID MBR FOUND!", 2);

	while (1);
}
