package com.badlogic.invaders;

import com.badlogic.gdx.controllers.Controller;
import com.badlogic.gdx.controllers.ControllerListener;
import com.badlogic.gdx.controllers.PovDirection;
import com.badlogic.gdx.math.Vector3;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;

import java.util.ArrayList;

/**
 * An implementation of Controller for the buffer_bci framework.
 *
 * Doesn't define any axes or buttons on its own. These have to be added manually to an instance or a subclass.
 *
 * Created by lars on 11/21/15.
 */
public class BufferBciController implements Controller, BufferBciInput.ArrivedEventsListener {
    /** The unprocessed unprocessedEvents passed from BufferBciInput. **/
    private ArrayList<BufferEvent> unprocessedEvents;

    /** The buttons this controller supports. **/
    protected final ArrayList<BufferBciButton> buttons;

    /** The axes this controller supports. **/
    protected final ArrayList<BufferBciAxis> axes;

    /** The listeners that listen to this controller. **/
    protected final ArrayList<ControllerListener> controllerListeners;

    /**
     * Initializes the BufferBciController instance.
     */
    public BufferBciController() {
        this.buttons = new ArrayList<BufferBciButton>();
        this.axes = new ArrayList<BufferBciAxis>();
        this.controllerListeners = new ArrayList<ControllerListener>();
        this.unprocessedEvents = new ArrayList<BufferEvent>();
    }

    /**
     * Adds a virtual axis.
     * @param code The code for the virtual axis.
     * @param processor The processor that determines the value of the axis.
     */
    public void addAxis(int code, BufferBciAxisProcessor processor) {
        // Check whether this axis already exists.
        for(BufferBciAxis axis : axes) {
            if(axis.code == code) {
                throw new IllegalArgumentException("Given axis code has already been added.");
            }
        }

        // Add the axis.
        BufferBciAxis axis = new BufferBciAxis();
        axis.code = code;
        axis.processor = processor;
        axis.value = 0;
        axes.add(axis);
    }

    /**
     * Adds a virtual button.
     * @param code The code for the virtual button.
     * @param processor The processor that determines whether the button is pressed or not.
     */
    public void addButton(int code, BufferBciButtonProcessor processor) {
        // Check whether this button already exists.
        for(BufferBciButton button : buttons) {
            if(button.code == code) {
                throw new IllegalArgumentException("Given button code has already been added.");
            }
        }

        // Add the button.
        BufferBciButton button = new BufferBciButton();
        button.code = code;
        button.processor = processor;
        button.activated = false;
        buttons.add(button);
    }


    /**
     * Saves the provided events until update() is called on the rendering thread.
     * @param events The events that have occurred since the last update.
     */
    @Override
    public void receiveEvents(BufferEvent[] events) {
        // Since receiveEvents is called from the buffer_bci thread, claim the unprocessedEvents arraylist.
        synchronized (unprocessedEvents) {
            for (BufferEvent e : events) {
                this.unprocessedEvents.add(e);
            }
        }
    }

    /**
     * Processes unprocessed buffer events.
     */
    public void update() {
        if(unprocessedEvents == null) return;

        synchronized (unprocessedEvents) {
            for (BufferEvent e : unprocessedEvents) {
                updateButtons(e);
                updateAxes(e);
            }
        }
    }

    /**
     * Updates all buttons with the given buffer event.
     * @param e
     */
    private void updateButtons(BufferEvent e) {
        for(BufferBciButton btn : buttons) {
            if (btn.processor.trigger(e)) {
                btn.activated = btn.processor.isActivated(e);

                onButtonUpdated(btn);
            }
        }
    }

    /**
     * Called whenever a button is updated.
     * @param btn
     */
    private void onButtonUpdated(BufferBciButton btn) {
        // Inform listeners.
        for (ControllerListener cl : controllerListeners) {
            if (btn.activated) {
                cl.buttonDown(this, btn.code);
            } else {
                cl.buttonUp(this, btn.code);
            }
        }
    }

    /**
     * Updates all axes with the given buffer event.
     * @param e
     */
    private void updateAxes(BufferEvent e) {
        for (BufferBciAxis axis : axes) {
            if (axis.processor.trigger(e)) {
                axis.value = axis.processor.getValue(e);
                onAxisUpdated(axis);
            }
        }
    }

    /**
     * Called whenever an axis is updated.
     * @param axis
     */
    protected void onAxisUpdated(BufferBciAxis axis)
    {
        // Inform listeners.
        for (ControllerListener cl : controllerListeners) {
            cl.axisMoved(this, axis.code, axis.value);
        }
    }



    @Override
    public boolean getButton(int buttonCode) {
        for(BufferBciButton s : buttons) {
            if(s.code == buttonCode) {
                return s.activated;
            }
        }

        return false;
    }

    @Override
    public float getAxis(int axisCode) {
        for(BufferBciAxis a : axes) {
            if(a.code == axisCode) {
                return a.value;
            }
        }

        return 0;
    }

    @Override
    public String getName() {
        return "buffer_bci controller";
    }

    @Override
    public void addListener(ControllerListener listener) {
        controllerListeners.add(listener);
    }

    @Override
    public void removeListener(ControllerListener listener) {
        controllerListeners.remove(listener);
    }

    /**
     * Represents a button.
     */
    private static class BufferBciButton
    {
        public int code;
        public boolean activated;

        public BufferBciButtonProcessor processor;
    }

    /**
     * A button processor. A processor responds buffer events for the button.
     */
    public interface BufferBciButtonProcessor
    {
        boolean trigger(BufferEvent evt);
        boolean isActivated(BufferEvent evt);
    }

    /**
     * Represents an axis.
     */
    private class BufferBciAxis
    {
        public int code;
        public float value;

        public BufferBciAxisProcessor processor;
    }

    /**
     * An axis processor. A processor responds to buffer events for the axis.
     */
    public interface BufferBciAxisProcessor
    {
        boolean trigger(BufferEvent evt);
        float getValue(BufferEvent evt);
    }



    /** Unimplemented methods **/

    @Override
    public PovDirection getPov(int povCode) {
        return null;
    }

    @Override
    public boolean getSliderX(int sliderCode) {
        return false;
    }

    @Override
    public boolean getSliderY(int sliderCode) {
        return false;
    }

    @Override
    public Vector3 getAccelerometer(int accelerometerCode) {
        return null;
    }

    @Override
    public void setAccelerometerSensitivity(float sensitivity) {

    }
}
