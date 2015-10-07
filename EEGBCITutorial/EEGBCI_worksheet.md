

#Worksheet: Introduction to EEG BCI tutorial

#Overview of the buffer\_bci framework

Buffer BCI is a platform independent and language agnostic framework for building Brain Computer Interface experiements.  It is based on a \*network transparent client-server architecture\* with multiple clients getting and putting data to a central data and events server.  The server is based on the [fieldtrip buffer]([http://fieldtrip.fcdonders.nl/development/realtime](http://fieldtrip.fcdonders.nl/development/realtime)) specification for data access and storage.

The server is available for Mac, Linux, Windows and Android and client language bindings are provided the following programming languages Matlab, Octave, Java, Python, C\# and c.  For Matlab and Octave additional signal-analysis, classification and example demonstration BCIs are provided1.  For Python and Java more limited example BCIs are provided.

Note buffer\_bci is a **client-server architecture**.  Thus to using this system requires starting **at least** three interacting processes:

1) a **server** running (the 'buffer') and two clients:

2) a **data-acquisation client** which interfaces with the hardware to send data to the server,

3) an **application client** which does something with the received data, like showing it on the screen.

Whilst this client-server architecture increases the apparent system complexity it has the advantage that different clients may be written in different programming languages and even run on different computers.

#Ethical issues & participant handling advice

An EEG experiment with a electrode cap on your head and electrodes on your face/body can be quit intimidating, especially if the participant is new and has never done an EEG experiment before. Therefore, there are also some (logical) rules we would like you to follow during the

actual experiment:

- The participant is your **guest,** to be pleasant to them at all times.
- **The participant can stop participation at any moment without any further consequences.** (Be sure to clearly explain this to your participants).
- The participant should sign an informed consent form to show they understand the purpose of what you are doing and what the gathered data will be used for.  Furthermore they must to be informed about:
  - where they can go with questions about the research (you)
  - where they can go with complaints about participation and how these will be handled (the lab manager)
  - that they can stop participation at any moment without any consequences, for any reason. If they are promised payment, they will get paid for the time spent.
