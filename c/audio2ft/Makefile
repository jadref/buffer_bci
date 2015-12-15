# Copyright (C) 2010 Bart Niehuis, Stefan Klanke
# Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
# Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
# Kapittelweg 29, 6525 EN Nijmegen, The Netherlands

# Use MinGW for compilation on Windows!
# On other platforms, make sure you have PortAudio installed.

PLATFORM = $(shell gcc -dumpmachine)
UNAME = $(shell uname)
ifndef MACHINE
	MACHINE = $(shell uname -m)
endif

FTBUFFER = ../../dataAcq/buffer
CPPDIR  = $(FTBUFFER)/cpp

# defaults, might be overwritten further down
INCPATH = -I$(FTBUFFER)/c -I$(CPPDIR) -I. 
LDFLAGS = -L$(FTBUFFER)/c
CFLAGS = $(INCPATH) -Wunused -Wall -pedantic -O3
CXXFLAGS = $(CFLAGS)

# to avoid dependencies just build everything from source every time...
CPPSRCS = $(patsubst %,$(CPPDIR)/%,\
	SignalConfiguration.cc GdfWriter.cc FtConnection.cc StringServer.cc)

ifneq (,$(findstring mingw, $(PLATFORM)))
	BINDIR = $(FTBUFFER)/win32
	SUFFIX = .exe
	fixpath = $(subst /,\,$1)
	# LDFLAGS += -L$(BINDIR) does not seem to work for DLLs. Hence:
	LDLIBS += -lbuffer -lws2_32 $(BINDIR)/pthreadGC2.dll $(BINDIR)/PortAudio.dll 
	INCPATH += -I./portaudio -I$(FTBUFFER)/win32/include
	LDFLAGS += -static
	RM = del
endif
ifneq (,$(findstring msys, $(PLATFORM)))
	BINDIR = $(FTBUFFER)/win32
	SUFFIX = .exe
	fixpath = $(subst /,\,$1)
	# LDFLAGS += -L$(BINDIR) does not seem to work for DLLs. Hence:
	LDLIBS += -lbuffer -lws2_32 $(BINDIR)/pthreadGC2.dll $(BINDIR)/PortAudio.dll 
	INCPATH += -I./portaudio -I$(FTBUFFER)/win32/include
	LDFLAGS += -static
	RM = rm
endif
ifneq (,$(findstring cygwin, $(PLATFORM))) # cygwin is *not* w32!
endif

ifeq "$(UNAME)" "Linux"
    fixpath = $1
    ifeq "$(MACHINE)" "i686"
		BINDIR = $(FTBUFFER)/glnx86
    endif
    ifeq "$(MACHINE)" "x86_64"
		BINDIR = $(FTBUFFER)/glnxa64
    endif
    ifeq "$(MACHINE)" "armv6l"
		BINDIR = $(FTBUFFER)/raspberrypi
    endif
	# Cross-compile for windows on linux
	ifeq "$(MACHINE)" "mingw32"
		CXX = i586-mingw32msvc-g++
		BINDIR = $(FTBUFFER)/win32
		SUFFIX = .exe
		fixpath = $(subst /,\,$1)
		LDLIBS += -lws2_32 -lbuffer $(BINDIR)/pthreadGC2.dll $(BINDIR)/PortAudio.dll 
		INCPATH += -I./portaudio -I$(FTBUFFER)/win32/include
		# Build directly from sources to avoid dependency issues with e.g. .o files
		FTSRCS = $(patsubst %,$(FTBUFFER)/c/%,\
						clientrequest.c util.c tcprequest.c socketserver.c \
						tcpsocket.c endianutil.c cleanup.c extern.c dmarequest.c)
	else
		LDLIBS += -lbuffer -lpthread -ldl -lportaudio
	   LDFLAGS += -L$(FTBUFFER)/c
	endif
endif

ifeq "$(UNAME)" "Darwin"
    fixpath = $1
    ifeq "$(MACHINE)" "i386"
        BINDIR = $(FTBUFFER)/maci
        CFLAGS += -m32
        CXXFLAGS += -m32
        LDFLAGS += -m32
    endif
    ifeq "$(MACHINE)" "x86_64"
        BINDIR = $(FTBUFFER)/maci64
        CFLAGS += -m64
        CXXFLAGS += -m64
        LDFLAGS += -m64
    endif
    LDLIBS += -lpthread -lportaudio
endif



ifndef BINDIR
$(error Unsupported platform: $(PLATFORM) :/.)
endif

TARGETS = $(BINDIR)/audio2ft$(SUFFIX)

##############################################################################
all: $(TARGETS)

$(BINDIR)/%$(SUFFIX): %.cc $(CPPSRCS) $(FTSRCS)
	$(CXX) -o $@ $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS)

clean:
	$(RM) $(call fixpath, $(TARGETS))
	$(RM) *.o
