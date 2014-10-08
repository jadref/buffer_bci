PLATFORM = $(shell gcc -dumpmachine)
FTBUFFER = ../../dataAcq/buffer/c


CXX = gcc
CXXFLAGS = -I$(FTBUFFER) -Wall
##LDFLAGS = -L$(FTBUFFER)/src
LDLIBS = -lm
LIBEXT=so
EXTENSION=

# turn-on optimization
#CXXFLAGS += -O3 -g
# turn-on profile code
#CXXFLAGS += -g #-pg

#windows
ifneq (,$(findstring mingw, $(PLATFORM)))
#	BINDIR = $(FTPATH)/realtime/bin/win32
	BINDIR = ../../dataAcq/buffer/win32
	EXTENSION = .exe
#	LDLIBS += -lws2_32 $(BINDIR)/pthreadGC2.dll 
	LDLIBS += -lws2_32
	LDFLAGS += -static
   # Make clean target work on windows:
	fixpath = $(subst /,\,$1)
#	RM = del
endif
ifneq (,$(findstring cygwin, $(PLATFORM))) # cygwin is *not* w32!
endif

ifneq (,$(findstring i686-apple-darwin,$(PLATFORM))) # MacOS
#	BINDIR = $(FTPATH)/realtime/bin/maci
	BINDIR = ../../dataAcq/buffer/maci
	CFLAGS += -m32
	CXXFLAGS += -m32 -DDISABLE_NAGLE
	LDLIBS += -lpthread -m32
	fixpath = $1
	LIBEXT=la
endif

ifneq (,$(findstring linux,$(PLATFORM))) # linux
	CXX = gcc
#	BINDIR = $(FTPATH)/realtime/bin/glnx86
	BINDIR = ../../dataAcq/buffer/glnx86
   # Only Linux has BLUEz support
	CXXFLAGS += -DDISABLE_NAGLE
endif

# dependencies info
CLIENTSOURCES = cclient.c 
PROXYSOURCES  = csignalproxy.c 
bufferSOURCES = $(FTBUFFER)/util.c $(FTBUFFER)/tcprequest.c $(FTBUFFER)/cleanup.c

TARGETS = cclient$(EXTENSION) csignalproxy$(EXTENSION)

all: $(TARGETS)

cclient$(EXTENSION): $(CLIENTSOURCES) $(bufferSOURCES)
	$(CXX) -o cclient $^ $(CXXFLAGS) $(LDFLAGS) $(LDLIBS)

csignalproxy$(EXTENSION): $(PROXYSOURCES) $(bufferSOURCES)
	$(CXX) -o csignalproxy $^ $(CXXFLAGS) $(LDFLAGS) $(LDLIBS)
	cp csignalproxy${EXTENSION} ${BINDIR}

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) cclient$(EXTENSION)
