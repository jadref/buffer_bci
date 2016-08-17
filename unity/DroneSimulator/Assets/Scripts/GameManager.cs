using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;
using UnityEngine.UI;
/*
 * This Script Manages the Game States
 * 
 */
public class GameManager : MonoBehaviour {
    public static int currentScore;
    public static int currentLevel = 0;
    public static int unlockedLevel;
    public static GameManager Instance;

    public float startTime;
    public string currentTime;
    public static string currentAction;
    public int numTargets;
    public int maxTargets;
    public bool gameStarted, gameVictory;
    public Text timer, targets, action;

    private GameObject GameOverText, GameOverButton, VictoryText, VictoryButton, StartText;
    private GameObject pauseCanvas;
    public GameObject Player;
    public GameObject T0, T1, T2, T3, T4, T5, T6, T7, T8, T9;
    


    void Awake()
    {
        GameOverText = GameObject.Find("GameOverText");
        GameOverButton = GameObject.Find("GameOverButton");
        pauseCanvas = GameObject.Find("PauseCanvas");
        VictoryText = GameObject.Find("VictoryText");
        VictoryButton = GameObject.Find("VictoryButton");
        StartText = GameObject.Find("StartText");
        Instance = this;
    }

    // Use this for initialization
    void Start()
    {
        // Initialize game values. 
        gameStarted = false;
        gameVictory = false;
        numTargets = 10;
        startTime = 0;
        currentAction = "None";
        Time.timeScale = 1;

        //Set Player position and angle
        Player.transform.position = new Vector3(5, 5, -5); Player.transform.eulerAngles = new Vector3(0, 0, 0);

        // Display start Text, deactivate the rest.
        GameOverText.SetActive(false);
        GameOverButton.SetActive(false);
        pauseCanvas.SetActive(false);
        VictoryText.SetActive(false);
        VictoryButton.SetActive(false);
        StartText.SetActive(true);
    }
    /*
    public static void CompleteLevel()
    {
        currentLevel += 1;
        SceneManager.LoadScene(currentLevel);
    }

    public void LoadScene(int scene)
    {
        SceneManager.LoadScene(scene);
    }
    */
    // If a Target has been hit, Start the game if it is the first one, deduct targets until zero. 
    public void TargetHit()
    {
        if (numTargets == 10)
        {
            startTime = 60;
            gameStarted = true;
            PlayerPrefs.SetInt(getPlayerPrefsPath() + "Games", PlayerPrefs.GetInt(getPlayerPrefsPath() + "Games") + 1);
            StartText.SetActive(false);
        }
        if (numTargets > 0)
        {
            numTargets -= 1;
        }
        if( numTargets == 0)
        {
           Victory();
        }
    }

    // If number of targets is zero the game is a Victory.
    // The best time and score gets stored and victory text displayed.
    public void Victory()
    {
        if (startTime > PlayerPrefs.GetFloat(getPlayerPrefsPath() + "Time"))
        {
            PlayerPrefs.SetFloat(getPlayerPrefsPath() + "Time", startTime);
        }
        if (10 - numTargets > PlayerPrefs.GetInt(getPlayerPrefsPath() + "Score"))
        {
            PlayerPrefs.SetInt(getPlayerPrefsPath() + "Score", 10 - numTargets);
        }
        gameVictory = true;
        GameOverText.SetActive(false);
        GameOverButton.SetActive(false);
        VictoryText.SetActive(true);
        VictoryButton.SetActive(true);
        StartText.SetActive(false);
        Time.timeScale = 0;
    }



    // Update is called once per frame
    //Update the time, if the time is up. Store the scores and display appropriate text.
    // Also check if the game needs to be pauzed
    void Update()
    {
        if (!(startTime <= 0))
        {
            startTime -= Time.deltaTime;
        }
        currentTime = string.Format("{0:0.0}", startTime);
        
        if (startTime <= 0 && gameStarted)
        {
            startTime = 0;
            if (startTime > PlayerPrefs.GetFloat(getPlayerPrefsPath() + "Time"))
            {
                PlayerPrefs.SetFloat(getPlayerPrefsPath() + "Time", startTime);
            }
            if (10 - numTargets > PlayerPrefs.GetInt(getPlayerPrefsPath() + "Score"))
            {
                PlayerPrefs.SetInt(getPlayerPrefsPath() + "Score", 10 - numTargets);
            }
            
            GameOverButton.SetActive(true);
            GameOverText.SetActive(true);
            
            Time.timeScale = 0;
            
        }

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            print("escape pressed");
            if (Time.timeScale == 0)
            {
                Time.timeScale = 1;
                pauseCanvas.SetActive(false);
              
                
            }
            else
            {
                Time.timeScale = 0;
                print("Pauzed");
            }
        }

    }

    //Updates Gui elements.
    void OnGUI()
    {
        
        if (timer != null) { 
        timer.text = currentTime;
        }
        targets.text = numTargets.ToString();
        action.text = currentAction;
        if (pauseCanvas != null)
        {
            if (Time.timeScale == 0 && (startTime > 0 || !gameStarted) && !gameVictory)
            {
                pauseCanvas.SetActive(true);
            }
        }
    }

    // Get the pathname to store the game values.
    private string getPlayerPrefsPath()
    {
        return (ProfileManager.selectedProfile + ProfileManager.usingBCI + ProfileManager.selectedControl);
    }

    // Return o the main menu. 
    public void ReturnToMain()
    {
        Time.timeScale = 1;
        SceneManager.LoadScene(0);
        
    }

}
