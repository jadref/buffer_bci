using UnityEngine;
using UnityEngine.UI;
using System.Collections;

/*
 * Script to manage everything on the Profile(Extra) Canvas
 * 
 * 
 */
public class ProfileManager : MonoBehaviour {
    public Dropdown ProfileDropdown;
    public Dropdown ControlSelectDropdown;
    public InputField ProfileInputField;
    public ArrayList profiles = new ArrayList();
    public Toggle usingBCIToggle;
    public Text TimeLabel;
    public Text NameLabel;
    public Text GamesLabel;
    public Text ScoreLabel;
    public static string selectedProfile;
    public static string selectedControl;
    public static string usingBCI;
    private string[] modeNames = { "Full Control", "Turning", "Up/Down", "Forward", "Forward + Up/Down", "Forward + Turning", "Turning + Up/Down", "Forward + Turning + Up/Down" };


    // Use this for initialization
    void Start() {
        // Add profiles that are stored
        int j = 0;
        PlayerPrefs.SetString("profile0", "Default");
        PlayerPrefs.SetString("profile1", "TestDrive");
        while (PlayerPrefs.HasKey("profile" + j))
        {
            profiles.Add(PlayerPrefs.GetString("profile" + j));
            j++;
        }
        addProfiles();
        ProfileDropdown.value = profiles.IndexOf(PlayerPrefs.GetString("selectedProfile"));

        //Construct dropdown and add lisitner for Control Mode dropdown.
        for (int i = 0; i < modeNames.Length; i++)
        {
            ControlSelectDropdown.options.Add(new Dropdown.OptionData(modeNames[i]));
        }
        ControlSelectDropdown.onValueChanged.AddListener(delegate { OnControlSelectDropdownChange(); });
        ControlSelectDropdown.value = 0;
        ControlSelectDropdown.captionText.text = modeNames[ControlSelectDropdown.value];
        selectedControl = "Control" + ControlSelectDropdown.value.ToString();

        // Add Listener for Using BCI Toggle
        usingBCIToggle.onValueChanged.AddListener(delegate { OnUsingBCIToggle(); });

        // Set Profile Statistics
        setStatistics();
    }

    // Update is called once per frame
    void Update () {
	
	}

    // Reconstructs the profile Dropdown
    public void addProfiles()
    {
        ProfileDropdown.options.Clear();
        for(int i = 0; i < profiles.Count; i++)
        {   
            ProfileDropdown.options.Add(new Dropdown.OptionData(profiles[i].ToString())); 
        }
        ProfileDropdown.onValueChanged.AddListener(delegate { OnProfileChange(); });
    }

    // Creates a new profile according to the Input text
    public void createProfile()
    {
        if (!profiles.Contains(ProfileInputField.text))
        {
            PlayerPrefs.SetString("profile" + profiles.Count.ToString(), ProfileInputField.text);
            profiles.Add(ProfileInputField.text);  
        }
        addProfiles();
        ProfileDropdown.value = profiles.Count - 1;
        ProfileDropdown.captionText.text = profiles[profiles.Count -1].ToString();
    }


    // Set the values in the profile window.
    public void setStatistics()
    {
        TimeLabel.text = string.Format("{0:0.0}",PlayerPrefs.GetFloat(selectedProfile + usingBCI + selectedControl + "Time"));
        GamesLabel.text = PlayerPrefs.GetInt(selectedProfile + usingBCI + selectedControl + "Games").ToString();
        ScoreLabel.text = PlayerPrefs.GetInt(selectedProfile + usingBCI + selectedControl + "Score").ToString();
    }

    // Deletes the profile that is currently selected
    
    public void deleteProfile()
    {
        PlayerPrefs.DeleteKey("profile" + (profiles.IndexOf(ProfileDropdown.captionText.text)));
        profiles.Remove(ProfileDropdown.captionText.text);
        addProfiles();
        ProfileDropdown.value = 0;
        ProfileDropdown.captionText.text = profiles[0].ToString();
    }

    // Returns the selected Profile
    public static string getSelectedProfile()
    {
        return selectedProfile;
    }

    /*------- Listeners -------*/
    public void OnProfileChange()
    {
        selectedProfile = ProfileDropdown.captionText.text;
        PlayerPrefs.SetString("selectedProfile", selectedProfile);
        setStatistics();
        NameLabel.text = selectedProfile;

    }

    public void OnControlSelectDropdownChange()
    {
        selectedControl = "Control"+ControlSelectDropdown.value.ToString();
        PlayerPrefs.SetString("selectedControl", selectedControl);
        setStatistics();

    }

    public void OnUsingBCIToggle()
    {
        if (usingBCIToggle.isOn)
        {
            usingBCI = "BCI";
        }
        else
        {
            usingBCI = "";
        }
        PlayerPrefs.SetString("usingBCI", usingBCI);
        setStatistics();
    }
}
