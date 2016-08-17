using UnityEngine;
using UnityEngine.UI;
using System.Collections;
/*
 * This Script Manages the Select Canvas
 * 
 * 
 */
public class SelectManager : MonoBehaviour {

    public Dropdown selectDropdown;
    public Dropdown XDropdown, YDropdown, ZDropdown, RotDropdown;
    public Toggle usingBCIToggle;
    public static bool XLockBool, YLockBool, ZLockBool, RotLockBool;
    public static bool BCIRotBool, BCIYBool, BCIXBool, BCIZBool;
    private string[] modeNames = { "Full Control", "Turning", "Up/Down", "Forward", "Forward + Up/Down", "Forward + Turning", "Turning + Up/Down", "Forward + Turning + Up/Down" };
    private string[] controlNames = { "Keyboard", "BCI", "Autopilot" };
    private string[] xNames = { "Keyboard", "Inactive" };
    private string usingBCI;

	// Use this for initialization
	void Start () {

        // Construct the Control Preset Select Dropdown
        for (int i = 0; i < modeNames.Length; i++)
        {
            selectDropdown.options.Add(new Dropdown.OptionData(modeNames[i]));
        }
        selectDropdown.onValueChanged.AddListener(delegate { OnSelectDropdownChange(); });
        selectDropdown.value = 0;

        // Construct the Custom Control Select Dropdowns.
        for (int i = 0; i < controlNames.Length; i++)
        {
            RotDropdown.options.Add(new Dropdown.OptionData(controlNames[i]));
            YDropdown.options.Add(new Dropdown.OptionData(controlNames[i]));
            ZDropdown.options.Add(new Dropdown.OptionData(controlNames[i]));
        }
        RotDropdown.onValueChanged.AddListener(delegate { OnRotDropdownChange(); });
        YDropdown.onValueChanged.AddListener(delegate { OnYDropdownChange(); });
        ZDropdown.onValueChanged.AddListener(delegate { OnZDropdownChange(); });

        //Construct the X Control Dropdown, since it is more limited than the other Dropdowns.
        XDropdown.options.Add(new Dropdown.OptionData("Keyboard"));
        XDropdown.options.Add(new Dropdown.OptionData("Inactive"));
        XDropdown.onValueChanged.AddListener(delegate { OnXDropdownChange(); });

        // Add a listener to the Using BCI Toggle
        usingBCIToggle.onValueChanged.AddListener(delegate { OnBCIToggle(); });

        
        // Reset Booleans
        XLockBool = false;
        YLockBool = false;
        ZLockBool = false;
        RotLockBool = false;
        BCIRotBool = false;
        BCIXBool = false;
        BCIYBool = false;
        BCIZBool = false;
    }
	
	// Update is called once per frame
	void Update () {
        //Update the Dropdown texts
        selectDropdown.captionText.text = modeNames[selectDropdown.value];
        XDropdown.captionText.text = xNames[XDropdown.value];
        YDropdown.captionText.text = controlNames[YDropdown.value];
        ZDropdown.captionText.text = controlNames[ZDropdown.value];
        RotDropdown.captionText.text = controlNames[RotDropdown.value];
    }

    /*------- Listeners -------*/
    // Set Rotation movement Bools according to Dropdown Value
    public void OnRotDropdownChange()
    {
        if (RotDropdown.value == 0)
        {
            BCIRotBool = false;
            RotLockBool = false;
        }
        if (RotDropdown.value == 1)
        {
            BCIRotBool = true;
            RotLockBool = false;
        }
        if(RotDropdown.value == 2)
        {
            BCIRotBool = false;
            RotLockBool = true;
        }
    }

    // Set Y movement Bools according to Dropdown Value
    public void OnYDropdownChange()
    {
        if (YDropdown.value == 0)
        {
            BCIYBool = false;
            YLockBool = false;
        }
        if (YDropdown.value == 1)
        {
            BCIYBool = true;
            YLockBool = false;
        }
        if (YDropdown.value == 2)
        {
            BCIYBool = false;
            YLockBool = true;
        }
    }

