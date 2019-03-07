/*
 * Copyright (c) 2019 Jeremy Constantin Börker, Anna Gansen, Marit Hagens, Codruta Lugoj, Wouter Loeve, Samarpan Rai and Alex Tichter
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package nl.ru.bcigames.StandardizedInterface;

import com.badlogic.gdx.Gdx;
import nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses.KeyCommandsBuffer;
import nl.ru.bcigames.ServerWrapper.ConnectionState;
import nl.ru.bcigames.ServerWrapper.SubscribeEvent;
import nl.ru.bcigames.ServerWrapper.Subscriber;
import nl.ru.bcigames.VisualStimuliBackend.StimThread;


import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public  class StandardizedInterface {

    private static String hostname;
    private static int port;
    private static int timeOut;
    private static int gameStepLength = 60;
    private static StandardizedInterface instance = null;
    public static BufferClient BufferClient = null;
    public static StimuliSystem StimuliSystem = null;
    private static Subscriber sub = null;
    private static StimThread stimThread = null;
    private static boolean[] stimSequence;
    private static int currentStimulusIndex;
    private static long timeZero;
    private static int keyCommandDecayRate = 200;
    private static GamePlayMode currentGamePlayMode = GamePlayMode.DIRECT;

    /**
     *  Key stroke string. This is the key-value pair where key is a string (in this case Keystroke) and value is the output sent from BufferBCI
     */
    public static final String KEY_REPLACER_KEYSTROKE_STRING = "Keystroke";
    /**
     * In sticky mode, this delay will dictate how much the system waits before sending the last command.
     * This delay is required to simulate key press because Gdx will only consider a key as being pressed
     * once it is released. The unit is microsecond.
     */
    public static final int KEY_REPLACER_TIME_TO_WAIT_BEFORE_SENDING_LAST_COMMAND = 2500;
    /**
     * In sticky mode, when there are no new command, this delay will dictate how much the system waits between
     * two commands. The unis is microsecond.
     */
    public static final int KEY_REPLACER_TIME_TO_WAIT_BETWEEN_TWO_COMMANDS = 2000;

    /**
     * These are the KeyCommand modes namely direct input and sticky keys
     */
    public enum GamePlayMode {
        STICKY,
        DIRECT
    }

    /**
     * Draft for the nl.ru.bcigames.standardizedinterface.nl.ru.bcigames.StandardizedInterface.StandardizedInterface. Nothing in here works but almost everything looks pretty. :)
     */
    private StandardizedInterface() {
        timeZero = System.nanoTime();
        hostname = "127.0.0.1";
        port = 1972;
        timeOut = 1000;
        BufferClient = new BufferClient();
        StimuliSystem = new StimuliSystem();
        BufferClient.connect();
    }

    /**
     * Stops all threads safely. Such as server connections
     */
    public static void cancel() {
        BufferClient.disconnect();
    }

    /**
     * Returns static instance of the nl.ru.bcigames.standardizedinterface.nl.ru.bcigames.StandardizedInterface.StandardizedInterface. Used for singelton.
     * @return nl.ru.bcigames.StandardizedInterface.StandardizedInterface
     */
    public static StandardizedInterface getInstance() {
        if (instance == null) {
            instance = new StandardizedInterface();
        }
        return instance;
    }

    /**
    Returns instance of Subscriber
    @return if Instantiated, the Subscriber Object  else null
     */
    public Subscriber getSubscriberInstance(){
        if(BufferClient.isConnected()){
            return sub;
        }
        else {
            Gdx.app.error(this.getClass()+":SubscriberInstance", "Subscriber Instance not created yet");
            return null;
        }
    }

    /**
     * Set the decay time for the key command counter
     * @param keyCommandDecayRate
     */
    public static void setKeyCommandDecayRate(int keyCommandDecayRate) {
        StandardizedInterface.keyCommandDecayRate = keyCommandDecayRate;
    }

    /**
     * Returns the decay time used by the key command counter.
     * @return
     */
    public static int getKeyCommandDecayRate() {
        return keyCommandDecayRate;
    }

    /**
     * This sets the amount of frames a game is rendered between bci steps
     * @param i
     */
    public static void setGameStepLength(int i) {
        StandardizedInterface.gameStepLength = i;
    }

    /**
     * This gets the amount of frames a game is rendered between bci steps
     */
    public static int getGameStepLength() {
        return StandardizedInterface.gameStepLength;
    }

    /**
     * Set if Sticky keys or direct keys are used
     * @param playMode
     */
    public static void setCurrentGamePlayMode(GamePlayMode playMode) {
        currentGamePlayMode = playMode;
    }

    /**
     * Returns if StickyKeys or Direct Mode is used
     * @return
     */
    public static GamePlayMode getCurrentGamePlayMode() {
        return currentGamePlayMode;
    }


