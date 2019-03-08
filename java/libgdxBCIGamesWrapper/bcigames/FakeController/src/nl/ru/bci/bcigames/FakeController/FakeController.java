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

package nl.ru.bci.bcigames.FakeController;

import nl.ru.bcigames.ServerWrapper.Subscriber;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;

/**
 * Fake Controller class, handles everything around the controller.
 */
public class FakeController extends JFrame implements KeyListener {

    private boolean running = true;

    /**
     *  Constructor for the FakeController
     */
    public FakeController(){
        StandardizedInterface si = StandardizedInterface.getInstance();
        StandardizedInterface.BufferClient.connect();
        initWindow();
    }


    /**
     * All the JFrame methods that are needed to create a window
     */
    private void initWindow(){
        addKeyListener(this);
        System.out.println("Working Directory = " +
                System.getProperty("user.dir"));
        ImageIcon img = new ImageIcon("bcigames/nl.ru.bci.bcigames.FakeController.FakeController/images/controller_cc.jpg");
        JLabel background = new JLabel("",img,JLabel.CENTER);
        background.setBounds(0,0,600,300);
        add(background);
        this.setTitle("nl.ru.bcigames.fakecontroller.nl.ru.bci.bcigames.FakeController.FakeController");
        this.setResizable(false);
        this.setSize(600, 300);
        this.setMinimumSize(new Dimension(600, 300));
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setVisible(true);

    }

    /**
     * Safely disconnects the publisher and closes the window
     */
    public void kill(){
        this.dispose();
    }

    /**
     * Indicates, whether the window is still open
     * @return boolean if it is open
     */
    public boolean isRunning(){
        return running;
    }

    @Override
    public void keyTyped(KeyEvent e) {

    }

    @Override
    public void keyPressed(KeyEvent e) {

    }

    /**
     * On the release of the key an event will get send.
     * This event is coded in an integer array for easier communication
     * @param e key event that is received from the keyboard
     */
    @Override
    public void keyReleased(KeyEvent e) {
        //System.out.println("Key pressed: " + e.getKeyCode());
        //key up 38 w 87
        //key left 37 a 65
        //key down 40 s 83
        //key right 39 d 68

        if(e.getKeyCode() == 38 | e.getKeyCode() == 87) {
            //up
            int keycode = 0;
            publishManyTimes(1,keycode);
        }else if(e.getKeyCode() == 37 | e.getKeyCode() == 65){
            //left
            int keycode = 1;
            publishManyTimes(1,keycode);

        }else if(e.getKeyCode() == 40 | e.getKeyCode() == 83){
            //down
            int keycode = 2;
            publishManyTimes(1,keycode);
        }else if(e.getKeyCode() == 39 | e.getKeyCode() == 68){
            //left
            int keycode = 3;
            publishManyTimes(1,keycode);
        }else if(e.getKeyCode() == 27){
            //ESC
            System.out.println("Controller will be shutdown");
            running = false;
            kill();
        }
    }

    public void publishManyTimes(int times, int keycode){
        for(int i = 0; i < times; i++)
            StandardizedInterface.BufferClient.publish("Keystroke", Integer.toString(keycode));

    }
}
