SYSNAME=$(shell uname)

include ../configure

OBJS1=\
	alua.lua
OBJS2=\
	alua/event.lua \
	alua/marshal.lua \
	alua/mbox.lua \
	alua/task.lua \
	alua/tcp.lua \
	alua/thread.lua \
	alua/timer.lua

all clean:
	cd unix && $(MAKE) $@

install:
	cd unix && $(MAKE) $@
	mkdir -p $(LUA_INSTALL_PATH)
	mkdir -p $(LUA_INSTALL_PATH)/alua
	cp $(OBJS1) $(LUA_INSTALL_PATH)
	cp $(OBJS2) $(LUA_INSTALL_PATH)/alua