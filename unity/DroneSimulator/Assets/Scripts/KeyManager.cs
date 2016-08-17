using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;

/*
 * Script that manages the key dictionary.  
 * keys in the dictionary can be changed through the options menu
 */
public class KeyManager : MonoBehaviour {

    public static Dictionary<string, KeyCode> keys = new Dictionary<string, KeyCode>();
    public Text forward, backward, up, down, left, right, turnleft, turnright;
    private GameObject currentKey;
 
    // Use this for initialization
	void Start () {
        // Create elements in dictionary as is currently stored. 
        keys.Clear();
        keys.Add("MoveForward", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveForward","W")));
        keys.Add("MoveBackward", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveBackward", "S")));
        keys.Add("MoveUp", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveUp", "Space")));
        keys.Add("MoveDown", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveDown", "LeftShift")));
        keys.Add("MoveLeft", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveLeft", "Q")));
        keys.Add("MoveRight", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("MoveRight", "E")));
        keys.Add("TurnLeft", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("TurnLeft", "A")));
        keys.Add("TurnRight", (KeyCode)System.Enum.Parse(typeof(KeyCode), PlayerPrefs.GetString("TurnRight", "D")));
        
        // Display the keys on the buttons.
        forward.text = keys["MoveForward"].ToString();
        backward.text = keys["MoveBackward"].ToString();
        up.text = keys["MoveUp"].ToString();
        down.text = keys["MoveDown"].ToString();
        left.text = keys["MoveLeft"].ToString();
        right.text = keys["MoveRight"].ToString();
        turnleft.text = keys["TurnLeft"].ToString();
        turnright.text = keys["TurnRight"].ToString();

    }
	
	// Update is called once per frame
	void Update () {
	
	}
    // Similar to the Update function. 
    // Waits for keypresses.
    void OnGUI()
    {
        if (currentKey != null)
        {
            Event e = Event.current;
            if (e.isKey)
            {
                keys[currentKey.name] = e.keyCode;
                currentKey.transform.GetChild(0).GetComponent<Text>().text = e.keyCode.ToString();
             //   currentKey.GetComponent<Image>().color = normal;
                currentKey = null;
                SaveKeys();
            }
        }
    }

    //Change the key of the clicked button
    public void ChangeKey(GameObject clicked)
    {
        currentKey = clicked;
    }

    // Store the keys 
    public void SaveKeys()
    {
        foreach( var key in keys)
        {
            PlayerPrefs.SetString(key.Key, key.Value.ToString());
        }
        PlayerPrefs.Save();
    }
}
