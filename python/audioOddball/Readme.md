Introduction
------------

This experiment used a auditory odd-ball task to investagate the difference in brain response between a common 'standard' stimuli and a rare 'oddball' stimuli.


Requirements
------------

Matlab or Octave (for signal analysis)
Python with Pygame and Pyaudio (for stimulus display)


QuickStart
----------

To run this example:

1) Start the 'buffer' based data-server by running:
	    dataAcq/startJavaBuffer.sh or dataAcq/startJavaBuffer.bat

2) Start the data Acquisation system.

	Depending on the hardware you have (or not) start the appropriate data acquisition system driver:

      * No-EEG hardware:  start the simulated EEG driver: dataAcq/startSignalProxy.sh or .bat

      * TMSi Mobita:      start the hardware driver by running: dataAcq/startMobita.sh or .bat

      * Emotiv Epoc:      start the hardware driver by running: dataAcq/startEmotiv.sh or .bat

      * Biosemi Active 2: start the hardware driver by running: dataAcq/startBiosemi.sh or .bat

3) Start the Matlab based signal processing proces by running: startSigProcBuffer.bat or .sh

    This will ask you to choose a cap-file which gives the system the electrode locations to use
    for this experiment.  For this type of data a good cap-file to use is: `cap_midline_15ch.txt`

4) Start the actual experiment by running: runOddball_portaudio.bat or .sh

5) Run the experiment.  This experiment has the following phases selected from the main menu:

    EEG      -- real-time EEG viewer to check electrode connection quality.  This shows a topographic arrangement of the electrodes with the current (filtered) signal in each electrode.  If you have a well connected set of electrodes you should be able to see eye-blinks in the most frontal electrodes, and muscle artifacts (such as jaw clenching) in all electrodes.

    Oddball training -- This will make two windows

       * Experiment Window: You will hear a series of high and low 'beeps'.  The high beeps are 'oddball's in that they occur rarely.  Thus, the high-beeps generate a different brain response than the common low-beeps. To give you a cue for the 'target' high-beeps they will be played 3 times in a row at the start of the sequence.

        * ERsP Visualization window: this shows the live updated average response to the different experimental conditions.  To prevent distraction the subject should *not* see this. 

    Oddball testing -- This is the same at the oddball training paradigm *except* now the experimenter can change the extent of the distinction between the 'oddball' high-beep and the standard low-beep by using the number keys 0-9, where 9 is most different and 0 is least different.   The Experiment window will show the frequency of the current target sound.

    line/beep testing -- This is the same as the Oddball testing *except* the visualization window will make a different line for each different oddball type used
