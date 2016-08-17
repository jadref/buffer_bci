using UnityEngine;
using System.Collections;

/*
 * This script can be used to attach the DontDestroyOnLoad functions to gameObjects
 * DontDestoryOnLoad preserves the GameObject when switching Scenes. 
 */

public class DontDestroyOnLoad : MonoBehaviour {

	// Use this for initialization
	void Start () {
        DontDestroyOnLoad(gameObject);
    }
	
	// Update is called once per frame
	void Update () {
	
	}
}
