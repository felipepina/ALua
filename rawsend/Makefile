SYSNAME=$(shell uname)

include ../configure

LIBS=-ltbb -lpthread

ifeq ($(SYSNAME),Darwin)
CPPFLAGS=-O2 -fno-common $(DEFS) $(IPATH)
LDFLAGS=-bundle -undefined dynamic_lookup $(LPATH)
else
CPPFLAGS=-O2 -fpic $(DEFS) $(IPATH)
LDFLAGS=-shared -O -fpic $(LPATH)
endif

CC=gcc
LD=g++
CPP=g++
RM=rm -f

MOD=rawsend.so
OBJ=register.o rawsend.o

.PHONY: all clean

all: $(MOD)

$(MOD): $(OBJ)
	$(LD) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

clean:
	$(RM) $(OBJ) $(MOD)

install: all
	mkdir -p      $(LUA_INSTALL_LIB_PATH)
	cp rawsend.so $(LUA_INSTALL_LIB_PATH)

rawsend.o: register.h rawsend.cpp
register.o: register.h register.cpp
