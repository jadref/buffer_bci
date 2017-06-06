PLATFORM = $(shell gcc -dumpmachine)
FTPATH   = ../buffer
FTCPPPATH= $(FTPATH)/cpp
FTBUFFER = $(FTPATH)

CXX = gcc
##LDFLAGS = -L$(FTBUFFER)
LDLIBS = -lm
LDXXLIBS= $(LDLIBS)
LIBEXT=so
EXTENSION=

# turn-on optimization
CFLAGS += -O3
# turn-on profile code
#CFLAGS += -g -pg -O 

CFLAGS = -I$(FTBUFFER)/src -I$(FTBUFFER)/cpp -I$(FTBUFFER)/c -I. -I$(CPPDIR) -Wall
CXXFLAGS= $(CFLAGS)
LDFLAGS = -L$(FTBUFFER)
LDXXFLAGS= $(LDFLAGS) -lstdc++

#windows
ifneq (,$(findstring mingw, $(PLATFORM)))
#	BINDIR = $(FTPATH)/realtime/bin/win32
	BINDIR = ../buffer/win32
	EXTENSION = .exe
#	LDLIBS += -lws2_32 $(BINDIR)/pthreadGC2.dll 
#	LDLIBS += -lws2_32
	EEGOLIBDIR= windows/32bit
	LDFLAGS += -static -L$(EEGOLIBDIR) -leego-SDK
	CFLAGS += -I$(BINDIR)/pthreads-win32/include
	LDFLAGS += -L$(BINDIR)/pthreads-win32/lib -lws2_32 -lpthreadGC2
   # Make clean target work on windows:
	fixpath = $(subst /,\,$1)
#	RM = del
endif
ifneq (,$(findstring cygwin, $(PLATFORM))) # cygwin is *not* w32!
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

ifneq (,$(findstring linux,$(PLATFORM))) # linux
	CXX = g++
#	BINDIR = $(FTPATH)/realtime/bin/glnx86
	BINDIR = ../buffer/glnx86
	CFLAGS += -DDISABLE_NAGLE
	EEGOLIBDIR= linux/64bit
	LDFLAGS+= -lpthread -L$(EEGOLIBDIR) -leego-SDK
endif

# dependencies info
SOURCES = eego2ft.cc
bufferSOURCES = $(patsubst %,$(FTPATH)/cpp/%,\
	SignalConfiguration.o GdfWriter.o FtConnection.o StringServer.o)\
	$(patsubst %,$(FTPATH)/c/%,\
	tcpserver.o tcpsocket.o tcprequest.o clientrequest.o dmarequest.o cleanup.o util.o printstruct.o swapbytes.o extern.o endianutil.o socketserver.o)

TARGETS = eego2ft$(EXTENSION)

all: $(TARGETS)

eego2ft$(EXTENSION): $(SOURCES) $(bufferSOURCES)
	$(CXX) -o eego2ft $^ $(CXXFLAGS) $(LDXXFLAGS) $(LDXXLIBS)
	cp eego2ft$(EXTENSION) $(BINDIR)
	cp $(EEGOLIBDIR)/* $(BINDIR)

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) eego2ft$(EXTENSION)
