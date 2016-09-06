mmelody: mmelody/mmelody

mmelody_OBJS = mmelody/mmelody.o

mmelody/mmelody: $(mmelody_OBJS)
	$(CC) $(CFLAGS) -o $@ $(mmelody_OBJS)

clean_mmelody:
	-rm -f mmelody/mmelody $(mmelody_OBJS)
