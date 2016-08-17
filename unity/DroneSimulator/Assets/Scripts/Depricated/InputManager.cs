using UnityEngine;
using System.Collections;
using System.Collections.Generic;

// This is the core script for input management.
namespace DT.InputManagement
{

    // Add at the bottom of this enum any new action code (just give it a reasonable name).
    // You can see this enum as a list of virtual keys. A physical key will be binded to an action code.
    public enum ActionCode
    {
        None,
        Escape,
        MoveUp,
        MoveDown,
        MoveRight,
        MoveLeft,
        MoveForward,
        MoveBackward,
        TurnRight,
        TurnLeft
    }

    public static class InputManager
    {

        // =================================================================================================
        // Static variables

        // Dictionary keyBinds
        // This dictionary holds the action code --> key code binding. An action code can have only one
        // backing key code. This means that you can't actually assign multiple physical keys to a 
        // single action code, to perform the same action.
        private static Dictionary<ActionCode, KeyCode> keyBinds = new Dictionary<ActionCode, KeyCode>();

        // List keysAllowed
        // A list of all physical keys that you can bind to the action codes. Quite spartan but this
        // allows you to bind only the physical keys you want - which must be defined in the 'LoadAllowedKeys' method.
        // Any key code which is not in this list will be ignored in 'SetKey' method.
        private static List<KeyCode> keysAllowed = new List<KeyCode>();

        // =================================================================================================
        // Static properties

        // We use this property to check in other scripts if we're escaping - this usually means that
        // we need to interact with a gui, e.g. settings, so we need to disable other action keys.
        public static bool IsEscaping { get; private set; }

        // =================================================================================================
        // Initialize

        public static void Initialize()
        {
            IsEscaping = false;
            LoadAllowedKeys();
            LoadDefaultBinds();
        }

        // =================================================================================================
        // LoadAllAllowedKeys

        // Define here all physical keys that we can bind to the action codes.
        private static void LoadAllowedKeys()
        {
            if (keysAllowed != null)
            {
                keysAllowed.Clear();

                keysAllowed.Add(KeyCode.Q);
                keysAllowed.Add(KeyCode.W);
                keysAllowed.Add(KeyCode.E);
                keysAllowed.Add(KeyCode.R);
                keysAllowed.Add(KeyCode.T);
                keysAllowed.Add(KeyCode.Y);
                keysAllowed.Add(KeyCode.U);
                keysAllowed.Add(KeyCode.I);
                keysAllowed.Add(KeyCode.O);
                keysAllowed.Add(KeyCode.P);
                keysAllowed.Add(KeyCode.A);
                keysAllowed.Add(KeyCode.S);
                keysAllowed.Add(KeyCode.D);
                keysAllowed.Add(KeyCode.F);
                keysAllowed.Add(KeyCode.G);
                keysAllowed.Add(KeyCode.H);
                keysAllowed.Add(KeyCode.J);
                keysAllowed.Add(KeyCode.K);
                keysAllowed.Add(KeyCode.L);
                keysAllowed.Add(KeyCode.Z);
                keysAllowed.Add(KeyCode.X);
                keysAllowed.Add(KeyCode.C);
                keysAllowed.Add(KeyCode.V);
                keysAllowed.Add(KeyCode.B);
                keysAllowed.Add(KeyCode.N);
                keysAllowed.Add(KeyCode.M);
                keysAllowed.Add(KeyCode.UpArrow);
                keysAllowed.Add(KeyCode.LeftArrow);
                keysAllowed.Add(KeyCode.DownArrow);
                keysAllowed.Add(KeyCode.RightArrow);
                keysAllowed.Add(KeyCode.Mouse0);
                keysAllowed.Add(KeyCode.Mouse1);
                keysAllowed.Add(KeyCode.LeftShift);
                keysAllowed.Add(KeyCode.RightShift);
                keysAllowed.Add(KeyCode.Space);
            }
        }

        // =================================================================================================
        // LoadDefaultBinds

        // Add all possible button binds, pay attention to use allowed physical key only.
        public static void LoadDefaultBinds()
        {
            if (keyBinds != null)
            {
                keyBinds.Clear();

                keyBinds.Add(ActionCode.Escape, KeyCode.Escape);
                keyBinds.Add(ActionCode.MoveForward, KeyCode.W);
                keyBinds.Add(ActionCode.MoveBackward, KeyCode.S);
                keyBinds.Add(ActionCode.TurnRight, KeyCode.D);
                keyBinds.Add(ActionCode.TurnLeft, KeyCode.A);
                keyBinds.Add(ActionCode.MoveUp, KeyCode.Space);
                keyBinds.Add(ActionCode.MoveDown, KeyCode.LeftShift);
                keyBinds.Add(ActionCode.MoveLeft, KeyCode.Q);
                keyBinds.Add(ActionCode.MoveRight, KeyCode.E);
            }
        }

