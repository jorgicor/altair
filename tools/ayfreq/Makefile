SHELL = /bin/sh

.SUFFIXES:
.SUFFIXES: .c .o

CC = cc
CFLAGS = -g

OBJS = ayfreq.o

ayfreq: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	-rm -f ayfreq $(OBJS)
