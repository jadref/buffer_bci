# Buffer BCI

Buffer BCI is a platform independent and language agnostic framework
for building Brain Computer Interface experiements.  It is based on a
*client-server architecture* with multiple clients getting and putting
data to a centeral data and events server.  The server is based on the
[fieldtrip buffer](http://fieldtrip.fcdonders.nl/development/realtime)
specificitation for data access and storage. 

The server is available for Mac, Linux and Windows and language
bindings are provided the following programming languages Matlab,
Octave, Java, Python, C\# and c.  For Matlab and Octave additional
signal-analysis, classification and example demonstration BCIs are
provided.  A summary of the language feature support is:
* C#, java, Python, c : support for accessing data and events
* Octave : with Octave_java, support for accessing data and events. Support of processing of data.  Graphics supportd depends on the graphics toolkit available, viz. Qthandles=full support, fltk=data visualization, gnuplot=no graphics.
* Matlab : R>7.4, full support for accessing data and events, signal analysis, data visualization and GUI control.

## Important Note:

This is a *client-server architecture*.  Thus to use any of the demos or run time you need at least:
1. a server running (the 'buffer') and two clients: 
2. a data-acquisation client which interfaces with the hardware to send data to the server, 
3. an application client which does something with the received data, like showing it on the screen.

Further different clients may be written in different programming languages and hence have different dependences.  As a minimum many of the clients interfacing with signal measurement hardware are written in java (specificially: the MUSE and openBCI clients) hence you will need a working java run-time to use these devices.  Further, most of the demonstration systems are written in Matlab/Octave, so you will need to install these systems to run these demos – though check the java, python and csharp directories for demonstrations written in those languages.

## Installation: General

Copy these directories somewhere on your local drive.

Note: If using MATLAB/Octave and the .bat/.sh files do not work because the MATLAB/Octave executable is not found automatically then modify the path in the file [`utilities\findMatlab.bat`](utilities/findMatlab.bat) (windows) or [`utilities/findMatlab.sh`](utilities/findMatlab.sh) (Linux/MacOSX) to point to the executable location.

### Installation: Octave+Windows
When using Matlab/Octave this code relies on java for network communication between processes.  Matlab includes a JRE internally, for octave you must download and install the *correct* JRE first.  These are specific instructions for that case:

1) First install java *32bit*.  Note: with the current version of octave is *must* be the 32bit java version, e.g. from <https://www.java.com/en/download/manual.jsp>, which is not what you get by default if you just 'download java'.

2) Then install / setup octave.  You can find a binary installer here <https://ftp.gnu.org/gnu/octave/windows/>.  This should then auto-detect the java install and setup the java environment.

3) Check your octave-java install with: usejava('jvm') at the octave command line, which should return 1.

### Installation : MacOS

*MacOS* to run the *.sh files from the finder you need to set them to open with the *Terminal* application (which is in the utilities sub-directory of applications).  Set this by Control-clicking any .sh file and choosing 'Open With' then browse to the *Terminal* application and choose open all .sh files this way.

### Installation : Linux

*Linux* to run the *.sh files from Nautilus, the Gnome file manager, you need to set it to run 'executable text files' directly.  To do this goto: Files->Preferences, open the Behaviour tab and in the 'Executable Text Files' set it to either 'Run them' (potential security risk) or 'Ask what to do' (safer).

## QuickStart

Read the `README` file in either of the [`games`](matlab/games), [`EEGBCITutorial`](tutorial/EEGBCITutorial), [`imaginedMovement`](matlab/imaginedMovement), [`matrixSpeller`](matlab/matrixSpeller) directories for instructions on how to startup and run
those demos.  (Note: all demos require Matlab/Octave_java+QtHandles to
run correctly!)

To run the [games](matlab/games) demo:

1. Start the data Acquisation system.

 If you have *no* EEG hardware, but just want to test:

  1. start a buffer by running: [`dataAcq/startJavaBuffer.bat`](dataAcq/startJavaBuffer.bat) or [`dataAcq/startJavaBuffer.sh`](dataAcq/startJavaBuffer.sh)  
  2. start a *simulated* data source by running: [`dataAcq/startJavaSignalProxy.bat`](dataAcq\startJavaSignalProxy.bat) or [.sh](dataAcq/startJavaSignalProxy.sh)

