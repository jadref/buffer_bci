package com.badlogic.invaders;

import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;

/**
 * A controller specific for input generated for the Invaders demo.
 *
 * Created by lars on 11/21/15.
 */
public class InvadersController extends BufferBciController {
    public static final int AXIS_X = 0;
    public static final int BTN_FIRE = 1;

    public InvadersController() {
        super();

        // Add an axis to the controller.
        addAxis(AXIS_X, new BufferBciController.BufferBciAxisProcessor() {

            // Respond to the AXIS_X buffer event.
            @Override
            public boolean trigger(BufferEvent evt) {
                return evt.getType().toString().equals("AXIS_X");
            }

            // Interpret the event value as a single float value.
            @Override
            public float getValue(BufferEvent evt) {
                String v = evt.getValue().toString();
                return Float.parseFloat(v);
            }
        });

        // Add a button to the controller.
        addButton(BTN_FIRE, new BufferBciController.BufferBciButtonProcessor() {

            // Respond to the BTN_FIRE buffer event.
            @Override
            public boolean trigger(BufferEvent evt) {
                return evt.getType().toString().equals("BTN_FIRE");
            }

            // When the value is 'down', the button is pushed down.
            // When the value is 'up', the button is up.
            @Override
            public boolean isActivated(BufferEvent evt) {
                return evt.getValue().toString().equals("down");
            }
        });
    }
}
