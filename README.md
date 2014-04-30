buffer_bci
==========

Simple Matlab/Octave based framework for building Brain Computer/Machine Interfaces (BCI/BMI)s

This directory contains all the matlab code, and associated .mex files for the BCI framework used in the BCI Practical course.
This system has been tested to work on Mac, Windows or Linux, and works with any Matlab version >R14.

An overview of the included directories is:
  dataAcq -- code for data acquisition, i.e. interfacing to recording hardware, based on the field-trip buffer specification <http://fieldtrip.fcdonders.nl/development/realtime>.
             Also code for generating and waiting for events via the buffer
				 Also scripts (.bat for windows, .sh for Linux/Mac) for starting the executables
  dataAcq/buffer -- mex files for MATLAB access to fieldtrip buffer data storage
  dataAcq/buffer/glnx86 -- linux executable binaries for hardware access
  dataAcq/buffer/glnxa86 -- 64-bit linux executable binaries for hardware access
  dataAcq/buffer/maci   -- (intel) Mac OS executable binaries for hardware access
  dataAcq/buffer/maci64 -- 64-bit (intel) Mac OS executable binaries for hardware access
  dataAcq/buffer/win32  -- windows executable binaries for hardware access

  signalProc -- code for pre-processing EEG data, training classifiers, and applying the trained classifiers on-line for the ERP and ERSP based BCIs

  stimulus -- utility functions for generating correctly randomised stimulus sequences

  utilties -- various utility functions for BCI use, in particular for loading cap position layout files, setting up paths, option parsing etc.

  classifiers -- code for the linear logistic regression classifier, and associated utility functions for e.g. cross-validation, performance estimation etc.

  plotting -- various plotting utility functions, e.g. plotting topographic head outlines, plotting 3-d data (multi-plots), zooming multi-plots
  
  offline -- Example scripts for process saved BCI data offline, i.e. analysing data loaded from file

  example -- Example clients for the major supported programming languages; Matlab, java, Python, C#

  tutorial -- Tutorial arranged in lectures 1 through 5 about how BCIs work, 
              the structure and components of a BCI and how to build a standard BCI with the buffer_bci framework

  games -- Example BCI system for playing 3 simple games (Snake, Sokoban and Pacman) using and visual evoked response (ERP) type BCI

  imaginedMovement -- Example BCI system for controlling a cursor using an imagined movement (ERSP) type BCI

  matrixSpeller -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI

  cursorControl -- Example BCI system for controlling a cursor in 2-d using
                             visual evoked response (ERP) type BCI

  evokedDemo -- Example system for visualizing responses evoked by visual
                            stimulus, both transient and steady state, and
                            attention related (p300 type) changes.

  inducedDemo -- Example system for visualizing induced responses.


Installation
------------

Copy these directories somewhere on your local harddrive.

*Windows Only* : modify the path in the file utilities/findMatlab.bat to point to your install of matlab

*OSX Only* : make the recording file runnable by executing this command in your terminal: sudo chmod +x /dataAcq/buffer/maci/recording

Read the readme.txt file in either of the games, imaginedMovement, or matrixSpeller directories for instructions on how to startup and run those demos.

To run the games demo:

1) Start the data Acquisation system.

 If you have *no* EEG hardware, but just want to test:
  1.1) start a buffer by running: dataAcq/startBuffer.bat or buffer/startBuffer.sh
  1.2) start a *simulated* data source by running: dataAcq/startSignalProxy.bat or .sh

 If you have EEG hardware connected then depending on the hardware:
  TMSi Mobita
  		 1.1) start a buffer by running: dataAcq/startBuffer.bat or buffer/startBuffer.sh
       1.2) start the hardware driver by running: dataAcq/startMobita.bat or dataAcq/startMobita.sh
   Emotiv Epoc:
	    1.1) start the hardware driver *only* by running: dataAcq/startEmotiv.bat or dataAcq/startEmotiv.sh
   Biosemi Active 2:
       1.1) start the hardware driver *only* by running: dataAcq/startBiosemi.bat or dataAcq/startBiosemi.sh

2) Start the Matlab based signal processing process by running: games/startSigProcBuffer.bat or .sh

3) Start the Matlab based experiment control & stimulus presentation system by running : games/runGame.bat or runGame.sh

4) Type in the subject name to the experiment control window, and then run through each of the experiment phases: 

   Practice -- practice the task to be used in the BCI.  Green arrows indicate target locations you should attend to by counting the white and red arrow 'flashes'

   Calibration -- get calibration data by attending as instructed for ~90seconds

   Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.

5) Select the game you would like to play!
