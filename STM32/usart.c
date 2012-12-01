#include "stm32f0xx_conf.h"

void delay(int cycles)
{
	volatile int i;
	for(i = 0; i < cycles; i++);
}

void hdInit()
{
	GPIOF->ODR &= ~(1 << 7); // clear RS pin
	
	GPIOB->ODR = 0x30;
	
	GPIOC->ODR = (1 << 10); // Clock E high
	delay(8);
	GPIOC->ODR = 0; // low
	delay(40000);
	
	GPIOC->ODR = (1 << 10); // high
	delay(8);
	GPIOC->ODR = 0; // low
	delay(1600);
	
	GPIOC->ODR = (1 << 10); // high
	delay(8);
	GPIOC->ODR = 0; // low
	delay(1600);
	
	GPIOB->ODR = 0x20; // set to 4-bit mode
	
	GPIOC->ODR = (1 << 10); // high
	delay(8);
	GPIOC->ODR = 0; // low
	delay(40000);
}

void hdSendByte(int byte, int type)
{
	if (type == 1)
		GPIOF->ODR |= (1 << 7);	// If data write, pull RS high
	
	GPIOB->ODR = (0xf0 & byte); // Put high nybble onto pins
	GPIOC->ODR |= (1 << 10);		// Toggle E high
	GPIOC->ODR |= (1 << 8);		// Turn on PC8 LED
	delay(1600);
	GPIOC->ODR = 0;				// Toggle E low & turn off LED
	if (type == 1)
		delay(1600);			// wait 200us for data writes
	else
		delay(40000);			// wait 5ms for command writes
	
	GPIOB->ODR = ((0x0f & byte) << 4);	// put low nybble on pins
	GPIOC->ODR |= (1 << 10);		// Toggle E high
	GPIOC->ODR |= (1 << 8);		// Turn on PC8 LED
	delay(1600);
	GPIOC->ODR = 0;				// Toggle E low & turn off LED
	if (type == 1)
		delay(1600);			// wait 200us for data writes
	else
		delay(40000);			// wait 5ms for command writes
	
	GPIOF->ODR &= ~(1 << 7);
}

/* USART2 PA.2 Tx, PA.3 Rx STM32F0-Discovery sourcer32@gmail.com */
 
int main(void)
{
  USART_InitTypeDef USART_InitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
 
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOA, ENABLE);
 
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2,ENABLE);
 
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource2, GPIO_AF_1);
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource3, GPIO_AF_1);
 
  /* Configure USART2 pins:  Rx and Tx ----------------------------*/
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_2 | GPIO_Pin_3;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_UP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
 
  USART_InitStructure.USART_BaudRate = 2400;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART2, &USART_InitStructure);
 
  USART_Cmd(USART2,ENABLE);
  
  RCC->AHBENR |= RCC_AHBENR_GPIOCEN; 	// enable the clock to GPIOC
  RCC->AHBENR |= RCC_AHBENR_GPIOBEN;  // Also GPIOB (LCD data pins)
  RCC->AHBENR |= RCC_AHBENR_GPIOFEN;  // Also GPIOF (LCD RS pin)
  GPIOF->MODER |= (1 << 14); // Enable pin 7 as GPIO
  GPIOB->MODER = 0x5500;	// Turn on PB4,5,6,7 for output
  GPIOC->MODER = (1 << 16);
  GPIOC->MODER |= (1 << 20);
  
  delay(16000);
  hdInit();
  hdSendByte(0x28, 0);
  hdSendByte(0x08, 0);
  hdSendByte(0x01, 0); // blank and home cursor
  hdSendByte(0x0f, 0); // turn on screen
 
  char buffer;
  while(1)
  {
   if ((USART2->ISR & (1 << 5)) == (1 << 5))
   {
    buffer = (USART2->RDR & (uint16_t)0x01FF);
	USART_SendData(USART2, buffer);
	hdSendByte(buffer, 1);
	buffer = 0;
   }
  }
}