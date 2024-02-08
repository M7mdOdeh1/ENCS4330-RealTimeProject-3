# MPLAB IDE generated this makefile for use with GNU make.
# Project: master.mcp
# Date: Fri Feb 09 00:55:28 2024

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

master.cof : master.o
	$(CC) /p16F877A "16f877a_g.lkr" "master.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"master.cof" /M"master.map" /W

master.o : master.asm P16F877A.INC LCDIS.INC
	$(AS) /q /p16F877A "master.asm" /l"master.lst" /e"master.err" /o"master.o" /d__DEBUG=1

clean : 
	$(CC) "master.o" "master.err" "master.lst" "master.cof" "master.hex"