    // Set Z movement Bools according to Dropdown Value
    public void OnZDropdownChange()
    {
        if (ZDropdown.value == 0)
        {
            BCIZBool = false;
            ZLockBool = false;
        }
        if (ZDropdown.value == 1)
        {
            BCIZBool = true;
            ZLockBool = false;
        }
        if (ZDropdown.value == 2)
        {
            BCIZBool = false;
            ZLockBool = true;
        }
    }

    // Set X movement Bools according to Dropdown Value
    public void OnXDropdownChange()
    {
        if(XDropdown.value == 0)
        {
            XLockBool = false;
        }
        if(XDropdown.value == 1)
        {
            XLockBool = true;
        }
    }

    // Set public static string so everything knows if you use a BCI
    public void OnBCIToggle()
    {
        if (usingBCIToggle.isOn)
        {
            usingBCI = "BCI";
        }
        else
        {
            usingBCI = "";
        }
        ProfileManager.usingBCI = usingBCI;
        OnSelectDropdownChange();
    }

    // Complex Switch that sests all Control Axis Dropdowns according to a certain preset. 
    public void OnSelectDropdownChange()
    {
        int caseIndex = selectDropdown.value;
        ProfileManager.selectedControl = "Control"+selectDropdown.value.ToString();
        switch (caseIndex)
        {
            case 1:
                
                XDropdown.value = 1; YDropdown.value = 2; ZDropdown.value = 2;
                if (usingBCIToggle.isOn){
                    RotDropdown.value = 1;
                }
                else{
                    RotDropdown.value = 0;
                }     
                break;
            case 2:
                
                XDropdown.value = 1;  ZDropdown.value = 2; RotDropdown.value = 2;
                if (usingBCIToggle.isOn)
                {
                    YDropdown.value = 1;
                }
                else
                {
                    YDropdown.value = 0;
                }
                break;
            case 3:
                
                XDropdown.value = 1;  YDropdown.value = 2; RotDropdown.value = 2;
                if (usingBCIToggle.isOn)
                {
                    ZDropdown.value = 1;
                }
                else
                {
                    ZDropdown.value = 0;
                }
                break;
            case 4:
                
                XDropdown.value = 1;  RotDropdown.value = 2;
                if (usingBCIToggle.isOn)
                {
                    YDropdown.value = 1; ZDropdown.value = 1;
                }
                else
                {
                    YDropdown.value = 0; ZDropdown.value = 0;
                }
                break;
            case 5:
                
                XDropdown.value = 1;   YDropdown.value = 2;
                if (usingBCIToggle.isOn)
                {
                    ZDropdown.value = 1; RotDropdown.value = 1;
                }
                else
                {
                    ZDropdown.value = 0; RotDropdown.value = 0;
                }
                break;
            case 6:
               
                XDropdown.value = 1;  ZDropdown.value = 2; 
                if (usingBCIToggle.isOn)
                {
                    YDropdown.value = 1; RotDropdown.value = 1;
                }
                else
                {
                    YDropdown.value = 0; RotDropdown.value = 0;
                }
                break;
            case 7:
                
                XDropdown.value = 1; 
                if (usingBCIToggle.isOn)
                {
                    YDropdown.value = 1; ZDropdown.value = 1; RotDropdown.value = 1;
                }
                else
                {
                    YDropdown.value = 0; ZDropdown.value = 0; RotDropdown.value = 0;
                }
                break;
            default:
               
                if (usingBCIToggle.isOn)
                {
                    XDropdown.value = 1; YDropdown.value = 1; ZDropdown.value = 1; RotDropdown.value = 1;
                }
                else
                {
                    XDropdown.value = 0; YDropdown.value = 0; ZDropdown.value = 0; RotDropdown.value = 0;
                }
                
                break;
        }
    }
}
