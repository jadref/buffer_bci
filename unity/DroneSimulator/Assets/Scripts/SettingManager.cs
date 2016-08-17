using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using DT.InputManagement;
using System;
/*
 * Script to Manage everything related to the Options Canvas. 
 * Except the Keybuttons which are managed by the KeyManager.
 * 
 */

public class SettingManager : MonoBehaviour {

    public Dropdown resolutionDropdown;
    public Dropdown qualityDropdown;
    public Dropdown MoveForwardDropdown, MoveBackwardDropdown, MoveLeftDropdown, MoveRightDropdown, MoveUpDropdown, MoveDownDropdown, TurnLeftDropdown, TurnRightDropdown;
    public static int Fclass, Bclass, Lclass, Rclass, Uclass, Dclass, TLclass, TRclass;
    public Toggle fullscreenToggle;
    public Resolution[] resolutions;
    public string[] qualitynames;
    private string[] classNames = { "Class1", "Class2", "Class3", "Class4", "Class5", "Class6", "Class7", "Class8" };

	// Use this for initialization
	void Start () {
        // Add Listener for full screen Toggle
        fullscreenToggle.onValueChanged.AddListener(delegate { OnFullScreenToggle(); });
        fullscreenToggle.isOn = PlayerPrefs.GetInt("FullScreen") == 1 ? true : false;

        // Construct dropdown and add listener for Quality Dropdown.
        qualitynames = QualitySettings.names;
        for (int i = 0; i < qualitynames.Length; i++)
        {
            qualityDropdown.options.Add(new Dropdown.OptionData(qualitynames[i]));
        }
        qualityDropdown.onValueChanged.AddListener(delegate { OnQualityChange(); });
        qualityDropdown.value = PlayerPrefs.GetInt("Quality");

        // Construct dropdown and add listener for Resolution Dropdown
        resolutions = Screen.resolutions;
        for (int i = 0; i < resolutions.Length; i++)
        {
            resolutionDropdown.options.Add(new Dropdown.OptionData(ResToString(resolutions[i])));
        }
        resolutionDropdown.onValueChanged.AddListener(delegate { OnResolutionChange(); }); 
        resolutionDropdown.value = PlayerPrefs.GetInt("Resolution");

        // Construct Dropdowns to enable user to select which action is which class. 
        for (int i = 0; i < classNames.Length; i++)
        {
            MoveForwardDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            MoveBackwardDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            MoveUpDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            MoveDownDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            MoveLeftDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            MoveRightDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            TurnLeftDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
            TurnRightDropdown.options.Add(new Dropdown.OptionData(classNames[i]));
        }
        
        // Add listeners to class dropdowns.
        MoveForwardDropdown.onValueChanged.AddListener(delegate { OnForwardClassChange(); });
        MoveBackwardDropdown.onValueChanged.AddListener(delegate { OnBackwardClassChange(); });
        MoveUpDropdown.onValueChanged.AddListener(delegate { OnUpClassChange(); });
        MoveDownDropdown.onValueChanged.AddListener(delegate { OnDownClassChange(); });
        MoveLeftDropdown.onValueChanged.AddListener(delegate { OnLeftClassChange(); });
        MoveRightDropdown.onValueChanged.AddListener(delegate { OnRightClassChange(); });
        TurnLeftDropdown.onValueChanged.AddListener(delegate { OnTurnLeftClassChange(); });
        TurnRightDropdown.onValueChanged.AddListener(delegate { OnTurnRightClassChange(); });

        // Initialize class dropdowns. 
        MoveForwardDropdown.value = 0; MoveForwardDropdown.captionText.text = classNames[0];
        MoveBackwardDropdown.value = 1;
        MoveUpDropdown.value = 2;
        MoveDownDropdown.value = 3;
        MoveLeftDropdown.value = 4;
        MoveRightDropdown.value = 5;
        TurnLeftDropdown.value = 6;
        TurnRightDropdown.value = 7;
    }

    // Format resolution names
    string ResToString(Resolution res)
    {
        return res.width + " x " + res.height;
    }

    // Update is called once per frame
    void Update () {
       
	}
    

    /*------- Listeners -------*/
    // Set and store resolution
    public void OnResolutionChange()
    {
        PlayerPrefs.SetInt("Resolution", resolutionDropdown.value);
        Screen.SetResolution(resolutions[resolutionDropdown.value].width, resolutions[resolutionDropdown.value].height, fullscreenToggle.isOn);
        PlayerPrefs.Save();
    }

    // Set and store fullscreen/windowed boolean.
    public void OnFullScreenToggle()
    {
        PlayerPrefs.SetInt("Fullscreen", fullscreenToggle.isOn ? 1:0 ) ;
        Screen.fullScreen = fullscreenToggle.isOn;
        PlayerPrefs.Save();
    }

    // Set and store Quality.
    public void OnQualityChange()
    {
        PlayerPrefs.SetInt("Quality", qualityDropdown.value);
        QualitySettings.SetQualityLevel(qualityDropdown.value,true);
      
        PlayerPrefs.Save();
    }

    //Store which class the forward action is
    public void OnForwardClassChange()
    {
        Fclass = MoveForwardDropdown.value;
    }

    //Store which class the backward action is
    public void OnBackwardClassChange()
    {
        Bclass = MoveBackwardDropdown.value;
    }

    //Store which class the up action is
    public void OnUpClassChange()
    {
        Uclass = MoveUpDropdown.value;
    }

    //Store which class the down action is
    public void OnDownClassChange()
    {
        Dclass = MoveDownDropdown.value;
    }

    //Store which class the left action is
    public void OnLeftClassChange()
    {
        Lclass = MoveLeftDropdown.value;
    }

    //Store which class the right action is
    public void OnRightClassChange()
    {
        Rclass = MoveRightDropdown.value;
    }

    //Store which class the turn left action is
    public void OnTurnLeftClassChange()
    {
        TLclass = TurnLeftDropdown.value;
    }

    //Store which class the turn right action is
    public void OnTurnRightClassChange()
    {
        TRclass = TurnRightDropdown.value;
    }
}
