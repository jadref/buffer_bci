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
package nl.ru.bcigames.VisualStimuliBackend;

/**
 * The stimulus loop runs in a separate thread to ensure that the changes of the stimuli are indeed
 * in the right amount of steps. You can access the timings, and the current stimulus files.
 */
public class StimThread implements Runnable{

    private int current_stim;
    private float[][] stimSeq;
    private int[] stimTime;
    private boolean running;
    private long start;
    private int n_cycles;
    private int max_cycles = -1;

    /**
     * Constructor for the Stimulus Thread, if the timing and sequence arrays are already given.
     * @param stimSeq stimulus sequence file NxM
     * @param stimTime stimulus timings 1xN
     */
    public StimThread(float[][] stimSeq, int[] stimTime){
        current_stim = 0;
        n_cycles = 0;
        this.stimTime = stimTime;
        this.stimSeq = stimSeq;
        running = false;
    }

    /**
     * Debugging constructor with a standard file.
     * Maybe remove to avoid problems with wrong initialization.
     */
    public StimThread(){
        current_stim = 0;
        running = false;
    }

    /**
     * Constructor for the Stimulus Thread, when only the file location is known.
     * @param stimulusfile location of the stimulus file
     */
    public StimThread(String stimulusfile){
        StimulusReader sr = new StimulusReader(stimulusfile);
        stimTime = sr.getStimTime();
        stimSeq = sr.getStimSeq();
        current_stim = 0;
        n_cycles = 0;
        running = false;
    }

    /**
     * Change the stimulus file used for the thread and reinitialize the stimulus timings and sequence
     * @param stimulusfile Stimulus file to read.
     */
    public void readStimulusFile(String stimulusfile){
        StimulusReader sr = new StimulusReader(stimulusfile);
        stimTime = sr.getStimTime();
        stimSeq = sr.getStimSeq();
        current_stim = 0;
        n_cycles = 0;
        running = false;
    }

    /**
     * Checks every millisecond if the new timing is reached and updates the position of the
     * stimulus sequence.
     * Error of up to 4 milliseconds in the timings.
     */
    @Override
    public void run() {
        running = true;
        current_stim = 0;
        n_cycles = 0;
        start = System.nanoTime();
        while(running){
            try {
                Thread.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            long end = System.nanoTime();

            if(current_stim == 254){
                start = System.nanoTime();
                current_stim = 0;
                n_cycles += 1;
            }else if(end-start > stimTime[(current_stim+1)] * Math.pow(10,6)){
                current_stim = (current_stim+1)%255;
                //start = System.nanoTime();
            }

            if(n_cycles == max_cycles){
                stop();
                current_stim = 0;
            }
        }
    }

    /**
     * Returns the time elapsed since the start call of the function.
     * @return long time in milliseconds
     */
    public long getElapsedTime(){
        return (long)((System.nanoTime()-start)/Math.pow(10,6)) + (n_cycles*25400);
    }

    /**
     * Getter for the current stimulus sequence
     * @return The stimulus sequence currently active
     */
    public float[] getCurrentStimulusSequence(){
        return stimSeq[current_stim];
    }

    /**
     * Getter for the current stimulus sequence
     * @return The stimulus sequence currently active
     */
    public boolean[] getCurrentStimulusSequenceBoolean() {
        boolean [] return_array = new boolean[stimSeq[current_stim].length];
        for(int i=0; i < stimSeq[current_stim].length; i++){
            return_array[i] = stimSeq[current_stim][i] == 1.0f;
        }
        return return_array;
    }
    /**
     * Getter for the current stimulus position
     * @return
     */
    public int getCurrentStimPosition() {
        return current_stim;
    }

    /**
     * Stops the thread
     */
    public void stop(){
        running = false;
    }

    /**
     * Returns whether the thread is running.
     * @return true if the thread is running, false otherwise.
     */
    public Boolean isRunning(){
        return running;
    }

    /**
     * Maximum number of cycles, if one doesn't want the thread to run endlessly
     * Earlier stopping criterion for debugging purposes
     * @param max
     */
    public void setMaxCycles(int max){
        max_cycles = max;
    }
}
