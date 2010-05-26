SYSNAME=$(shell uname)

include ../configure

# Library names
LIBS=-luuid
# LIBS=-lossp-uuid

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

T=uuid.so

OBJS=uuid.o

.PHONY: all clean install

all: $(T)

$(T): $(OBJS)
	$(LD) -o $@ $(LDFLAGS) $(OBJS) $(LIBS)

clean:
	$(RM) $(OBJS) $(T)

uuid.o: uuid.c

install: all
	mkdir -p $(LUA_INSTALL_LIB_PATH)
	cp $(T) $(LUA_INSTALL_LIB_PATH)
