Simple IRQ demo: Draw a pixel to the screen; wait for Vblank; interrupt handler will then change the color for the next pixel; keep drawing pixels until the screen is full.

This version does not use BIOS calls and instead installs its own IRQ vector.
