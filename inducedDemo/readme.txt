QuickStart
----------

To run the imaginedMovement demo:
1) Start a buffer by running: dataAcq/startBuffer.bat or buffer/startBuffer.sh
(optional) 1.1) Start a simulated data source (if you don't have an measurement system connected) by running: dataAcq/startSignalProxy.bat or .sh
2) Start the Matlab based signal processing proces by running: imaginedMovement/startSigProcBuffer.bat or .sh
3) Start the Matlab based experiment control & stimulus presentation system by running : imaginedMovement/runIM.bat or runGame.sh
4) Type in the subject name to the experiment control window, and then run through each of the experiment phases: 
   CapFitting -- check electrode connection quality of the cap.  This will show a topographic plot of the head with the electrodes colored from red=bad to green=good.  Add additional gel or rub the electrodes until all are green.
   EEG      -- real-time EEG viewer to check electrode connection quality.  This shows a topographic arrangement of the electrodes with the current (filtered) signal in each electrode.  If you have a well connected set of electrodes you should be able to see eye-blinks in the most frontal electrodes, and muscle artifacts (such as jaw clenching) in all electrodes.
   Practice -- practice the task to be used in the BCI. A red central dot indicated 'get-ready', then the central dot and one of the outer dots will turn green indicating perform this task.  
     The default is 3 directions, with the mapping:
             left  -> left-hand movement
             right -> right-hand movement
             top   -> *both* feed movement, or *both* hands movement
   Calibration -- get calibration data by performing the task as instructed for approx. 4 minutes
   Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERsPs, per-class AUCs, and cross-validated classification performance.  Close the classification performance window to continue to the next stage.
5) Test -- test the trained classifier by moving the cursor round the screen as you want!



File List
---------

General Setup/GUI Files:

configureIM.m -- basic configuration variables for the speller, such as the set of options to display
runIM.m  runIM.sh runIM.bat -- Controller functions to run the speller stimulus and experiment control
controller.m controller.fig -- files to generate the GUI and function call-backs for the experiment control
startSigProcBuffer.m startSigProcBuffer.bat -- control functions to run the various signal-processing functions as requested by the runIM experiment controller.

Experiment Phase Files:

imCalibrateStimulus.m  -- generate the calibration phase stimulus, i.e. show fixation, cue'd targets etc.
imOnlineFeedbackStimulus.m   -- generate the feedback phase stimulus, i.e. show the set of targets, gather the classifier predictions and move the cursor as indicated
imOnlineFeedbackSignals.m    -- signal analyis for the feedback phase, i.e. get data every ~.25s, apply the trained classifier, and send prediction events.
