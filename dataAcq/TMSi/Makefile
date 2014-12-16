PLATFORM = $(shell gcc -dumpmachine)
FTPATH = ../buffer/c
FTBUFFER = $(FTPATH)

CXX = gcc
CXXFLAGS = -I$(FTBUFFER) -Wall
##LDFLAGS = -L$(FTBUFFER)
LDLIBS = -lm
LIBEXT=so
EXTENSION=

# turn-on optimization
CXXFLAGS += -O3
# turn-on profile code
#CXXFLAGS += -g -pg -O 

#windows
ifneq (,$(findstring mingw, $(PLATFORM)))
#	BINDIR = $(FTPATH)/realtime/bin/win32
	BINDIR = ../buffer/win32
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

ifneq (,$(findstring apple-darwin,$(PLATFORM))) # MacOS
#	BINDIR = $(FTPATH)/realtime/bin/maci
	BINDIR = ../buffer/maci
	CFLAGS += -m32 -DDISABLE_NAGLE -mmacosx-version-min=10.5
	CXXFLAGS += -m32 -DDISABLE_NAGLE -mmacosx-version-min=10.5
	LDLIBS += -lpthread -m32
	fixpath = $1
	LIBEXT=la
endif

ifneq (,$(findstring linux,$(PLATFORM))) # linux
	CXX = gcc
#	BINDIR = $(FTPATH)/realtime/bin/glnx86
	BINDIR = ../buffer/glnx86
   # Only Linux has BLUEz support
	CXXFLAGS += -DDISABLE_NAGLE
	LDFLAGS += -l:libbluetooth.a 
endif

# dependencies info
SOURCES = mobita2ft.c tmsi.c
SOURCESSPLIT = mobita2ft_split.c tmsi.c
bufferSOURCES = $(FTBUFFER)/util.c $(FTBUFFER)/tcprequest.c $(FTBUFFER)/cleanup.c

TARGETS = mobita2ft$(EXTENSION)

all: $(TARGETS)

mobita2ft$(EXTENSION): $(SOURCES) $(bufferSOURCES)
	$(CXX) -o mobita2ft $^ $(CXXFLAGS) $(LDFLAGS) $(LDLIBS)
	cp mobita2ft$(EXTENSION) $(BINDIR)

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) mobita2ft$(EXTENSION)
