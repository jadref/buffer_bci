# Buffer BCI

Buffer BCI is a platform independent and language agnostic framework
for building Brain Computer Interface experiements.  It is based on a
client-server architecture with multiple clients getting and putting
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

## Folder Structure

An overview of the included directories is:
*  `dataAcq` -- code for data acquisition, i.e. interfacing to recording hardware, based on the [field-trip buffer specification](http://fieldtrip.fcdonders.nl/development/realtime).
				 Also scripts (.bat for windows, .sh for Linux/Mac) for starting the executables
*  `dataAcq/buffer` -- binary and source files for the fieldtrip buffer implementation
*  `dataAcq/buffer/glnx86` -- linux executable binaries for hardware access
*  `dataAcq/buffer/glnxa86` -- 64-bit linux executable binaries for hardware access
*  `dataAcq/buffer/maci`   -- (intel) Mac OS executable binaries for hardware access
*  `dataAcq/buffer/maci64` -- 64-bit (intel) Mac OS executable binaries for hardware access
*  `dataAcq/buffer/win32`  -- windows executable binaries for hardware access
*  `dataAcq/buffer/c`      -- buffer client driver code in C
*  `dataAcq/buffer/csharp` -- buffer client driver code in C#
*  `dataAcq/buffer/python` -- buffer client driver code in Python
*  `dataAcq/buffer/java`   -- buffer client driver code in java

*  `signalProc` -- code for pre-processing EEG data, training classifiers, and applying the trained classifiers on-line for the ERP and ERSP based BCIs

*  `stimulus` -- utility functions for generating correctly randomised stimulus sequences

*  `utilties` -- various utility functions for BCI use, in particular for loading cap position layout files, setting up paths, option parsing etc.

*  `classifiers` -- code for the linear logistic regression classifier, and associated utility functions for e.g. cross-validation, performance estimation etc.

*  `plotting` -- various plotting utility functions, e.g. plotting topographic head outlines, plotting 3-d data (multi-plots), zooming multi-plots
  
*  `games` -- Example BCI system for playing 3 simple games (Snake, Sokoban and Pacman) using and visual evoked response (ERP) type BCI

*  `offline` -- Example scripts for process saved BCI data offline, i.e. analysing data loaded from file

*  `example` -- Example clients for the major supported programming languages; Matlab, java, Python, C#, C

*  `tutorial` -- Tutorial arranged in lectures 1 through 5 about how BCIs work, 
              the structure and components of a BCI and how to build a standard BCI with the buffer_bci framework
				 
*  `imaginedMovement` -- Example BCI system for controlling a cursor using an imagined movement (ERSP) type BCI

*  `matrixSpeller` -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI

*  `matrixSpellerPTB` -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI.  This version uses PsychToolBox to improve the timing of the visual stimulus rendering.  
    N.B. to use this you will need to set the PTB path correctly in `utilities/initPTBPaths.m`

*  `cursorControl` -- Example BCI system for controlling a cursor in 2-d using
                             visual evoked response (ERP) type BCI

*  `evokedDemo` -- Example system for visualizing responses evoked by visual
                            stimulus, both transient and steady state, and
                            attention related (p300 type) changes.

*  `inducedDemo` -- Example system for visualizing induced responses.


## Installation

Copy these directories somewhere on your local drive.

Note: is using MATLAB/Octave and the executable is not found
automatically then modify the path in the file
utilities/findMatlab.bat (windows) or utilities/findMatlab.sh
(Linux/MacOSX) to point to the executable location

Note2: For Linux there is a [Docker image]( https://github.com/dokterbob/docker-bci) which can be used to simply install buffer_bci and all it's dependencies directly 


## QuickStart


Read the readme.txt file in either of the games, imaginedMovement, or
matrixSpeller directories for instructions on how to startup and run
those demos.  (Note: all demos require Matlab/Octave_java+QtHandles to
run correctly!)

To run the games demo:

1. Start the data Acquisation system.

 If you have *no* EEG hardware, but just want to test:

  1.2) start a buffer by running: `dataAcq/startBuffer.bat` or `buffer/startBuffer.sh`  
  1.2) start a *simulated* data source by running: `dataAcq/startSignalProxy.bat` or .sh

 If you have EEG hardware connected then depending on the hardware:

  1.1) start a buffer by running: `dataAcq/startBuffer.bat` or `buffer/startBuffer.sh`  
  1.2) start appropriate acquisition driver for your device:  
  		 TMSi Mobita([mobita]):       `dataAcq/startMobita.bat`  or  `dataAcq/startMobita.sh`  
       Emotiv Epoc:        `dataAcq/startEmotiv.bat`  or  `dataAcq/startEmotiv.sh`  
       Biosemi Active 2:   `dataAcq/startBiosemi.bat` or  `dataAcq/startBiosemi.sh`  
		 Interaxon Muse:     `dataAcq/startMuse.bat`    or  `dataAcq/startMuse.sh`  

2. Start the Matlab/Octave based signal processing process by running: `games/startSigProcBuffer.bat` or .sh

3. Start the Matlab/Octave based experiment control & stimulus presentation system by running : `games/runGame.bat` or runGame.sh

4. Type in the subject name to the experiment control window, and then run through each of the experiment phases: 

  * Practice -- practice the task to be used in the BCI.  Green arrows indicate target locations you should attend to by counting the white and red arrow 'flashes'

  * Calibration -- get calibration data by attending as instructed for ~90seconds

  * Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.

5. Select the game you would like to play!



###Notes: TMSi mobita {mobita}
This device uses wifi to connect between the computer and the amplifier.  When recording data this connection *cannot* be disconnected.  Unfortunately, most OSs currently have a wifi auto-scan system which will periodically scan for 'better' wifi networks.  This scanning will interrupt data sending and cause the connection to be temporally lost for 1-3seconds.   To prevent this you need to prevent wifi auto-scanning, how this is done differs depending on OS.
* Linux: on most current linux wifi is managed by NetworkManager.  By stopping this process from running you can prevent wifi auto-scanning.  Do this by: `killall -STOP NetworkManager`.  To resume auto-scanning use: `killall -CONT NetworkManager'
* Windows: to stop network scanning follow the instructions [here](http://answers.microsoft.com/en-us/windows/forum/windows_7-networking/how-to-disable-automatic-scanning-for-wifi/4c8253ec-40c6-42c8-a9f7-00d78fce966c).  Briefly:

To disable automatic scanning for Wireless networks, we need to stop WLAN autoconfig service.
a.       Click the "Start" button.
b.      Type "services.msc" in the field that appears. Press "Enter" key on your keyboard.
c.       Find "WLAN autoconfig" and right-click on it. Choose "Stop" or "Pause" in the list of options that appears.
Note: To enable the Wireless networks, follow the same steps but choose "Resume" or "Restart" in the same list of options.
