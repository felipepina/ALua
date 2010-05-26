SYSNAME=$(shell uname)

include ../../configure

CCR_IPATH=-I../lib $(IPATH)
CCR_LPATH=-L../lib $(LPATH)

LIBS=-lccr -ltbb -lpthread

ifeq ($(SYSNAME),Darwin)
CPPFLAGS=-O2 -fno-common $(DEFS) $(CCR_IPATH)
LDFLAGS=-bundle -undefined dynamic_lookup $(CCR_LPATH)
else
CPPFLAGS=-O2 -fpic $(DEFS) $(CCR_IPATH)
LDFLAGS=-shared -O -fpic $(CCR_LPATH)
endif

CC=gcc
LD=g++
CPP=g++
RM=rm -f

MOD=ccr.so
OBJ=register.o timer.o notify.o ccr.o

.PHONY: all clean

all: $(MOD)

$(MOD): $(OBJ)
	$(LD) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

clean:
	$(RM) $(OBJ) $(MOD)

install:
	mkdir -p      $(LUA_INSTALL_LIB_PATH)
	mkdir -p      $(LUA_INSTALL_PATH)/ccr
	cp ccr.so     $(LUA_INSTALL_LIB_PATH)
	cp ccr.lua    $(LUA_INSTALL_PATH)
	cp ccr/notify.lua $(LUA_INSTALL_PATH)/ccr
	cp ccr/timer.lua  $(LUA_INSTALL_PATH)/ccr

ccr.o: register.h ccr.h ccr.cpp
register.o: register.h register.cpp
notify.o: ccr.h notify.cpp
timer.o: ccr.h timer.cpp
