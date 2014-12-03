PsycoPy Stimulus Example
------------------------

This directory contains a simple example of a BCI experiment developed with the [PsychoPy](www.psychopy.org) python based experiment design system.  This experiment has been developed with the _PsychoPy_ GUI experiment builder system.  To use this experiment you should switch to 'Builder View' and load the file `simple_imagined_movement.psyexp`.

The included experiment *only* performs the stimulus display and experiment control.  To run a complete experiment you will additionally need to:
  1) Run a buffer server
  2) Run a data-acquisation system
  3) Run a signal analysis system to firstly gather the labelled data, and secondly to generate feedback intructions on demand.  (A standard Matlab based ERsP pipeline should work for this purpose.)

Below gives and overview of how to start and run this demo:

**Running the Demo**

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

2) Start the a signal processing proces by running: games/startSigProcBuffer.bat or .sh
   You will then be asked to select a 'capFile'.  Pick the one appropriate to your EEG system, if in doubt then select `1010.txt`.

3) Start the *Python* (specificially PsychoPy) based experiment control & stimulus presentation system.
    3.1) First start PsychoPy
    3.2) Now Go to the View menu and switch to 'Builder View'
    3.3) Now load the file: `simple_imagined_movement.psyexp`
    3.4) Run the file by pressing the green running man button.

4) Type in the subject name and session in the participant information window.  Then follow the presented instructions to run the experiment.