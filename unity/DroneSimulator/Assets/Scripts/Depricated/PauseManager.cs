using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;


public class PauseManager : MonoBehaviour
{
    private GameObject pauseCanvas;

    void Awake()
    {
        pauseCanvas = GameObject.Find("PauseCanvas");
    }
    // Use this for initialization
    void Start()
    {

        pauseCanvas.SetActive(false);
    }

    // Update is called once per frame
    void Update()
    {

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
    void OnGUI()
    {
        if (pauseCanvas != null)
        {
            if (Time.timeScale == 0)
            {
                pauseCanvas.SetActive(true);
            }
        }
    }

    public void ReturnToMain()
    {
        Time.timeScale = 1;
        SceneManager.LoadScene(0);
    }
}
