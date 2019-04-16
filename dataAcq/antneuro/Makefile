PLATFORM = $(shell gcc -dumpmachine)
UNAME = $(shell uname)
ifndef MACHINE
	MACHINE = $(shell uname -m)
endif
FTPATH   = ../buffer
FTCPPPATH= $(FTPATH)/cpp
FTBUFFER = $(FTPATH)

CXX = g++
##LDFLAGS = -L$(FTBUFFER)
LDLIBS = -lm
LDXXLIBS= $(LDLIBS)
LIBEXT=so
EXTENSION=

# turn-on optimization
CFLAGS += -O3
# turn-on profile code
#CFLAGS += -g -pg -O 

# defaults, might be overwritten further down
INCPATH = -I$(FTBUFFER)/c -I$(CPPDIR) -I. 
LDFLAGS = -L$(FTBUFFER)/c
CFLAGS = $(INCPATH) -Wunused -Wall -pedantic -O3 
CXXFLAGS = $(CFLAGS) -std=c++11

CFLAGS = -I$(FTBUFFER)/src -I$(FTBUFFER)/cpp -I$(FTBUFFER)/c -I. -I$(CPPDIR) -Wall
CXXFLAGS= $(CFLAGS)
LDFLAGS = -L$(FTBUFFER)
LDXXFLAGS= $(LDFLAGS)  -lstdc++

# to avoid dependencies just build everything from source every time...
CPPSOURCES = $(patsubst %,$(FTCPPPATH)/%,\
	SignalConfiguration.cc GdfWriter.cc FtConnection.cc StringServer.cc)
CSOURCES = 	$(patsubst %,$(FTPATH)/c/%,\
	tcpserver.c tcpsocket.c tcprequest.c clientrequest.c dmarequest.c cleanup.c util.c printstruct.c swapbytes.c extern.c endianutil.c socketserver.c)
# dependencies info
SOURCES = eego2ft.cc

ifneq (,$(findstring mingw, $(PLATFORM)))
	BINDIR = $(FTBUFFER)/win32
	SUFFIX = .exe
	fixpath = $(subst /,\,$1)
	EEGOLIBDIR=windows/32bit/eego-SDK.dll
	LDLIBS += -lws2_32 $(BINDIR)/pthreads-win32/lib/pthreadGC2.dll $(EEGOLIBDIR)/eego-SDK.dll
	INCPATH += -I./portaudio -I$(FTBUFFER)/win32/include 
	LDFLAGS += -static
	RM = del
endif
ifneq (,$(findstring msys, $(PLATFORM)))
	BINDIR = $(FTBUFFER)/win32
	SUFFIX = .exe
	fixpath = $(subst /,\,$1)
	EEGOLIBDIR=windows/32bit/eego-SDK.dll
	LDLIBS += -lws2_32 $(BINDIR)/pthreads-win32/lib/pthreadGC2.dll windows/32bit/eego-SDK.dll
	INCPATH += -I$(FTBUFFER)/win32/include
	LDFLAGS += -static
	RM = rm
endif
ifneq (,$(findstring cygwin, $(PLATFORM))) # cygwin is *not* w32!
endif

ifeq "$(UNAME)" "Linux"
    fixpath = $1
    ifeq "$(MACHINE)" "i686"
		BINDIR = $(FTBUFFER)/glnx86
		EEGOLIBDIR=linux/32bit
	   LDLIBS += $(EEGOLIBDIR)/libeego-SDK.so
    endif
    ifeq "$(MACHINE)" "x86_64"
		BINDIR = $(FTBUFFER)/glnxa64
		EEGOLIBDIR=linux/64bit
	   LDLIBS += $(EEGOLIBDIR)/libeego-SDK.so
    endif
    ifeq "$(MACHINE)" "armv6l"
		BINDIR = $(FTBUFFER)/raspberrypi
		EEGOLIBDIR=linux/arm32bit
	   LDLIBS += $(EEGOLIBDIR)/libeego-SDK.so
    endif
    ifeq "$(MACHINE)" "armv7l"
		BINDIR = $(FTBUFFER)/raspberrypi
		EEGOLIBDIR=linux/arm32bit
	   LDLIBS += $(EEGOLIBDIR)/libeego-SDK.so
	   LD = arm-none-eabi+g++
           #LDXXFLAGS += --stl=gnustl
		CXX = arm-linux-gnueabihf-g++
		CXXFLAGS += -fpermissive # -fno-exceptions
    endif
    ifeq "$(MACHINE)" "aarch64"
		BINDIR = $(FTBUFFER)/raspberrypi
		EEGOLIBDIR=linux/arm32bit
		LDLIBS += $(EEGOLIBDIR)/libeego-SDK.so
		# cross-compile to arm32
		CXX = arm-linux-gnueabihf-g++
		#LDFLAGS = -static
		CXXFLAGS += -fpermissive
	endif
   # Cross-compile for windows on linux
	ifeq "$(MACHINE)" "mingw32"
		CXX = i686-w64-mingw32-g++
		BINDIR = $(FTBUFFER)/win32
		SUFFIX = .exe
		fixpath = $(subst /,\,$1)
		EEGOLIBDIR=windows/32bit
		LDLIBS += -lws2_32 $(BINDIR)/pthreadGC2.dll -lpthread $(EEGOLIBDIR)/eego-SDK.dll
		INCPATH += -I$(FTBUFFER)/win32/include
      # Build directly from sources to avoid dependency issues with e.g. .o files
		LDFLAGS += -static
	else
		LDLIBS += -lpthread -ldl
	   LDFLAGS += -L$(FTBUFFER)/c
	endif
endif

ifneq (,$(findstring apple-darwin,$(PLATFORM))) # MacOS
#	BINDIR = $(FTPATH)/realtime/bin/maci
	BINDIR = ../buffer/maci
	CFLAGS += -m32 -DDISABLE_NAGLE -mmacosx-version-min=10.5
	LDLIBS += -lpthread -m32
	fixpath = $1
	LIBEXT=la
	EEGOLIBDIR= linux/64bit
	LDFLAGS += -Lmaci -leego-SDK
endif

TARGETS = eego2ft$(SUFFIX)

all: $(TARGETS)

eego2ft$(SUFFIX): $(SOURCES) $(CPPSOURCES) $(CSOURCES)
	$(CXX) -o eego2ft$(SUFFIX) $^ $(LDXXLIBS) $(CXXFLAGS) $(LDXXFLAGS) 
	cp eego2ft$(SUFFIX) $(BINDIR)
	cp eego2ft$(SUFFIX) $(EEGOLIBDIR)
	cp $(EEGOLIBDIR)/* $(BINDIR)

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) eego2ft$(EXTENSION) eego2ft.exe