- Explain what you are doing (especially during setting up the cap). For example, if you need to apply EOG electrodes show them on your on face where you will put them.
- Never let the participant wait without telling them what is happening. So, if something is wrong with the hard/software explain it to the subject and give an estimate of how long it will take.
- Always try to minimize this waiting time.
- Anything that you can do while the experiment is running should be done then, in order to minimize the length of the experiment.
- If you want to play music during the cap setting, make sure it is not too loud. And also think about what kind of music you play: either ask your participant what he would like or play something 'easy listening'.
- Always make sure that the participant feels comfortable.
- Stay professional! For example, do not talk about things that you always do wrong, make sure you instill confidence.
- In keeping with the ethical considerations above, keep checking that the participant is ok, make sure you have sufficiently clarified that they can stop at any time and that you can always see/hear them, and that they are always free to ask questions etc.
- Remember that they are giving you their time (even when they're paid) and it's your responsibility that the experiment goes well.

**Happy participant = better chance of good data!**

#Practical: Introduction to EEG
##Introduction to EEG

EEG recording system consists of:

- **EEG electrodes** , made of sver/silver-cloride (Ag/AgCl) alloy which measure voltage at particular location on the scalp
- **Cap** : which holds the electrodes in place (doh!) at specific locations.  These locations are standardized to a measurement system called the 10-20 system.
- **Conductive Gel/Water**: Bridges the gap to complete the electrical circuit between electrode and the scalp
- **Amplifier** : Measures the voltage at each electrode and converts to digital values

###The International 10-20 system

Standardized system for placing electrodes on the scalp.  As shown in the figures below it is based on measuring angles from 4 reference points on the head, namely left-ear, right-ear, nasion (bridge of the noise) and inion (lump at the back of the skull).  Cap is positioned so that electrode **Cz** which is exactly centered between the left/right ears and nasion/inion.  Electrode name consists of 2 parts;

- 1 or more letters which denote the lobe of the brain the electrode is over, e.g. F=frontal, O=occipital, C=central, T=temporal, P=pariatial etc.
- 1 or more numbers or the letter z, which denote the left/right position of the electrode. z=zero=centered on the head.  Odd numbers are over the left hemisphere counting up from the mid-line.  Even numbers are over the right hemisphere counting up from the mid-line.


**Image 1 here **

**Image 2 here**

 
##Fitting the EEG cap

For this practical we will be using the buffer\_bci system, which is an open-source platform and language independent framework for rapid prototyping of BCI experiments. (You can download from <[www.github.com/jadref/buffer\_bci](http://www.github.com/jadref/buffer_bci)>)

1. Start the BCI software, which is located on the Desktop under buffer\_bci
  1. Start the data storage buffer run: `dataAcq/startJavaBuffer.bat` or `dataAcq/startJavaBuffer.sh` where dataAcq is a sub-directory of the main buffer\_bci directory.

 You should see a text console open, and may be asked to specify a file save location.

 Note: By default raw data is saved to: `~/output/test/YYMMDD/HHMM/raw_buffer/0001`  for MacOS/Linux or
`C:\output\test\YYMMDD\HHMM\raw_buffer\0001`  for windows, where `YYMMDD` is the date in year/month/day format, `HHMM` is start time hour and minutes

 Note: by default this server saves all data to disk.  To run the server without saving to disk use the `dataAcq/startJavaNoSaveBuffer.bat`/`sh` file.

2. Connect your measurement device and start the data-acquisition system driver which will get data from your (real, or simulated) brain measurement device.  How you do this depends on exactly what EEG acquisition hardware you wish to use:
  
  - **No-EEG hardware** : start a **simulated** data source by running: `dataAcq/startSignalProxy.bat` or .sh

  - **TMSi Mobita** : run `dataAcq/startMobita.bat`  or  .sh  
 (N.B. See [here](https://github.com/jadref/buffer_bci/blob/master/doc/Mobita_manual.md) for more instructions on how to connect to and use the mobita)

  - **Biosemi Active 2** : run `dataAcq/startBiosemi.bat` or  .sh

  - **Interaxon Muse** : run `dataAcq/startMuse.bat`    or  .sh

  - **Emotiv Epoc** : run `dataAcq/startEmotiv.bat`  or  .sh

If this command is successful you should see a new console open with some some text in to indicate that it has started sending data, e.g. a continuously updating summary of the run-time, number of samples sent, and data-rate.  The hardware itself will also generally give some visual indication that it is sending data, with e.g. flashing green and blue lights for the Mobita, or green data light for the Biosemi.

**Image3 here**


3. Start the stimulus generation software by running: `EEGBCITutorial\runEEGBCITutorial.bat` or  `EEGBCITutorial\runEEGBCITutorial.sh`

You should see Matlab start up, and (eventually) a window like this titled " **BCI Controller**".

4. Finally, start the signal analysis software, by running: `EEGBCITutorial/startSigProcBuffer.bat` or `EEGBCITutorial/startSigProcBuffer.sh`

 You should see Matlab startup.  You will then be asked to pick a **cap-file** for this experiment which says for the connected eeg hardware where each electrode is positioned in 10-20 notation.  For the EEG systems listed above the appropriate cap-files are:
  - **No-EEG hardware** : `1010.txt`    
  - **TMSi Mobita** :        `cap_tmsi_mobita_16ch.txt` for 32 electrode systems **or**  `cap_tmsi_mobita_10ch.txt` for 10 electrode systems
  - **Biosemi Active 2** :        `1010.txt`
  - **Interaxon Muse** :        `muse.txt`
  - **Emotiv Epoc** :        `1010.txt`

5. Now that everything is running. Click the button marked EEG in the "**BCI Controller**" window to see the data which is coming out of the amplifier.  You should see 2 windows open, one showing the signals (called "**Sig Viewer**"), and one showing signal-processing options (called "**Sig Proc Options**").

 This sig-viewer can show **time** -domain, **freq** uency-domain, **spect** rogram (time-frequency-representation) and **50Hz** noise power representations of the raw data, accessed by selecting different options in the list box at the top right of the window.

 **Image 4 here**
**Image 5 here**


6. Switch to the 50Hz power representation of the signal.  In this representation the 50Hz power is color coded to indicate the quality of the connection for each electrode.  This should ideally be **Green** for all electrodes.

7. Put the cap on the subjects head (Note: the front has the electrodes close to the edge of the cap, and the back has about a 2cm gap).  The cap should be a snug fit, but not too tight, if it seems to big/small then ask the assistants to get you an alternative cap.  Be sure it is centered correctly left-to-right and front-to-back such that it is symmetric on the subjects head.  If using the Mobita be sure to put water on the wrist strap/reference electrode and put this round the subjects wrist.

8. On the **Sig-Viewer** screen each electrode position has a name consisting of a number and the electrode name in 10-20 notation.  Each electrode also has a label with a number on each wire.  For the systems with loose electrodes (Mobita, Biosemi) you now need to put each electrode into the correct hole on the cap by matching the electrode numbers to it's position as shown in the **Sig-Viewer** window.  How you do this depends on the system used:

1. **Biosemi** : This is a 'gel-based' system.  Thus you must use the provided syringe to first put a drop of conductive gel in the appropriate electrode hole before pressing the electrode into position.  Be sure to connect the electrode ribbon-cable to the amplifier in the first (A) row.

  Also be sure to connect the additional 'reference' electrodes (called CMS/DRL), and connect them to the amplifier with the dedicated CMS/DRL cable and connector.

2. **Mobita :** This is a 'water-based' system.  Be sure there is a sponge in each electrode and that it is **wet** – the subject should feel a little bit of dampness when the electrode is placed into the cap.

  Note: As we will only be using 16 (or 10) channels in the experiment, you will only use alternative **rows** of the cap, i.e. front-most row, then 2 rows-back, then 2-further back, etc..

9. Connection quality check.  Now you have all electrodes in the cap let it rest for 30second or so, this gives time for the gel/water to reach the scalp and the initial connection artifacts to die-down.  The **Sig-Viewer** will now show the quality of the connection for each electrode.  You should ensure that all electrodes have a good connection (are **Yellow** / **Green** in the display).  To improve the contact for an electrode either:

   1. Press it firmly (but not painfully) into the head to improve distribution of gel/water on the scalp.
   2. Remove the electrode, add more water/gel (using the syringe), and replace.
   3. 'Wiggle' the electrode around on the head
   4. Remove the electrode and then use the syringe to try to move the hair out of the way before adding more water/gel and replacing the electrode.

 Note: of almost all electrodes are bad then be sure to check the 'reference' has a good connection and re-fit this first, i.e. wet wrist band for Mobita, refit cms/drl for Biosemi.

10. Repeat step 9 until All/most of the electrodes are ' **Yellow**** / ****Green**'.

##Basic Properties of the Non-Artifact EEG

**Image 6 here**

**Image 7 here**

Spectrally: 1/f spectrum, mu/alpha peak                        High spatial correlation over electrodes

###Practical: Basic properties of EEG

Get your subject to minimize artifacts by relaxing, trying to minimize movements, (i.e. no talking, moving and try to keep eye's fixed at one location)

1. Start the **Sig-Viewer** (if not already running), and switch to the time-domain view of the signals.
 - What do you see?
 - What is the average magnitude of the EEG fluctuations?
 - When comparing near-by electrodes do the signals look similar?
 - What about when comparing distant electrodes (e.g. frontal to occiptal?)

2. Look at the EEG in frequency domain:
 - What do you see?
 - Does the power decrease with frequency?
 - Are there any electrodes where this is not the case?  If so what is the location, and a what frequency does the power increase? (Hint: alpha peak?)

###External Artifact Sources in EEG

_Pysiological artifact: a)eye-move b)blink c)muscle_

_Sensor artifact: a)bad-channel b)slow-drift_

**Image 8 here**

**Image 9 here**


####Practical: External artifacts

- Bring up the **Sig Proc Options** window and turn off all pre-processing by; Setting Pre-proc to None, Spatial-filter to None and spectral filter to [low-cut-off=0 high-cut-off=inf]
- Switch the **Sig-Viewer** to time-domain and for each of the following artifacts; take a note of it's approximate size (in muV), location (frontal, temporal, central, occiptial) and frequency (speed of fluctuations) as either slow <5Hz (times/second) or fast>15Hz.

| **Artifact Type** | **Size (muV)**|**Location**|**Freq**|**Other Observations?** |
| --- | --- | --- | --- | --- |
| Bad-channel (Hint: try tapping the channel, or removing the gel/sponge from one channel) |   |   |   |   |
| 50Hz / Line noise |   |   |   |   |
| Slow electrode drifts |   |   |   |   |
| Muscle – jaw-clenching |   |   |   |   |
| Eye-movement – Blinking |   |   |   |   |
| Eye-movement – left/right and up/down |   |   |   |   |
| Movement effects – head wiggling |   |   |   |   |

###Internal Artifact Sources in EEG

Internal artifacts tend to be mostly **induced** responses.

####Practical: Internal artifact sources

- Reset the **Sig Proc Options** to their default values, i.e. Pre-proc=detrend, Spatial Filter=CAR, Spectral filter, [low-cut-off=.1,  high-cut-off=47]
- Switch the **Sig Viewer** to frequency domain.
- Ask you user to switch between the following 2 internal states in turn.  In each state observer the EEG and try to identify which changes are associated with the change in the mental state.

| **Artifact Type** | **Power (muV)** | **Location** | **Freq** | **Other Observations?** |
| --- | --- | --- | --- | --- |
| Eyes Open vs Eyes Closed |   |   |   |   |


###Referencing in EEG

EEG measures voltage differences relative to reference electrode(s): x\_meas = x\_raw – x\_ref.  Changing reference changes the apparent location and shape of the measured signal.

- Importantly, anything common to x\_ref and x\_raw is removed.  This is good for removing external noise sources, e.g. 50Hz

- Also, anything only in x\_ref (such as noise, or brain signal) is spread over all other electrodes

An ideal  reference – only detects noise common to all other electrodes and no brain-related signals.  Commonly used references are: Linked mastoid, Common-average (CAR), Surface Lapacial.

####Practical: Effect of Referencing

1. Start the **Sig-Viewer** (if not already running), and switch to the time-domain signal view.
2. Bring up the **Sig Proc Options** , and set the spectral filter to 0-100Hz (so you can see the 50Hz noise).
3. Switch between the various reference types and note the changes in the signal properties, in terms of the strength of the 50Hz power noise, Strength of Movement/slow-drift artifacts, and the spatial correlation – which means how similar the signal looks in electrodes positioned near to each other.

| Spatial Filter | Strength 50Hz (uV) | Movement/slow-drifts | Spatial Correlation | Other Observations |
| --- | --- | --- | --- | --- |
| None |   |   |   |   |
| CAR |   |   |   |   |
| SLAP |   |   |   |   |

##Practical: Stimulus (Evoked) Responses

Generally, brain signals are very small relative to the artifacts (both external and internal).  To remove this noise and make the signal visible we need to process the signal.  For Evoked responses, which are time-locked to a know stimulus event, a significant reduction in noise strength can be achieved by simply averaging together responses from multiple events – the time-locked component remains and the non-time locked noise reduced by roughly 1/sqrt(N) where N is the number of trials in the average.  Thus, averaging together 25 events should reduce the noise impact by a factor of 5, or 100 to reduce by factor of 10.

###Stimulus Response Effects

Whenever subject experiences stimulus brain has a prototypical response.  The shape of this response depends on numerous factors, such as Modality (visual, auditory), Stimulus type (transient, steady-state), Subject expectation (p300) etc.

####Practical: Visual/Auditory stimulus responses

**Image10 here**
 
_Typical responses to visual stimuli                                Typical response to_ **oddball** _stimuli @ Cz_

 
1. Close the **Sig Viewer**.  The main **BCI Controller** window should return, if not switch to it.

2. We will be using MATLAB for 'high speed' graphics it is best to switch your display to a low resolution e.g. 800x600, for this part of the tutorial.

 Alternatively, if you have 2 displays attached to your computer, you can use the PsychToolBox (PTB) based version of the experiment which can generate 'high speed' graphics at all resolutions.
 
 Note:  if this fails with an error message about 'Cannot find the PTB path!' ask an assistant for help.

3. Start the Event related potential visualization tool, by clicking the " **ERP Visualization**" button.  (Or 'ERP Viz PTB' if you have two displays attached3.)  This should open 2 windows as shown below, one showing instructions for different stimulus types. titled " **Evoked/Induced Response Stimulus**", and one showing averaged brain responses, titled "**ER(s)P Viewer**:".


 **Image 11 here**
 
 **Image12 here**
 
 **image 13 here**

4. Maximise both windows, and switch (alt-tab) to the   **'Evoked/Induced Response Stimulus'** window to the foreground.  The instructions tell you which key to press to generate the indicated type of stimulus to evoke a brain response.

5. For each of the stimulus types, instruct your subject to relax and look at the screen.  When a stimulus is selected first there will be a single red-fixation point for 1-second, this allows the subject to fixate their eyes and get read for the stimulus (relax, stop moving etc.).  This dot will turn 'green' or disappear when the actual stimuli begin.  Press the key for the stimulus you would like.

6. After you have gathered a few stimulus responses (in most cases you will need to repeat the stimulus multiple times (3-4) to get enough examples in the average to allow you to see any consistent evoked response.).  Switch to the "**ER(s)P Viewer**" window using e.g. <alt-tab> or the task-bar.  This will show for each type of stimulus event the averaged response along with the number of stimulus events used to compute the average in brackets.

 N.B. for the **Oddball** tasks, you should particularly focus on the differences between the target and non-target responses.

 Note: you can press the "Reset" button in the "**ER(s)P Viewer**" window to clear information from previous stimulus types and reduce the image clutter.  Further you can 'zoom' in on certain electrodes by dragging a 'rubber-band' box around them, double-click to return to the full view.

7. For each of the following stimuli examine the responses and note the magnitude, location and approx number of trials required to make the response visible.

| Stimulus | size | location | #trials | Other Observations |
| --- | --- | --- | --- | --- |
| **Visual** - events are flashes in blank screen |   |   |   |   |
| **Oddball** - events are 'rare' green target flashes which subject should count, and frequent standard flashes (grey) to be ignored. |    |     |   |   |
| **Auditory oddball –** events are 'rare' 'high' tones which subject should count, and frequent standard 'low' tones to be ignored. |   |   |   |   |

###Practical: Steady State Visual Response

Also get response to continuous stimulation at a fixed frequency, where response should be an increase in power at the stimulus frequency (or one of it's harmonics, i.e. double or triple the stimulus frequency) relative to the non-stimulated (resting) state in the appropriate sensory region.

| Stimulus | size | location | #trials | Other Observations |
| --- | --- | --- | --- | --- |
| **Visual SSEP Visual** - events are flashes at given frequency on blank screen.(N.B. Easier to see in **frequency** representation of the signal.  Compare to response to no-stimulus (no-cue task).) |   |   |   |   |

##Attentional Modulation of Responses

The basic low-level stimulus response can be modulated by selective attention.  Further, additional components can be evoked by selective response to different stimuli, such as only counting the target stimuli.  This selection can be to 1-of-N parallel stimuli, or to particular stimuli in a sequence selected based on target stimulus properties.  Targets can be identified by any stimulus property, such as location, frequency (high/low), color, shape, etc..  This ability to choose which stimuli to respond is the fundamental source of control for active evoked response BCIs.

###Practical: 2-stimulus visual selective attention

We have 2 selective attention tasks, the Visual P300, and the Visual flicker.  In both tasks the user will first see a **GREEN** target square.  This indicates which side (left or right) they should attend only to this side.  Two average ERPs will then be computed, one for the response to stimuli on the attended side, and one for responses to stimuli on the non-attended side.

| Stimulus | size | location | #trials |  Observations |
| --- | --- | --- | --- | --- |
| **Visual P300 **- As with the visual oddball, the subject should count the 'rare'** BLUE**target events, and ignore the frequent GREY standards. Compare target and non-target (standard) responses. |   |   |   |   |
| **Visual flicker** – subject should simply attend to the target side.(N.B. Easier to see in **frequency** representation of the signal.  Compare response between left (15Hz)-targets and right (20Hz)-targets.) |   |   |   |   |

Note: **Artifacts in (Visual) Evoked BCI**.  Attending to different stimuli may cause the user to change in other ways, e.g. Eye-pointing, head-pointing. These non-brain changes can result in bigger effects than the actual attentional modulation. c.f. Covert vs. Overt attention paper

###Practical: Induced (Endogenus) Responses

As well as responses evoked by external stimulus, signal changes can be caused by performing specific internal mental-tasks.  These responses are not time-locked, but visible as changes in magnitude of specific oscillation at particular frequencies (visible in the frequency representation of the data).  As they are internally generated, under active control are good candidate for on-line BCI applications.

####Practical: Induced Responses

1. Switch to the frequency-view of the signals.  (Note: in frequency view the average is computed in **frequency** domain, thus induced (non-time-locked) effects will be visible – even if not visible in the time-domain (time-average) view.)

2. Press the appropriate buttons to cue the subject for what task they should do (remember tell them in advance what left/none/right mean. ;-))  You should always compare at least 2 different tasks.

3. Exam the properties of the signals to see the strength and how many trials are needed to see a difference between the conditions.

| Stimulus | size | location | Freq | #trials |  Observations |
| --- | --- | --- | --- | --- | --- |
| **Left-Hand movement vs No-movement** : (Note: use an actual hand-clenching movement with the hands resting palm up on the table/lap to minimize movement-related artifacts.) |   |   |   |   |   |
| **Left vs Right Hand movement** : (Note: use an actual hand-clenching movement with the hands resting palm up on the table/lap to minimize movement-related artifacts.) |   |   |   |   |   |

#Demo: Evoked BCI– Matrix Speller

Now you will run an simple matrix speller BCI.

1. Exit the ER(s)P experiment by pressing q to quit.

2. **Calibration**: Click on the 'Calibration' in the speller block button to start the matrix speller calibration phase. You will see a simple grid of numbers – if this is not in front of the subject then move it to that screen.  One of the numbers will be highlighted in green, this will be the target for this trial.  The user should look at this number and count the number of times it 'flashes' by increasing in brightness.  (Note: it takes about 1.5 minutes to complete the training, try not to distract the subject in this period.)

3. **Classifier Training**: When the calibration has finished, you will be returned to the main BCI control window.  Now click the Train Classifier button.  The system will now train a classifier to distinguish the 'target' from the 'non-target' responses based on the data gathered in the calibration phase.  The system will also show you 3 windows, two "Data Visualisation" windows showing **ERP** and **AUC** views of the data, and a summary of the classification performance.
  1. **ERP** – this shows the average time-domain response of the brain to the target vs. non-target response.
  2. **AUC** – this shows with a color code where the main discriminative differences are between the target and non-target responses.  In this plot strong-colors indicate strong response differences, whereas white means no-useful difference.
  3. **Classifier performance** – a final window showing the performance of the trained target/non-target classifier.  (Note: don't click OK on this window until you have looked a the ERP and AUC plots and answered the below questions. (To re-make the figures just click training again.)).
4. Comparing these responses you should answer the following questions:
  1. What are the parameters of the target/non-target distinction, i.e. location, time, magnitude.
  2. Is this the location/time you expected?
  3. Are there any other useful distinctions? e.g. top-down modulated perceptual responses.
5. Click OK in the performance summary window to continue to the testing phase.
6. **On-line testing** – Now your subject can use the trained classifier to select numbers to attend to and communicate with you.  How well does it work (the subject will need to tell you if the system got his selection correct)?  Is the performance as high as you would expect given the classifier performance reported above.
7. Close the stimulus window to stop testing and return to the **BCI Controller.**

#Demo: Induced BCI – Imagined Movement

Now you will run a simple movement classification experiment.  The basic phases are the same as for the Evoked BCI practical, but with slightly different instructions.  Note: The Calibration takes at least 5 minutes so make sure you have enough time left.

1. **Calibration** - get the subject to perform queued contrastive mental task movements, e.g. Imagined Left-hand vs. Right-hand movements.  As above use hand clenching with the hands resting on palm up the table/lap to generate a strong signal whilst minimising movement artifacts.
2. **Classifier Training** – train a subject specific classifier on the calibration data.  Classifier Training: When the calibration has finished, you will be returned the the main BCI control window.  Now click the classifier training button.  The system will now train a classifier to distinguish the 'left-hand' from the 'right-hand' responses based on the data gathered in the calibration phase.  The system will also show you 2 windows, the ERsP view and the AUC view of the data.
  1. **ERsP** – this shows the average **frequency-domain** response of the brain to the left-hand vs. right-hand response.
  2. **AUC** – this shows with a color code where the main discriminative differences are between the target and non-target responses.  In this plot strong-colors (blue/green) indicate strong response differences, whereas white means no-useful difference.
  3. **Classifier performance** – a final window showing the performance of the trained target/non-target classifier.  (Note: don't click OK on this window until you have looked a the ERP and AUC plots and answered the below questions. (Just click training again if you do))
3. Comparing these responses you should answer the following questions:
  1. What are the parameters of the left/right movement distinction, i.e. location, time, magnitude.
  2. Is this the location/time you expected?
  3. Are there any other useful distinctions? e.g. very low frequency changes?
4. Click OK in the classifier performance window to continue to testing.
5. **On-line testing** - Use classifier to decode unknown mental-tasks.
