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
package nl.ru.bcigames.GdxInputReplacer;


import com.badlogic.gdx.Application;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses.DirectKeyModeImpl;
import nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses.GamePlayModeAbs;
import nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses.KeyCommandsBuffer;
import nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses.StickyKeyModeImpl;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

/**
 * @author Samarpan Rai (greenspray)
 *
 * This Facade is responsible for,
 * 1) Setting the Log Level in {@link Application}
 * 2) Initialize KeyCommands buffer which intercepts keys sent from the server
 * 3) Creates corresponding KeyCommand mode
 * strategy based on game play mode set in {@link StandardizedInterface}.
 */
public class ControlModeFacade {

    /**
     * The Commands buffer.
     */
    public static KeyCommandsBuffer commandsBuffer;
    private static GamePlayModeAbs commandMode;


    private static final ControlModeFacade instance = new ControlModeFacade();

    private ControlModeFacade() {
        Gdx.app.setLogLevel(Application.LOG_DEBUG);
        commandsBuffer =  KeyCommandsBuffer.getInstance();
        commandMode = new DirectKeyModeImpl(); //default
        initalizeKeyCommandMode();
    }

    /**
     * Get instance control facade.
     *
     * @return the control facade's instance
     */
    static ControlModeFacade getInstance(){
        initalizeKeyCommandMode(); //always update commandMode
        return instance;
    }


    private static void initalizeKeyCommandMode(){
        // check if the current command mode is already the latest command mode
        if(commandMode.getCommandModeName().equals(StandardizedInterface.getCurrentGamePlayMode().toString()))
            return;
        //Add observers

        if( StandardizedInterface.getCurrentGamePlayMode().equals(StandardizedInterface.GamePlayMode.DIRECT) ) {
            commandMode = new DirectKeyModeImpl();

            Gdx.app.log("GamePlayMode","Direct" );
        }
        else {
            commandMode = new StickyKeyModeImpl();
            Gdx.app.log( "GamePlayMode","Sticky" );
        }
        commandMode.setCommandModeName(StandardizedInterface.getCurrentGamePlayMode().toString());
        commandsBuffer.addObserver(commandMode);
    }


    /**
     * Checks if the keycode is exactly what the buffer client sent.
     * @param key the key
     * @return the boolean
     */
    boolean isKeyPressed(int key){
        boolean state = commandMode.getGdxCommand() == key ;
        if(state) {
            commandMode.reset();
            Gdx.app.log(this.getClass() +  ": Key press from Buffer ", Input.Keys.toString(key) );
        }
        return state;
    }
}
