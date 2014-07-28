PLATFORM = $(shell gcc -dumpmachine)
FTBUFFER = ../../buffer/c

EMOKITPATH = ../emokit-master
LIBMCRYPTPATH= ../libmcrypt
LIBHIDAPIPATH=/usr/local 

CXX = gcc
CXXFLAGS = -I$(FTBUFFER) -Wunused -Wall -O
LDLIBS = -lm
LIBEXT=so

ifneq (,$(findsting mingw32,$(PLATFORM)))
	#BINDIR = $(FTPATH)/realtime/bin/win32
	BINDIR = ../../buffer/win32
	EXTENSION = .exe

	CXXFLAGS += -I$(EMOKITPATH)/include
	LDFLAGS += -L$(EMOKITPATH)/lib
	LDLIBS += -static -lws2_32 -lwinmm $(BINDIR)/edk.dll \
		$(BINDIR)/pthreadGC2.dll 
   # Make clean target work on windows:
	fixpath = $(subst /,\,$1)
	RM = del
endif

ifneq (,$(findstring i686-apple-darwin,$(PLATFORM)))
	BINDIR = ../../buffer/maci
	CFLAGS += -m32
	CXXFLAGS += -m32
	LDLIBS += -lpthread -m32
	fixpath = $1
	LIBEXT=la
endif

ifneq (,$(findstring linux,$(PLATFORM))) # linux
	CXX = gcc
	CXXFLAGS += -I/usr/local/include -I$(EMOKITPATH)/include   
	LIBMCRYPTPATH=/usr/
	BINDIR = ../../buffer/glnx86
	#LDFLAGS += -L$(EMOKITPATH)/lib -L$(LIBMCRPYTPATH)/lib -L/usr/local/lib -L/usr/lib -L/lib/i386-linux-gnu
	LDFLAGS += -L$(EMOKITPATH)/lib -L$(LIBMCRPYTPATH)/lib
	# All dynamic N.B. mcrypt *has* to be last here!
	#LDLIBS += -lemokit -lhidapi-hidraw -lmcrypt
	# Part static, part dynamic
	LDLIBS += -Wl,-Bstatic -lemokit -lhidapi-hidraw -Wl,-Bdynamic -lrt -lpthread -lusb-1.0 -ludev -lmcrypt
	# this doesn't work because of libhid reference stuff
	#LDLIBS += libhidapi-hidraw.a libemokit.a -lrt -lpthread -lusb-1.0 -ludev -lmcrypt
#-Wl -rpath,/usr/local/lib
endif

#echo $(PLATFORM)
#echo $(CXXFLAGS)


# dependencies info
emokit2ft: emokit2ft.c
#emokit2ft: $(EMOKITPATH)/include/emokit/emokit.h
#emokit2ft: emokit2ft.c.o
emokit2ft: $(EMOKITPATH)/lib/libemokit.a
emokit2ft: $(LIBMCRYPTPATH)/lib/libmcrypt.$(LIBEXT)
emokit2ft: $(LIBHIDAPIPATH)/usr/local/lib/libhidapi-hidraw.$(LIBEXT)


TARGETS = $(BINDIR)/emotiv2ft$(EXTENSION) emokit2ft emokit2ft2
bufferSOURCES = $(FTBUFFER)/util.c $(FTBUFFER)/tcprequest.c $(FTBUFFER)/cleanup.c

all: $(TARGETS)

emokit2ft: emokit2ft.c $(bufferSOURCES)
	gcc -o emokit2ft $(filter %.c,$^) $(CXXFLAGS) $(LDFLAGS) $(LDLIBS)
	cp emokit2ft $(BINDIR)

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) emokit2ft
