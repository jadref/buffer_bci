A BCI experiment always consists of at least two phases: a *training* phase and a *test* phase. During the training phase you collect labelled EEG data (for instance, EEG data corresponding to the imagination of a left (labelled as “stimulus.left”) or right (labelled as “stimulus.right”) hand movement. This labelled EEG data is used to train a classifier. The trained classifier will then be used to classify new (i.e. unlabelled) data samples during the testing phase.

To build a BCI you need two main things.  
   1) Application : This part controls the user experience, showing them stimuli (if need), moving between the experiemnt phases, cueing them with what mental task to perform etc.
   2) Signal Analysis : This part gets the EEG data, trains the classifiers, and generates the predictions when needed.

As Brain responses come in two main types, i.e. *evoked*, and *induced* responses, the signal analysis component of the BCI can be made fairly standard for many different BCI applications.   Thus, in the ../signalProc directory there is a default signal analysis system (called: startSigProbBuffer) which can be configured for either evoked (ERP) or induced (ERsP) responses.  

This can be used by only configuring a few parameters.  However, to make the signal analysis work correctly with your application you need to do some additional work. Specificially, you need to **send events** to tell the signal-analysis what type of data is currently being recorded and what type of output it should generate.  For example, to use the evoked response analysis you need to send and event to tell the signal analysis routine when (and what type) of stimulus has just happened.  The signal analysis routine can then use this information to either gather examples of particular responses for later classifier training, or to apply a trained classifier and generate a prediction.

Thus, sending appropriate events is critical to the operation of the BCI -- **without the events there is no connection between the brain data and the application**.


Here, I will explain how to label your EEG data during your experiment and how to save the data for offline analysis. For this purpose, I will use the Psychopy example experiment on imagined movement that you can find in:
`imaginedmovement_psychoPy/simple_imageined_movement.psyexp`

In order to label the recorded EEG data during your experiment, you need to connect your Psychopy experiment to the buffer that is running simultaneously (as explained below). When you open the simple_imagined_movement.psyexp experiment in Psychopy and click on the “Instructions”-routine (first thing in the timeline), there is a short custom-made piece of code called “connectToBuffer”. This piece of code will make the connection to the running buffer. You can simply copy-paste it into your own Psychopy experiment. Make sure you insert it into the start of your experiment. Also, make sure that the required path (i.e. `sys.path.append("../../dataAcq/buffer/python/"))` in the `connectToBuffer` code is correct. The current path assumes that your Psychopy experiment is in `python/your_experiment_name`. You can either copy your Psychopy experiment to that directory or change the path, so it points correctly to the `dataAcq/buffer/python/` folder.

Now that your experiment is connected to the buffer, you can send events to it. Events are used to label the recorded EEG data and are visible to all other processes (i.e. buffer, signal processing, etc.). The different processes that are involved in a single BCI experiment, thus communicate with each other by sending and receiving events. All events are saved together with the EEG data by the buffer, so all labels are automatically stored for later off-line use.

Generally you want to send events to label your data at any point in time when something happens (i.e. when a stimulus is presented or changes). In case of the simple_imagined_movement.psyexp, the most important events are those that mark the onset of the imagined movement (i.e. when the word “left” or “right” is presented on the screen). These events are used to label specific data samples with “stimulus.right” or “stimulus.left” and are necessary in order to train a classifier. Usually you also send events marking the start/end of the experiment, the start/end of each trial, the start/end of a fixation cross, etc. Recording EEG data alone is useless since you will have no idea what the data corresponds to when it is not labelled.

Each event has timestamp (i.e. the time at which the event occurred in samples from the start of the experiment), a value and a type. You can send an event using: sendEvent(type,value). An example of this can be found in the “stimulus”-routine of the simple_imagined_movement.psyexp. In the “stimulus”-routine, you find a short custom-made piece of code called “sendEvent_2”. When you open this piece of code, you find “sendEvent("stimulus", str(bodypart))”. This means that each time when the word “left” or “right” is presented on the screen, an event of value “stimulus” and type “left” or “right” (indicated by “str(bodypart)”) is sent to the buffer.

To run the training phase of your experiment and collect and save training data, you need to:

    Start the buffer

The buffer is located in `dataAcq/startBuffer.bat` (Windows) or .sh (Mac)

    Start the data acquisition

            If you have *no* EEG hardware, but just want to test:

            Start a simulated data source by running:

            `dataAcq/startSignalProxy.bat` or .sh

 

            OR

 

            If you have EEG hardware connected (i.e. are using the TMSi Mobita):

            Start the hardware driver by running: `dataAcq/startMobita.bat` or .sh

           

    Start the Psychopy experiment:

            -First start PsychoPy

            -Now Go to the View menu and switch to 'Builder View'

            -Now load the file: `simple_imagined_movement.psyexp` (or your own experiment)

            -Run the file by pressing the green running man button.

            -Type in the subject name and session in the participant information window.  Then follow the presented instructions to run the experiment.