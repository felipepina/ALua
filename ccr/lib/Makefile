SYSNAME=$(shell uname)

include ../../configure

LIB_IPATH=-I. $(IPATH)
LIB_LPATH=-I. $(LPATH)

ifeq ($(SYSNAME),Darwin)
CPPFLAGS=-O2 -fno-common $(LIB_IPATH)
else
CPPFLAGS=-O2 -fpic $(LIB_IPATH)
endif

CC=gcc
LD=g++
CPP=g++
AR=ar rcu
RM=rm -f
RANLIB=ranlib

T=libccr.a

OBJS= \
 list.o     \
 alloc.o    \
 message.o  \
 mailbox.o  \
 register.o \
 thread.o 

.PHONY: all clean

all: $(T)

$(T): $(OBJS)
	$(AR) $@ $(OBJS)
	$(RANLIB) $@

clean:
	$(RM) $(OBJS) $(T)

list.o: list.h list.cpp
alloc.o: ccr/alloc.h alloc.cpp
message.o: ccr/alloc.h ccr/message.h message.cpp
register.o: ccr/mailbox.h ccr/register.h register.cpp
mailbox.o: ccr/message.h ccr/mailbox.h mailbox.cpp
thread.o: ccr/thread.h thread.cpp
