## Important Note:

Buffer_bci is a *client-server architecture*.  Thus to use any of the demos or run time you need at least:
1) a server running (the 'buffer') and two clients: 
2) a data-acquisation client which interfaces with the hardware to send data to the server, 
3) an application client which does something with the received data, like showing it on the screen.

## QuickStart

0. Start the buffer server by running:
	`dataAcq/startJavaNoSaveBuffer.bat` or `dataAcq/startJavaNoSaveBuffer.sh`  
   (Note: this server does *not* save any data to disk.  If you wish to save the data user `dataAcq\startJavaBuffer.sh' or '.bat')

1. Start the data Acquisation system.

 If you have *no* EEG hardware, but just want to test:

  * start a *simulated* data source by running: `dataAcq/startJavaSignalProxy.bat` or .sh

 If you have EEG hardware connected then depending on the hardware
 start appropriate acquisition driver for your device:
 
	* TMSi Mobita([mobita]):  `dataAcq/startMobita.bat`  or  `dataAcq/startMobita.sh`  
   * Emotiv Epoc:            `dataAcq/startEmotiv.bat`  or  `dataAcq/startEmotiv.sh`  
   * Biosemi Active 2:       `dataAcq/startBiosemi.bat` or  `dataAcq/startBiosemi.sh`  
	*Interaxon Muse:          `dataAcq/startMuse.bat`    or  `dataAcq/startMuse.sh`  


2. Start the Matlab/Octave based signal processing process by running: `ssep/startSigProcBuffer.bat` or .sh

3. Start the Matlab/Octave based experiment control & stimulus presentation system by running : `ssep/runSSEP.bat` or `runSSEP.sh`

4. Run through each of the experiment phases: 

  * Practice -- practice the task to be used in the BCI.  Green boxes indicate target locations you should attend to

  * Calibration -- get calibration data by attending as instructed for ~90seconds

  * Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.

5. Go into feedback stage where you can choose your target and the system will attempt to predict it based on the brain response
