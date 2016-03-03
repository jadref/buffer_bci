# Copyright (C) 2008, Robert Oostenveld
# Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
# Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
# Kapittelweg 29, 6525 EN Nijmegen, The Netherlands

PLATFORM = $(shell gcc -dumpmachine)
UNAME = $(shell uname)
MACHINE = $(shell uname -m)

# defaults, might be overwritten further down
CC = gcc
INCPATH = -I.
LDPATH = -L.
LDLIBS = -static -lbuffer -lm -lpthread  # static link to minimise dependencies at run-time?
LDFLAGS= 

ifneq (,$(findstring mingw, $(PLATFORM)))
	BINDIR  = ../win32
	INCPATH += -I../pthreads-win32/include
	LDPATH += -L../pthreads-win32/lib
	LDLIBS += -lpthreadGC2
	RM = del
endif
ifneq (,$(findstring cygwin, $(PLATFORM)))
  # N.B. cygwin is *not* win32....
endif

ifeq "$(PLATFORM)" "x86_64-w64-mingw32"
	BINDIR  = ../win64
	INCPATH	+= -I../pthreads-win64/include
	LDPATH += -L../pthreads-win64/lib
	RM = del
endif

ifeq "$(UNAME)" "Darwin"
    # Snow Leopard 10.6 is the first Mac OS X version to ship with a 64 bit kernel, and obviously your
	# Mac has to have a 64 bit processor to utilize that kernel, but some 64 bit Mac's are not defaulting
	# to the 64 bit kernel. Furthermore, irrespective of the kernel, the gcc compiler is able to (cross)
    # compile objects, libraries and applications for 32 and 64 bit.
    ifeq "$(MACHINE)" "i386"
        # compile for 32 bit
	     BINDIR  = ../maci
        CFLAGS += -m32
        CXXFLAGS += -m32
        LDFLAGS += -m32
    endif
    ifeq "$(MACHINE)" "x86_64"
	     BINDIR  = ../maci64
        # compile for 64 bit
        CFLAGS += -m64
        CXXFLAGS += -m64
        LDFLAGS += -m64
    endif
endif
ifeq "$(PLATFORM)" "i686-linux-gnu"
	BINDIR  = ../glnx86
	CFLAGS  += -DDISABLE_NAGLE
endif
ifneq (,$(findstring i686-64, $(PLATFORM)))
	BINDIR  = ../glnx86_64
	CFLAGS  += -DDISABLE_NAGLE
endif

CFLAGS += $(INCPATH) -Wunused -Wall -pedantic -O0 -fPIC -g
CXXFLAGS += $(INCPATH) -Wunused -Wall -pedantic -O0 -fPIC -g

TARGETS = libbuffer.a libclient.a demo_buffer_unix$(SUFFIX) demo_buffer$(SUFFIX) 

##############################################################################
all: $(TARGETS)

libbuffer.a: tcpserver.o tcpsocket.o tcprequest.o clientrequest.o dmarequest.o cleanup.o util.o printstruct.o swapbytes.o extern.o endianutil.o socketserver.o
	 ar rv $@ $^

libclient.a: tcprequest.o util.o
	 ar rv $@ $^

%.o: %.c buffer.h message.h extern.h swapbytes.h socket_includes.h unix_includes.h
	$(CC) $(CFLAGS) -c $*.c

demo_buffer$(SUFFIX) : demo_buffer$(SUFFIX).o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDPATH) $(LDLIBS)
	cp $@ $(BINDIR)

# direct include the .o files to make a static link
demo_buffer_unix$(SUFFIX) : demo_buffer_unix$(SUFFIX).o util.o tcpserver.o tcpsocket.o cleanup.o clientrequest.o tcprequest.o socketserver.o endianutil.o cleanup.o extern.o printstruct.o dmarequest.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDPATH) $(LDLIBS) 
	cp $@ $(BINDIR)

clean:
	$(RM) *.o *.a *.obj core