        // =================================================================================================
        // GetActionKey

        // Get the physical key code binded to the action code passed in the parameter.
        public static KeyCode GetActionKey(ActionCode actionCode)
        {
            if (keyBinds != null && keyBinds.ContainsKey(actionCode))
            {
                return keyBinds[actionCode];
            }
            Debug.LogError(string.Format("InputManager.GetActionKey: Action code '{0}' not managed by the input manager!", actionCode.ToString()));
            return KeyCode.None;
        }

        // =================================================================================================
        // SetActionKey

        // Bind a physical keycode to an action code. This method should not be called directly, but you should
        // call it through 'SetKey' method instead, since we need to check if the keycode to set is in the allowed keycode list.
        private static void SetActionKey(ActionCode actionCode, KeyCode keycode)
        {
            if (keyBinds != null && keyBinds.ContainsKey(actionCode))
            {

                // This will be used to clear the possible action code that holds the keycode we want to assign to this action code.
                ActionCode bindToReset = ActionCode.None;
                bool reset_old_bind = false;

                if (keyBinds.ContainsValue(keycode))
                {
                    // Theoretically, we should have only one duplicated keycode at this point, 
                    // however a foreach loop doesn't hurt too much in this case, so we use it to get the relative action key.
                    foreach (KeyValuePair<ActionCode, KeyCode> btn in keyBinds)
                    {
                        if (btn.Value == keycode)
                        {
                            // We cannot change the dictionary while looping in it so we need to take the reference of the previously assigned key.
                            bindToReset = btn.Key;
                            reset_old_bind = true;
                            break;
                        }
                    }
                }
                if (reset_old_bind)
                {
                    keyBinds[bindToReset] = KeyCode.None; // clear the action code that was using the keycode we want to set in this action code.
                }
                keyBinds[actionCode] = keycode; // bind the physical key code to the action code.
                Debug.Log("Action Key Set!");
            }
            else
            {
                Debug.LogError(string.Format("InputManager.SetActionKey: Action code '{0}' not managed by the input manager!", actionCode.ToString()));
            }
        }

        // =================================================================================================
        // GetKeyDown

        // Similar to Unity Input.GetKeyDown. Escape is a special key, so we set a flag if pressed,
        // which could be used to enable/disable other action codes (e.g. when enabling the settings gui -> disable movement keys).
        public static bool GetKeyDown(ActionCode actionCode)
        {
            if (actionCode == ActionCode.Escape && Input.GetKeyDown(KeyCode.Escape))
            {
                IsEscaping = !IsEscaping;
            }
            return Input.GetKeyDown(GetActionKey(actionCode));
        }

        // =================================================================================================
        // GetKey

        // Similar to Unity Input.GetKey
        public static bool GetKey(ActionCode actionCode)
        {

            return Input.GetKey(GetActionKey(actionCode));
        }

        // =================================================================================================
        // GetKeyUp

        // Similar to Unity Input.GetKeyUp
        public static bool GetKeyUp(ActionCode actionCode)
        {

            return Input.GetKeyUp(GetActionKey(actionCode));
        }

        // =================================================================================================
        // SetKey

        // Helper method to bind a key code to the action code passed as parameter.
        // This should be called straight after a key event, so we can catch the physical key being pressed in this frame.
        public static bool SetKey(ActionCode actionCode)
        {
            if (keysAllowed != null)
            {
                // check if the key being pressed is an allowed key.
                foreach (KeyCode keycode in keysAllowed)
                {
                    if (Input.GetKeyDown(keycode))
                    {
                        SetActionKey(actionCode, keycode);
                        return true;
                    }
                }
            }
            return false;
        }

        // =================================================================================================
        // UnbindAll

        // Set 'None' to all action codes in keyBinds except escape.
        public static void UnbindAll()
        {
            if (keyBinds != null)
            {
                Dictionary<ActionCode, KeyCode> keyBinds_tmp = new Dictionary<ActionCode, KeyCode>();
                foreach (KeyValuePair<ActionCode, KeyCode> bind in keyBinds)
                {
                    KeyCode val = (bind.Key == ActionCode.Escape) ? bind.Value : KeyCode.None;
                    keyBinds_tmp.Add(bind.Key, val);
                }
                keyBinds = keyBinds_tmp;
            }
        }

        // =================================================================================================

    }
}
