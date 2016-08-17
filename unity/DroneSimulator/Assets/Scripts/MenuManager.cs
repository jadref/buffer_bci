using UnityEngine;
using System.Collections;
using UnityEngine.SceneManagement;
/*
 * This Script Manages the Main menu and all the canvas transfers.
 * 
 * 
 */
public class MenuManager : MonoBehaviour {
    private GameObject mainCanvas, optionsCanvas, extraCanvas, selectCanvas;
    // Find all the Canvases 
    void Awake()
    {
        mainCanvas = GameObject.Find("MainCanvas");
        optionsCanvas = GameObject.Find("OptionsCanvas");
        extraCanvas = GameObject.Find("ExtraCanvas");
        selectCanvas = GameObject.Find("SelectCanvas");
    }

    // If the game was paused make sure to restart time and open on the main Canvas.
    void Start()
    {
        Time.timeScale = 1;
        mainCanvas.SetActive(true);
        optionsCanvas.SetActive(false);
        extraCanvas.SetActive(false);
        selectCanvas.SetActive(false);
    }

    void Update()
    {
    }

    //Load the Options Canvas
    public void LoadOptions()
    {
        mainCanvas.SetActive(false);
        optionsCanvas.SetActive(true);
        extraCanvas.SetActive(false);
        selectCanvas.SetActive(false);
    }

    // Load the Profile/Extra Canvas
    public void LoadExtra()
    {
        mainCanvas.SetActive(false);
        optionsCanvas.SetActive(false);
        extraCanvas.SetActive(true);
        selectCanvas.SetActive(false);

    }

    // Load the Main Canvas
    public void LoadMain()
    {
        mainCanvas.SetActive(true);
        optionsCanvas.SetActive(false);
        extraCanvas.SetActive(false);
        selectCanvas.SetActive(false);
    }

    // Load the Select Canvas
    public void LoadSelect()
    {
        mainCanvas.SetActive(false);
        optionsCanvas.SetActive(false);
        extraCanvas.SetActive(false);
        selectCanvas.SetActive(true);
    }

    // Load the Scene you want
    public void LoadScene(int level)
    {
        SceneManager.LoadScene(level);
    }

    // Exit the Game
    public void exitGame()
    {
        Application.Quit();
    }
}
