QuickStart
----------

To run the pacman demo:
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


2) Start the Matlab based signal processing proces by running: games/startSigProcBuffer.bat or .sh


3) Start the Matlab based experiment control & stimulus presentation system by running : games/runGame.bat or runGame.sh

4) Type in the subject name to the experiment control window, and then run through each of the experiment phases: 
   CapFitting -- check electrode connection quality of the cap.  This will show a topographic plot of the head with the electrodes colored from red=bad to green=good.  Add additional gel or rub the electrodes until all are green.
   EEG      -- real-time EEG viewer to check electrode connection quality.  This shows a topographic arrangement of the electrodes with the current (filtered) signal in each electrode.  If you have a well connected set of electrodes you should be able to see eye-blinks in the most frontal electrodes, and muscle artifacts (such as jaw clenching) in all electrodes.
   Practice -- practice the task to be used in the BCI.  Green arrows indicate target locations you should attend to by counting the white and red arrow 'flashes'
   Calibration -- get calibration data by attending as instructed for ~90seconds
   Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.


5) Selected the game you would like to play!
