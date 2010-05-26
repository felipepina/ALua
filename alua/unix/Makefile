SYSNAME=$(shell uname)

include ../../configure

ifeq ($(SYSNAME),Darwin)
LD=env MACOSX_DEPLOYMENT_TARGET="10.5" gcc
CFLAGS=-O2 -fno-common $(IPATH)
LDFLAGS=-bundle -undefined dynamic_lookup $(LPATH)
else
LD=gcc
CFLAGS=-O2 -fpic $(IPATH)
LDFLAGS=-shared -O -fpic $(LPATH)
endif

CC=gcc
RM=rm -f

OBJS=alua.o
CMOD=alua.so

.PHONY: all clean install

all: $(CMOD)

install:
	mkdir -p $(LUA_INSTALL_LIB_PATH)
	cp $(CMOD) $(LUA_INSTALL_LIB_PATH)

$(CMOD): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

clean:
	$(RM) alua.o alua.so
