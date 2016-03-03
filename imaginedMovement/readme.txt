QuickStart
----------

To run the imaginedMovement demo:
1) Start a buffer by running: dataAcq/startJavaBuffer.bat or buffer/startJavaBuffer.sh
2) Start a data-acquistation system.
 If you have *no* EEG hardware, but just want to test:

  * start a *simulated* data source by running: `dataAcq/startJavaSignalProxy.bat` or .sh

 If you have EEG hardware connected then depending on the hardware
 start appropriate acquisition driver for your device:
 
	* TMSi Mobita([mobita]):  `dataAcq/startMobita.bat`  or  `dataAcq/startMobita.sh`  
   * Emotiv Epoc:            `dataAcq/startEmotiv.bat`  or  `dataAcq/startEmotiv.sh`  
   * Biosemi Active 2:       `dataAcq/startBiosemi.bat` or  `dataAcq/startBiosemi.sh`  
	*Interaxon Muse:          `dataAcq/startMuse.bat`    or  `dataAcq/startMuse.sh`  

3) Start the Matlab based signal processing proces by running: `imaginedMovement/startSigProcBuffer.bat` or `.sh`

4) Start the Matlab based experiment control & stimulus presentation system by running : `imaginedMovement/runIM.bat` or `runIM.sh`

5) Type in the subject name to the experiment control window, and then run through each of the experiment phases:

  * EEG      -- real-time EEG viewer to check electrode connection quality.  This shows a topographic arrangement of the electrodes with the current (filtered) signal in each electrode.  If you have a well connected set of electrodes you should be able to see eye-blinks in the most frontal electrodes, and muscle artifacts (such as jaw clenching) in all electrodes.

  * Practice -- practice the task to be used in the BCI. A red central dot indicated 'get-ready', then the central dot and one of the outer dots will turn green indicating perform this task.  
     The default is 3 directions, with the mapping:
             left  -> left-hand movement
             right -> right-hand movement
             top   -> *both* feed movement, or *both* hands movement

   * Calibration -- get calibration data by performing the task as instructed for approx. 4 minutes

   * Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERsPs, per-class AUCs, and cross-validated classification performance.  Close the classification performance window to continue to the next stage.


6) Test -- test the trained classifier by moving the cursor round the screen as you want!

You have two main test mode, per-trial (epoch) and continuous (cont)

epochfeedback -- feedback comes at the end of the trial and shows the predicted target

contfeedback  -- feedback comes every .25s and moves the cursor in the predicted direction

centerout     -- feedback is continuous.  The task is to move the cursor to the edge indicated in green.


File List
---------

General Setup/GUI Files:

configureIM.m -- basic configuration variables for the speller, such as the set of options to display
runIM.m  runIM.sh runIM.bat -- Controller functions to run the speller stimulus and experiment control
controller.m controller.fig -- files to generate the GUI and function call-backs for the experiment control
startSigProcBuffer.m startSigProcBuffer.bat -- control functions to run the various signal-processing functions as requested by the runIM experiment controller.

Experiment Phase Files:

imCalibrateStimulus.m  -- generate the calibration phase stimulus, i.e. show fixation, cue'd targets etc.
imEpochFeedbackStimulus.m   -- generate the feedback phase stimulus, i.e. show the set of targets, gather the classifier predictions and then show the predicted target at the end of the trial

imEpochFeedbackSignals.m    -- signal analyis for the feedback phase, i.e. get the whole epochs data (3s) in one go and generate a prediction for that period

imContFeedbackStimulus.m   -- generate the feedback phase stimulus, i.e. show the set of targets, gather the classifier predictions and then show the predicted target at the end of the trial move the cursor as indicated

imContFeedbackSignals.m    -- signal analyis for the feedback phase, i.e. get data every ~.25s, apply the trained classifier, and send prediction events.
