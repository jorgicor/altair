SHELL = /bin/sh

.SUFFIXES:
.SUFFIXES: .c .o

CC = cc
CFLAGS = -g

OBJS = beeper.o

beeper: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	-rm -f beeper $(OBJS)
