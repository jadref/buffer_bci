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
  
  pacman -- Example BCI system for playing 3 simple games (Snake, Sokoban and Pacman) using and visual evoked response (ERP) type BCI

  imaginedMovement -- Example BCI system for controlling a cursor using an imagined movement (ERSP) type BCI

  matrixSpeller -- Example BCI system for spelling characters using a visual matrix-speller (p300) type BCI

Installation
------------

Copy these directories somewhere on your local harddrive.

QuickStart
----------

Read the readme.txt file in either of the pacman, imaginedMovement, or matrixSpeller directories for instructions on how to startup and run those demos.

To run the pacman demo:
1) Start a buffer by running: dataAcq/startBuffer.bat or buffer/startBuffer.sh
(optional) 1.1) Start a simulated data source (if you don't have an measurement system connected) by running: dataAcq/startSignalProxy.bat or .sh
2) Start the Matlab based signal processing proces by running: pacman/startSigProcBuffer.bat or .sh
3) Start the Matlab based experiment control & stimulus presentation system by running : pacman/runGame.bat or runGame.sh
4) Type in the subject name to the experiment control window, and then run through each of the experiment phases: 
   Practice -- practice the task to be used in the BCI.  Green arrows indicate target locations you should attend to by counting the white and red arrow 'flashes'
   Calibration -- get calibration data by attending as instructed for ~90seconds
   Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.
5) Selected the game you would like to play!
