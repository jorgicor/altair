SHELL = /bin/sh

.SUFFIXES:
.SUFFIXES: .c .o

CC = cc
CFLAGS = -g

OBJS = randff.o

randff: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	-rm -f randff $(OBJS)
