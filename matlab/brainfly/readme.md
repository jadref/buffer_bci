# Running the experiment

## Informed consent and screening forms

### Informed consent

At the beginning of each experimental session, both the subject and researcher **must** fill in an informed consent form and a screening form (printed copies will be available in the practical room, digital versions are available on Blackboard). Informed consent and screening forms must be handed in to one of the teachers at the end of the experiment.

| Data collected without informed consent from the subject cannot be used for later analysis and publication! |
| --- |

Your subject has the right to be properly informed about the experiment before signing the consent form. Upon request, you should give your subject access to the information brochures which are available in the practical room and answer any questions.

### Screening form

The front side of the screening form must be completed by the subject prior to the experiment. On the back of the screening form the researcher must report at the end of the experiment whether an adverse event or incidental finding occurred.

- **Adverse Event** : any unfavorable and unintended occurrence in a study participant, including any abnormal sign (e.g. abnormal physical result) or symptom which does not necessarily have a causal relationship with the actual participation or experimental manipulation. Examples: headaches, fainting, accidents.
- **Incidental Finding** : an incidental finding (IF) is a finding concerning an individual research participant that has potential health impact and is discovered in the course of conducting research but is beyond the scope of the study. IFs range from those that have clear clinical significance to not directly assignable deviations noticed during or after testing possibly indicating a health concern for the participant.

| If the subject answered &#39;yes&#39; to any of the questions on the front side of the screening form or if an adverse event or incidental finding occurs, ask advice from one of the teachers. |
| --- |

## Starting the experiment

1. Before each experiment, check if you are on the most recent version of the bki323 branch of the buffer\_bci code. The PCs are also being used by other students who may have made local changes to the code or switched branches. To switch to the correct branch, use: git checkout bki323
2. Make sure the experiment code is configured for the correct condition. Each group is assigned one of the two experimental conditions (see Blackboard for a list).
  1. Open the configuration file buffer\_bci/matlab/brainfly/configureGame.m
3. Connect to the Mobita (for a reminder of how to set up the Mobita see buffer\_bci/doc/Mobita\_manual.md)
4. Start the EEG data-acquisition, by running:

buffer\_bci/dataAcq/startJavaBuffer.batand buffer\_bci/dataAcq/startMobita.bat_._

Data is saved to the default output folder: C:\output\test\&lt;YYMMDD&gt;\&lt;HHMM&gt;\raw\_buffer\0001

| Make a note of the name of the directory where the data is saved (so write down the date and timestamp). Multiple groups are using the PCs on the same day, so there will be several directories with the same date stamp. You need to know which of these contains the data of **your** group! |
| --- |

1. Start the signal processing module by running: buffer\_bci/matlab/brainfly/startSigProcBuffer.bat. This should start another session of Matlab/Octave and will ask you to select a cap file. For a 10-electrode configuration suited for imagined movement select cap\_tmsi\_mobita\_im.txt.
2. Start the experiment by running:buffer\_bci/matlab/bki323/runBrainfly.bat

## Capfitting

In the control window, select option **0) EEG** to open the EEG signal viewer. Place electrodes in the cap and check signal quality. A short reminder: aim for a signal amplitude of no more than +/- 20 µV in the time domain and check the signal for big artefacts such as 50 Hz noise or heartbeats. Refer to the instructions of the EEG tutorial session (buffer\_bci/tutorial/EEGBCITutorial/EEGBCI\_worksheet.pdf) for additional information.

## Running the experiment

| Throughout the experiment, keep notes of everything that may be of relevance for later analysis of the data (e.g. if there are electrodes with poor signal quality, if the experiment crashes and has to be restarted, if the subject fails to follow instructions at any point, if distracting events happen during the measurement). At the end of the experiment, you must upload a log file with your notes together with the recorded data. |
| --- |

Run the experiment blocks in the following order.  Instruct your subject what to do at the start of each block (see the &#39;ParticipantInstructions&#39; document).

1. **1)****Practice (optional):** shows an example of what the calibration phase will look like. Use this to show the participant what they will have to do during calibration. It is not necessary to complete the block if the subject already understands the task after a couple of trials. Note: no data is collected during this block.
2. **2)****Calibrate:** identical to the practice, but now training data for the classifier is collected and saved. A &#39;training\_data\_test\_&lt;date&gt;.mat&#39; file will be saved in _buffer\_bci/matlab/brainfly/_ containing the training data. Note: this file will be overwritten if you (or another group) retrain on the same day.
3. **3)****Train Classifier:**trains a classifier based on the training\_data\_test\_&lt;date&gt;.mat file (training data can be obtained via**calibrate**). Output is a trained classifier (saved in _buffer\_bci/matlab/brainfly/_ under &#39;clsfr\_test\_&lt;date&gt;.mat&#39;). The results pop-up in 3 windows showing: Per-class ERSPs, per-class AUCs, and cross-validated classification performance.
4. **4)**Epoch Feedback : in this mode subjects get feedback on the predictions at the end of each trial.  This mode is useful for poorly performing subjects as it reduces the distraction during the trials caused by the moving cursor.
5. **5)****Continuous feedback:** this is the part of the experiment where subjects do the neurofeedback training, either with or without time pressure depending on the condition to which your group was allocated. Run this block 4 times.
6. **6)****Brainfly Game ****:** This is the actual &#39;space-invaders&#39; style game the subject should play.  The subjects movements move the &#39;cannon&#39; at the bottom of the screen in a similar way as used in continuous feedback.  Accuracy is rewarded by getting more points for hitting the targets further up the screen.

1. a) **Artifacts:** a block in which the subject is asked to generate specific artifacts, such as eye blinks and jaw clenching.

## Saving the data

In research projects like this, personal data is collected from the participants. Dutch law dictates that researchers must adhere to a number of guidelines in order to protect the privacy of the individuals involved.

| According to data management guidelines, the data will be deleted from the computers in the classroom after each practical session. Data not uploaded to SurfDrive will be lost! |
| --- |

To backup your data, follow these steps:

1. Copy the raw-data to your encrypted disk:
  1. The raw\_buffer folder(s) containing the EEG data. The raw\_buffer folders are

located in C:\output\test\&lt;YYMMDD&gt;\&lt;HHMM&gt;\raw\_buffer\0001

A new raw\_buffer folder is created each time the buffer is started. As multiple groups are using the PCs on the same day, there will be multiple directories within the folder with the correct date stamp. Take care to upload only the raw\_buffer folder that belongs to your experiment (i.e. the one with the correct time stamp). If you had to restart the buffer during the experiment due to a crash, your data will be in multiple raw\_buffer folders.

Upload them all.

1.
  1. A log file (.txt) with notes made during the experiment (see Running the experiment).
  2. A digitized version of any questionnaires you may have used.
2. Make sure that the filenames or directories contain the subject, session recorded and the condition used, for example by using a directory name: Condition/SXXXX/YYYYMMDD/hhmm. (XXX is the numeric unique subject identifier, where YYYY is the year, MM is the numeric month, DD is the numeric day, hh is the time in 24hr format, mm is the minutes.)

| Never include any personal information (such as subject name or student number) in the data files or filenames! |
| --- |

## Finalizing the experiment

1. Close all open windows
2. Remove used sponges from the cap and throw them away
3. Check if informed consent and screening forms are complete

| At the end of the experiment, report to one of the teachers. They will check if the consent and screening forms are complete. |
| --- |