OR
  Start a complete simulated EEG system in one step using [`debug_quickstart.bat`](debug_quickstart.bat) or [`debug_quickstart.sh`](debug_quickstart.sh)

 If you have EEG hardware connected then depending on the hardware:

  1. start a buffer by running: [`dataAcq/startJavaBuffer.bat`](dataAcq/startJavaBuffer.bat) or [`dataAcq/startJavaBuffer.sh`](dataAcq/startJavaBuffer.bat)  
  2. start appropriate acquisition driver for your device:
    * TMSi Mobita:       [`dataAcq/startMobita.bat`](dataAcq\startMobita.bat)  or  `dataAcq/startMobita.sh`  
    * Emotiv Epoc:        `dataAcq/startEmotiv.bat`  or  `dataAcq/startEmotiv.sh`  
    * Biosemi Active 2:   `dataAcq/startBiosemi.bat` or  `dataAcq/startBiosemi.sh`
    * Interaxon Muse:     `dataAcq/startMuse.bat`    or  `dataAcq/startMuse.sh`  

Note: By default raw data is saved to:  
*  *MacOS/Linux*: `~/output/test/_YYMMDD_/_HHMM_/raw_buffer/0001`  
*  *Windows*: `C:\output\test\_YYMMDD_\_HHMM_\raw_buffer\0001`  
   where `_YYMMDD_` is the date in year/month/day format, `_HHMM_` is start time hour and minutes

2. Start the Matlab/Octave based signal processing process by running: [`matlab/games/startSigProcBuffer.bat`](matlab/games/startSigProcBuffer.bat) or [`.sh`](matlab/games/startSigProcBuffer.sh)

3. Start the Matlab/Octave based experiment control & stimulus presentation system by running : [`matlab/games/runGame.bat`](matlab/games/runGame.bat) or [`runGame.sh`](matlab/games/runGame.sh)

4. Type in the subject name to the experiment control window, and then run through each of the experiment phases: 

  * Practice -- practice the task to be used in the BCI.  Green arrows indicate target locations you should attend to by counting the white and red arrow 'flashes'

  * Calibration -- get calibration data by attending as instructed for ~90seconds

  * Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.

5. Select the game you would like to play!

## Folder Structure

An overview of the included directories is:
*  [`dataAcq`](dataAcq) -- code for data acquisition, i.e. interfacing to recording hardware, based on the [field-trip buffer specification](http://fieldtrip.fcdonders.nl/development/realtime).
				 Also scripts (.bat for windows, .sh for Linux/Mac) for starting the executables
*  [`matlab`](matlab)  -- example BCIs written in the [MATLAB](http://www.mathworks.com) language also compatiable with the free+open-source [OCTAVE](http://www.gnu.org/software/octave) system.
*  [`c`](c) -- example BCIs written the raw c
*  [`python`](python) -- example BCIs written in the [Python](http://www.python.org) programming language
*  [`java`](java) -- example BCI writen in the [java](http://www.oracle.com/java) programming language
*  [`csharp`](csharp) -- example BCIs written in the [C#](https://msdn.microsoft.com/en-us/library/67ef8sbd.aspx) programming language
*  [`unity`](unity) -- example BCIs writtin in the [unity](http://unity3d.com) game development environment
*  [`tutorial`](tutorial) -- Tutorial on BCI and how to use buffer_bci arranged in lectures 1 through 5 about how BCIs work, the structure and components of a BCI and how to build a standard BCI with the buffer_bci framework

## Main example BCI systems

* [`tutorial/EEGBCITutorial`](tutorial/EEGBCITutorial) -- Tutorial on how to use an EEG BCI, including general experience on EEG signals, and two simple BCIs; imagined-movements, and a visual-p300 speller.
				 
*  [`matlab/imaginedMovement`](matlab/imaginedMovement) -- Example BCI system for controlling a cursor using an imagined movement (ERSP) type BCI

*  [`matlab/matrixSpeller`](matlab/matrixSpeller) -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI

*  [`matlab/matrixSpellerPTB`](matlab/matrixSpellerPTB) -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI.  This version uses PsychToolBox to improve the timing of the visual stimulus rendering.  
    N.B. to use this you will need to set the PTB path correctly in `utilities/initPTBPaths.m`

*  [`matlab/cursorControl`](matlab/cursorControl) -- Example BCI system for controlling a cursor in 2-d using visual evoked response (ERP) type BCI
