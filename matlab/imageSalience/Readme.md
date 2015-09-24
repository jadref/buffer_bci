Introduction
------------

This experiment uses a Rapid Serial Visual Presentation (RSVP)
paradigm to identify which pieces of a given target image the user (or
their brain) react to most strongly.  Thus, it shows what parts of an
image the user finds most important (or salient).

Requirements
------------

Matlab or Octave
Python (for audience feedback display) + pygame


QuickStart
----------

To run this example:

1) Start the 'buffer' based data-server by running:
	    `dataAcq/startJavaBuffer.sh` or `dataAcq/startJavaBuffer.bat`

2) Start the data Acquisation system.

	Depending on the hardware you have (or not) start the appropriate data acquisition system driver,

      * No-EEG hardware:  start the simulated EEG driver: dataAcq/startSignalProxy.sh or .bat

      * TMSi Mobita:      start the hardware driver by running: dataAcq/startMobita.sh or .bat

      * Emotiv Epoc:      start the hardware driver by running: dataAcq/startEmotiv.sh or .bat

      * Biosemi Active 2: start the hardware driver by running: dataAcq/startBiosemi.sh or .bat

3) Start the Matlab based signal processing proces by running: startSigProcBuffer.bat or .sh

    This will ask you to choose a cap-file which gives the system the electrode locations to use
    for this experiment.  For this type of data a good cap-file to use is: `cap_tmsi_mobita_black.txt`

4) Start the actual experiment by running: runImageSalience.bat or .sh

5) Start the audience feedback display by running: startFeedback_fragments.bat or .sh

    This will open a feedback window.  To prevent distraction the subject should not see this.  Also during training/calibration this will not update much (except to show the current target image).  During feedback this will show the summary of the classifiers predicted image fragement salience.

5) Start the second audience feedback display by running: startFeedback_target..bat or .sh

    This will open a second feedback window.  To prevent distraction the subject should not see
    this. This wil not change except during the feedback phase of the experiment.

    During feedback this will show the top 9 images as given by the classifier as 'targetness'.
    That is the top-left image is the one the classifier things is the users target, with the other
    images ranked by similarity in this way.

6) Run the experiment.  This experiment has the following phases selected from the main menu:

    EEG      -- real-time EEG viewer to check electrode connection quality.  This shows a topographic arrangement of the electrodes with the current (filtered) signal in each electrode.  If you have a well connected set of electrodes you should be able to see eye-blinks in the most frontal electrodes, and muscle artifacts (such as jaw clenching) in all electrodes.

    Practice -- practice the task to be used in the BCI.  This will do one run through the task showing the stimuli so you can get a feel for what you should do.

    Calibration -- this does a real run through the data.  Two different windows will be show.

       * Experiment window: this shows the stimuli for the subject, i.e. first the target image then the image stream

       * ERsP Visualization window: this shows the live updated average response to the different experimental conditions.  To prevent distraction the subject should *not* see this. 

	Classifier Training -- train a classifier using the calibration data.  3 windows will pop-up showing: Per-class ERPs, per-class AUCs, and cross-validated classification performance.

    Testing/feedback -- this uses the trained classifier to assess the strength of the brain response to the testing image set to update the feedback display.