/** ########################## */

    /**
     * This is used to connect/disconnect with an BCI/BufferClient via the bufferBCI server
     */
    public static class BufferClient {
        ExecutorService pool = Executors.newCachedThreadPool();

        // Make BufferClient Singelton
        private BufferClient() {
            Gdx.app.error(this.getClass()+":BufferClient", "BufferclientCreated");
        }

        /**
         * Tries to establish a connection with the server; execute the task
         */
        public void connect() {
            System.out.println("Connect to server");

                sub = new Subscriber(hostname, port, timeOut);
                pool.execute(sub);
                registerForKeyStrokes();
        }

        /**
         * Register KeyStroke event listener to react to game commands coming from BCI Analyzer
         */
        private void registerForKeyStrokes() {
            try{
                sub.addListener(new SubscribeEvent() {
                    @Override
                    public boolean trigger(String key) {
                        return key.equals(StandardizedInterface.KEY_REPLACER_KEYSTROKE_STRING);
                    }

                    @Override
                    public void action(String value) {
                        String extractedData = value.split(",")[1];
                        int serverKeycode = Integer.parseInt(extractedData);
                        KeyCommandsBuffer.getInstance().update(serverKeycode);
                    }
                });
            }
            catch (Exception e){
                Gdx.app.error(this.getClass() + ": SubscriberEventCreation :","Cannot create subscriber event", e);
            }
        }

        /**
         * Disconnect from server
         */
        public void disconnect() {
            if (sub != null) {
                sub.disconnect();
                System.out.println("Disconnected from server");
            }
        }

        /**
         * Shows if the SI is connected to the server. True for yes and false for no
         * @return boolean
         */
        public boolean isConnected() {
            if (sub != null) {
                return sub.isConnected();
            }
            return false;
        }

        /**
         * Set the port at which the bufferBCI server is listening for a connection
         * @param p new port
         */
        public void setPort(int p) {
            StandardizedInterface.port = p;
        }

        /**
         * Set the IP of the computer on which the server is running
         * @param hostname new hostname address as string
         */
        public void setHostname(String hostname) {
            StandardizedInterface.hostname = hostname;
        }

        /**
         * Set server connection timeout
         * @param timeout
         */
        public void setTimeout(int timeout) { StandardizedInterface.timeOut = timeout; }

        /**
         * Get the port used
         * @return Port used as int
         */
        public int getPort() {
            return StandardizedInterface.port;
        }

        /**
         * Get the IP used
         * @return IP used as string
         */
        public String getHostname() {
            return StandardizedInterface.hostname;
        }

        /**
         * Get detailed connection state
         * @return ConnectionState
         */
        public ConnectionState getConnectionState() {
            if(sub != null) {
                return sub.getConnectionState();
            }
            else {
                return ConnectionState.CLOSED;
            }
        }

        /**
         * Publishes data with timestamp relative to the moment when this method is called
         * @param key key of the message
         * @param value value of the message
         */
        public static void publish(String key, String value){
            long time = System.nanoTime() - timeZero;
            //time in milliseconds
            time = time/1000000;
            sub.publish(key,time+","+value);
        }

        /**
         * PPublishes data with timestamp relative to passed time
         * @param key key of the message
         * @param value value of the message
         * @param time time in nano seconds to be used to generate timestamp
         */
        public static void publish(String key, String value, long time){
            long t = time - timeZero;
            //time in milliseconds
            t = t/1000000;
            sub.publish(key,t+","+value);
        }
    }

    /**
     * Here the stimuli system in the game can ask for the state of each of the n stimuli.
     * WORK IN PROGRESS.
     */
    public static class StimuliSystem {

        private static String stimuliFile = "";
        private static String gameStimuliFile = "stimulifiles/gold_10hz.txt";
        private static String calibrationStimuliFile = "stimulifiles/gold_10hz.txt";
        private static boolean isOn = true;
        private boolean stimuliOn = true;
        private boolean synchronous = true;
        private Thread t;

        /**
         * Constructor for the stimulus system
         */
        public StimuliSystem() {
            stimThread = new StimThread();

            //if you only want a fixed number of cycles otherwise it runs endlessly
            stimThread.setMaxCycles(1);
        }

        /**
         * Set a stimulus file to read from
         * @param file string file path
         */
        public void setStimuliFile(String file) {
            stimuliFile = file;
            this.readStimulusFile(file);
            setIsOn(true);
        }

        /**
         * Set a stimulus file for the game
         * @param file string file path
         */
        public void setGameStimuliFile(String file) {
            gameStimuliFile = file;
        }

        /**
         * Get the current game stimulus file path
         * @return file path of stimulus file
         */
        public String getGameStimuliFile() {
            return gameStimuliFile;
        }

        /**
         * Set the stimuli file for the calibration screen
         * @param file string file path
         */
        public void setCalibrationStimuliFile(String file) {
            calibrationStimuliFile = file;
        }

        /**
         * Get the current calibration stimulus file path
         * @return file path of stimulus file
         */
        public String getCalibrationStimuliFile() {
            return calibrationStimuliFile;
        }

        /**
         * Sets the SI mode to synchronous value provided
         * @param synchronous boolean whether synchronous mode or not
         */
        public void setSynchronous(boolean synchronous) { this.synchronous = synchronous;}

        /**
         * Returns whether the SI mode is synchronous or not
         * @return boolean indicating synchronous mode
         */
        public boolean isSynchronous() { return synchronous;}

        /**
         * Sets the stimulus system on the provided value
         * @param stimuliOn value to set the stimulus system to
         */
        public void setStimuliOn(boolean stimuliOn) { this.stimuliOn = stimuliOn;}

        /**
         * Returns whether or not the stimulus system is running
         * @return boolean if it is running
         */
        public boolean isStimuliOn() { return stimuliOn;}

        /**
         * Returns the path to the current stimulus file
         * @return string path to stimulus file
         */
        public String getStimuliFile() {
            return stimuliFile;
        }

        /**
         * Enable/Disable the stimulus system.
         * Once enabled, it runs permanently
         * @param b boolean enable or disable
         */
        public void setIsOn(boolean b) {
            isOn = b;
            if (!b){
                stimThread.stop();
            }else{
                startStimulus();
            }
        }

        /**
         * Indicates whether the stimulus system is running or not
         * @return on or not
         */
        public boolean isOn() {
            return isOn;
        }

        /**
         * Reads a stimuli file from a certain location
         * @param filepath path to the stimulus file
         */
        public void readStimulusFile(String filepath){
            stimThread.readStimulusFile(filepath);
            currentStimulusIndex = -1;
        }

        /**
         * Starts the stimulus system in order to access the stimulus states.
         */
        public void startStimulus(){
            t = new Thread(stimThread);
            t.start();
        }

        /**
         * Stops the stimulus system.
         */
        public void stopStimulus(){
            stimThread.stop();
        }

        /**
         * The game can continuously call this method to ask for the current stimuli active.
         * When it changes, the new stimulus sequence gets send to the server together with the
         * timing the change was registered by the game.
         * @return boolean array.
         */
        public boolean[] getStimuliStates() {
            stimSequence = stimThread.getCurrentStimulusSequenceBoolean();
            int new_stimulus_index = stimThread.getCurrentStimPosition();
            if (new_stimulus_index > currentStimulusIndex){
                currentStimulusIndex = new_stimulus_index;
            }
            return stimSequence;
        }

        /**
         * Use this function to send the stimulus states with the correct timing to the server.
         * @param stimulusStates
         */
        public void sendStimUpdateToServer(boolean[] stimulusStates){
            instance.BufferClient.publish("StimulusUpdate",booleanArrayToString(stimulusStates));
        }

        /**
         * Returns whether the stimulus thread is still running
         * @return true if it is running
         */
        public boolean isRunning(){ return stimThread.isRunning();}

        /**
         * Time since the start of the simulus system.
         * Gives an independent timing to send to the server when the stimulus got drawn.
         *
         * @return long time in ms since the start of the stimulus thread
         */
        public long getElapsedTime(){ return stimThread.getElapsedTime();}

        /**
         * Stimulus currently active.
         * Can be used to keep track of the change of the position in the stimulus system.
         * @return
         */
        public int getCurrentStimulusPosition(){ return stimThread.getCurrentStimPosition();}

        /**
         * Converts a boolean array into the standardized string notation
         * @param b 1D array to convert
         * @return standardized string notation
         */
        public String booleanArrayToString(boolean[] b){
            String s = "";
            for(int i=0; i<b.length; i++){
                if (b[i] == true) {
                    s += "1";
                } else {
                    s += "0";
                }
            }
            return s;
        }

        /**
         * Converts a standardized notated string back into a boolean array.
         * @param s standardized string to convert
         * @return boolean array
         */
        public boolean[] stringToBooleanArray(String s){
            boolean[] b = new boolean[s.length()];
            for(int i=0; i<s.length(); i++){
                if(s.charAt(i) == '1'){
                    b[i] = true;
                }else{
                    b[i] = false;
                }
            }
            return b;
        }
    }
}
