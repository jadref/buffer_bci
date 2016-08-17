using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using DT.InputManagement;
using UnityEngine.UI;

/*
 * Script to control PLayer Movement
 * 
 * 
 */
public class BasicMovement : MonoBehaviour {
    // Use this for initialization
    void Start () {  
    }
	
	// Update is called once per frame
	void Update () {
        // Get the vector components and scale them to set a certain speed.
        var xRot = GetYRotation() * Time.deltaTime * 50.0f;
        var z = GetZAxis() * Time.deltaTime * 3.0f;
        var y = GetYAxis() * Time.deltaTime * 3.0f;
        var x = GetXAxis() * Time.deltaTime * 3.0f;

        // Move the Player along these vectors.
        transform.Rotate(0, xRot, 0);
        transform.Translate(x, y, z);
	}

    // Get the x component. If you use Keyboard controls:
    // move right if the received key matches the one stored in the key Dictionary under MoveRight
    // move left if the received key matches the one stored in the key Dictionary under MoveLeft 
    private float GetXAxis()
    {
        if (SelectManager.XLockBool || SelectManager.BCIXBool)
        {
            return 0;
        }
        if (Input.GetKey(KeyManager.keys["MoveRight"]))
        {
            GameManager.currentAction = "Right";
            return 1;
        }
        if (Input.GetKey(KeyManager.keys["MoveLeft"]))
        {
            GameManager.currentAction = "Left";
            return -1;
        }
        else return 0;
    }
    // Get the y component. If you use Keyboard controls:
    // move up if the received key matches the one stored in the key Dictionary under MoveUp
    // move down if the received key matches the one stored in the key Dictionary under MoveDown 
    private float GetYAxis()
    {
        if (SelectManager.YLockBool || SelectManager.BCIYBool)
        {
            return 0;
        }
        if (Input.GetKey(KeyManager.keys["MoveUp"]))
        {
            GameManager.currentAction = "Up";
            return 1;
        }
        if (Input.GetKey(KeyManager.keys["MoveDown"]))
        {
            GameManager.currentAction = "Down";
            return -1;
        }
        else return 0;
    }

    // Get the z component. If you use Keyboard controls:
    // move Forward if the received key matches the one stored in the key Dictionary under MoveForward
    // move Backward if the received key matches the one stored in the key Dictionary under MoveBackward
    private float GetZAxis()
    {
        if (SelectManager.ZLockBool || SelectManager.BCIZBool)
        {
            return 0;
        }
        if (Input.GetKey(KeyManager.keys["MoveForward"]))
        {
            GameManager.currentAction = "Forward";
            return 1;
        }
        if (Input.GetKey(KeyManager.keys["MoveBackward"]))
       {
            GameManager.currentAction = "Backward";
            return -1;
        }
        else return 0;
        
    }

    // Get the y rotation component, turns you on the horizontal plane. If you use Keyboard controls:
    // turn right if the received key matches the one stored in the key Dictionary under TurnRight
    // turn left if the received key matches the one stored in the key Dictionary under TurnLeft
    private float GetYRotation()
    {
        if (SelectManager.RotLockBool || SelectManager.BCIRotBool)
        {
            return 0;
        }
        if (Input.GetKey(KeyManager.keys["TurnRight"]))
        {
            GameManager.currentAction = "Right Turn";
            return 1;
        }
        if (Input.GetKey(KeyManager.keys["TurnLeft"]))
        {
            GameManager.currentAction = "Left Turn";
            return -1;
        }
        else return 0;
    }
    
    // If the object to which this script is connected (The player) hits something
    // and that something is a target it will deactive the target and sign the GameManager. 
    void OnTriggerEnter(Collider other)
    {
        if (other.transform.tag == "Target")
        {
            GameManager.Instance.TargetHit();
            other.gameObject.SetActive(false);
        }
    }
}
