using System;
using System.Runtime.InteropServices;

namespace SensorySwitchMessages
{
    public enum SwitchState
    {
        Pressed,
        Released,
    }

    public class SwitchMessages
    {
        private const UInt32 SWITCH_PRESSED = 1;
        private const UInt32 SWITCH_RELEASED = 0;
        private const string WM_SENSORY_SWITCHINPUT = "Sensory_SwitchInput";
        private const UInt32 HWND_BROADCAST = 0xffff;

        private readonly UInt32 _wmSensorySwitchInput;

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern UInt32 RegisterWindowMessage(string lpProcName);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern bool SendNotifyMessage(UInt32 hWnd, UInt32 Msg, UInt32 wParam,
           UInt32 lParam);

        public SwitchMessages()
        {
            _wmSensorySwitchInput = RegisterWindowMessage(WM_SENSORY_SWITCHINPUT);
        }

        public void SetSwitchState(uint switchId, SwitchState switchState)
        {
            uint lParam = (switchState == SwitchState.Pressed) ? SWITCH_PRESSED : SWITCH_RELEASED;
            if (_wmSensorySwitchInput != 0)
                SendNotifyMessage(HWND_BROADCAST, _wmSensorySwitchInput, switchId, lParam);
        }

    }
}
