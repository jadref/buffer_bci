package nl.dcc.buffer_bci.imaginedMovement;

/**
 * Action event.
 * @author Bas Bootsma
 */
public enum ActionEvent
{        
    WEBCAM_SHOW,
    WEBCAM_HIDE,
    DIRECTION_METER_SHOW,
    DIRECTION_METER_HIDE,
    DIRECTION_METER_RESET,
    DIRECTION_METER_VALUE,                      // From 0 up till 2 * pi
    DIRECTION_METER_ROTATION,                   // Values: NONE, CLOCKWISE, COUNTER_CLOCKWISE
    POWER_METER_SHOW,
    POWER_METER_RESET,
    POWER_METER_HIDE,
    POWER_METER_VALUE,                          // From 0 up to 1
    TEXT_SHOW,                                  // Value of the text
    TEXT_HIDE,
    TEXT_RESET,
    TEXT_VALUE
}
