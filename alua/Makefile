SYSNAME=$(shell uname)

include ../configure

OBJS1=\
	alua.lua
OBJS2=\
	alua/dht.lua \
	alua/event.lua \
	alua/group.lua \
	alua/marshal.lua \
	alua/mbox.lua \
	alua/network.lua \
	alua/task.lua \
	alua/tcp.lua \
	alua/thread.lua \
	alua/timer.lua
OBJS3=\
	alua/dht/route.lua \
	alua/dht/storage.lua

all clean:
	cd unix && $(MAKE) $@

install:
	cd unix && $(MAKE) $@
	mkdir -p $(LUA_INSTALL_PATH)
	mkdir -p $(LUA_INSTALL_PATH)/alua
	mkdir -p $(LUA_INSTALL_PATH)/alua/dht
	cp $(OBJS1) $(LUA_INSTALL_PATH)
	cp $(OBJS2) $(LUA_INSTALL_PATH)/alua
	cp $(OBJS3) $(LUA_INSTALL_PATH)/alua/dht