==Simple off-line BCI Data analysis routine==

This directory contains some simple code for analysing off-line data
generated in a typical BCI experiment.  To tailor it to your
particular experiment you need to perform the following steps:

1) Find the saved data!

When you ran your experiment, the software should have asked you where to save the data.  You should take a note of this location.   If it did not, or you forgot then you can generally find the saved data under:

MacOS/Linux: ~/output/test/_YYMMDD_/_HHMM_/raw_buffer/0001

Windows: C:\output\raw_buffer\test\_YYMMDD_\_HHMM_\raw_buffer\0001

where _YYMMDD_ is the date in year/month/day format, _HHMM_ is start time hour and minutes.

You can tell you have the right directory if you see files named: 'events','samples','timing','header'. The largest of these should be 'samples' which should be a few Mb in size.

2) Identify the event types which indicate the start of your different trials. 

When you developed your experiment you should have defined and sent some event's which identify the segements of data where the user is performing the mental task which you would like to distinguish, for example: left-hand movements vs right-hand movements, or 'flashed' target letter vs 'flashed' non-target letter.  These event's should have a unique type, e.g. 'hand-movement, or 'stimulus.flash', with the value of the event, e.g. 'left' vs 'right', or 'target' vs 'non-target', indicating the mental task. 

These event types and values will be used to identify the data to be classified.  

3) Run the analysis.

In the folder 'buffer_bci/offline'  you will find a Matlab script called : 'example_offline_analysis'.  This example file contains all the commands you need to perform a simple data analysis.  To tailor it to your experiment you need to do the following:

  a) Line 27:  Modify the save data source directory to point to where your data was saved.

  b) Line 27: Modify the 'startSet' value to be the event type which indicates the start of the data to be classified.  That is, you change the text 'stimulus.target' to be the event type you used in your experiment, e.g. 'stimulus.flash'.

  c) Line 27: Modify the length of data which is used for the analysis to be the trial length used in the experiment.  That is, change the value after 'trlen_ms' from 3000 to what you used in your experiment.

  d) Line 30: Change the type of analysis to be performed based on the type of brain signature expected.   This is one of:

    buffer_train_erp_clsfr = if the brain response expected should be an evoked response (Event Related Potential), i.e. a time-locked change.
    buffer_train_ersp_clsfr = if the brain response is expected to be an induced response (Event related spectral peterbutation), i.e. a change in power at a particular frequency band.

 e) Line 30: Change the frequency band used in the pre-processing for the data analysis to reflect the frequency range you expect your brain response to be in.  In general this should be:

    ERP = [.5 20] to pass only the low freqencies.
    Movement related signals: [10 24] to allow both the mu (12Hz) and beta (20hz) responses to remain

4) Interpert the results.

If you have set everything correctly this file will run and first slice the data (it should find the same number of events as 'trials' you had in your experiment).  Then it will pre-process the data, produce some plots and finally try to classify the different conditions.  

This analysis should generate two summary figures:

a) ERP / ERsP data.  
This should be a head plot showing the averaged response for each of the different training conditions (as determined by the unique values of the trial events).  For ERP training this will be the signal amplitude over time after the trigger event.   For the ERsP training this will be the signal amplitude at different frequencies.

b) AUC data.
This plot shows where the signals for the different training conditions are most different and some indication of the magnitude of this difference.  Again is shows a head plot.  In this case the color of the plot shows the significance of the difference between conditions, with white=no-significant difference, and the strength of the color indicating the difference strength.  The magnitude of this difference is a rough indication of the classification performancy you could expect.

c) Classifier performance.
The final window will be a summary of the classifier performance on this data.  This is simply a number which is the fraction of trials the classifier would get correct.  
N.B. this is a so-called, balanced classification rate, so .5=chance and 1. is perfect performance.