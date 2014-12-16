FTPATH = ../buffer/java
FTBUFFER = $(FTPATH)

JAVAC=javac
JAVAFLAGS= -source 1.5 -target 1.5
JAVACLASSPATH= -classpath ${FTPATH}/BufferClient.jar:./jssc.jar

LDLIBS = -lm
LIBEXT=so
EXTENSION=

# dependencies info
SOURCES = openBCI2ft.java OpenBCI_ADS1299.java
bufferSOURCES = 

TARGETS = openbci2ft.class

all: $(TARGETS)

openbci2ft.class: $(SOURCES) $(bufferSOURCES)
	$(JAVAC) $^ $(JAVAFLAGS) $(JAVACLASSPATH)

clean:
	$(RM) *.o $(call fixpath, $(TARGETS)) mobita2ft$(EXTENSION)
