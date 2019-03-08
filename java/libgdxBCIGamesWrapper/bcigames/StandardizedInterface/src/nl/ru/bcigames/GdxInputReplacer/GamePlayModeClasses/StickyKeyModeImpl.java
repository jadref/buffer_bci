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
package nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

import java.util.Observable;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;


/**
 * @author Samarpan Rai (greenspray)
 * The type Sticky key mode.
 */
public class StickyKeyModeImpl extends GamePlayModeAbs {


    private boolean newCommandRegistered = false;
    private long lastCommandInterceptedAt = 0;
    private int lastGdxCommand;


    /**
     * Instantiates a new Sticky key mode.
     */
    public StickyKeyModeImpl(){
        startCommandCountDecay();
    }

    /**
     * This object is responsible for checking if the system has received any new keys command a per-defined period in time
     * and set flag correspondingly.
     *
     */
    private void startLastCommandWatchDog() {
        (new Thread(() -> {
            long difference = System.currentTimeMillis() - lastCommandInterceptedAt;

            while ( (difference < StandardizedInterface.KEY_REPLACER_TIME_TO_WAIT_BEFORE_SENDING_LAST_COMMAND) & !newCommandRegistered) {
                difference = System.currentTimeMillis() - lastCommandInterceptedAt;
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            if(newCommandRegistered)
                newCommandRegistered = false;
        })).start();

    }

    /**
     * This object is responsible for getting the decatRateForCount (in ms) from the {@link StandardizedInterface}
     * and start decreasing the count for all key command's counters by once every decatRateForCount ms
     */
    private void startCommandCountDecay(){
        long decayRateForCount = StandardizedInterface.getKeyCommandDecayRate();
        TimerTask repeatedTask = new TimerTask() {
            public void run() {
                if(keyCommandBuffer != null && keyCommandBuffer.decreaseAble()) {
                    keyCommandBuffer.decrementBy1();
                    Gdx.app.log(this.getClass().toString() , "CommandCountDecay : Decreasing command count by 1");
                }
            }
        };
        Timer timer = new Timer("StickyCommandTimer");

        long delay = 500L;
        timer.scheduleAtFixedRate(repeatedTask, delay,  decayRateForCount);
    }


    @Override
    public void update(Observable observable, Object o) {
        if(observable instanceof KeyCommandsBuffer){
            keyCommandBuffer = (KeyCommandsBuffer) observable;
            highestKeyCommand = getHighestKeyCommand();
            if(highestKeyCommand.getCount() >= 0) {
                lastCommandInterceptedAt = System.currentTimeMillis();
                lastGdxCommand = highestKeyCommand.getGdxKey();
                setGdxCommand(lastGdxCommand);
                newCommandRegistered = true;
            }
        }
    }

    /**
     * A thread-blocking method for setting the command
     * @param cmd The command key to set
     */
    private synchronized void setGdxCommand(int cmd){
        currentGdxCommand = cmd;
    }

    @Override
    public int getGdxCommand() {
        return  currentGdxCommand;
    }

    /**
     *   The reset in StickyMode is responsible for:
     *   1) Making sure to keep some delay in between two commands such that GDX system registers it as
     *   command.
     *   2) If no new command is registered, Set last command as current command after a pre-defined delay.
     *
     */
    @Override
    public void reset() {
        startLastCommandWatchDog();
        setGdxCommand(Input.Keys.UNKNOWN);
        ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(1);
        if (!newCommandRegistered)
            executor.schedule(() -> setGdxCommand(lastGdxCommand), StandardizedInterface.KEY_REPLACER_TIME_TO_WAIT_BETWEEN_TWO_COMMANDS, TimeUnit.MILLISECONDS);
    }

}
