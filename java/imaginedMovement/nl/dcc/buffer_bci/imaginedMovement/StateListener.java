package nl.dcc.buffer_bci.imaginedMovement;

import nl.dcc.buffer_bci.imaginedMovement.State.Rotation;

/**
 * State listener.
 * @author Bas Bootsma
 */
public interface StateListener
{
    public void onTextChanged(String text);
    public void onDirectionChanged(double direction);
    public void onPowerChanged(double power);
    public void onRotationChanged(Rotation rotation);
}
