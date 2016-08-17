using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using DT.InputManagement;
using UnityEngine.UI;
/*
 * Script to controL BCI movement
 * 
 * 
 */
public class BCIMovement : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}

    // Update is called once per frame
    void Update()
    {
        // Get the vector components and scale them to set a certain speed.
        var xRot = GetYRotation() * Time.deltaTime * 50.0f;
        var z = GetZAxis() * Time.deltaTime * 3.0f;
        var y = GetYAxis() * Time.deltaTime * 3.0f;
        var x = GetXAxis() * Time.deltaTime * 3.0f;

        // Move the Player along these vectors.
        transform.Rotate(0, xRot, 0);
        transform.Translate(x, y, z);
       
    }

    // Get the x component. If you use BCI controls:
    // move right if the received event matches either the keyboard event or the classifier prediction index for going right.
    // move left if the received event matches either the keyboard event or the classifier prediction index for going left.
    // Control is determined by the key and class setup in the Options menu. 
    private float GetXAxis()
    {
        if (!SelectManager.BCIXBool)
        {
            return 0;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveRight"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Rclass) 
        {
            GameManager.currentAction = "Right";
            return 1;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveLeft"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Lclass)
        {
            GameManager.currentAction = "Left";
            return -1;
        }
        else return 0;
    }

    // Get the y component. If you use BCI controls:
    // move up if the received event matches either the keyboard event or the classifier prediction index for going up.
    // move down if the received event matches either the keyboard event or the classifier prediction index for going down.
    // Control is determined by the key and class setup in the Options menu. 
    private float GetYAxis()
    {
        if (!SelectManager.BCIYBool)
        {
            return 0;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveUp"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Uclass)
        {
            GameManager.currentAction = "Up";
            return 1;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveDown"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Dclass)
        {
            GameManager.currentAction = "Down";
            return -1;
        }
        else return 0;
    }

    // Get the z component. If you use BCI controls:
    // move forward if the received event matches either the keyboard event or the classifier prediction index for going forward.
    // move backward if the received event matches either the keyboard event or the classifier prediction index for going backward.
    // Control is determined by the key and class setup in the Options menu. 
    private float GetZAxis()
    {

        ;
        if (!SelectManager.BCIZBool)
        {
            return 0;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveForward"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Fclass)
        {
            GameManager.currentAction = "Forward";
            return 1;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["MoveBackward"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.Bclass)
        {
            GameManager.currentAction = "Backward";
            return -1;
        }
        else return 0;

    }

    // Get the y rotation component. If you use BCI controls:
    // turn right if the received event matches either the keyboard event or the classifier prediction index for going right.
    // turn left if the received event matches either the keyboard event or the classifier prediction index for going left.
    // Control is determined by the key and class setup in the Options menu. 
    private float GetYRotation()
    {
        if (!SelectManager.BCIRotBool)
        {
            return 0;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["TurnRight"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.TRclass)
        {
            GameManager.currentAction = "Right Turn";
            return 1;
        }
        if (string.Compare(BufferManager.currentBCIAction, KeyManager.keys["TurnLeft"].ToString(), true) == 0 || BufferManager.highestPredictionindex == SettingManager.TLclass)
        {
            GameManager.currentAction = "Left Turn";
            return -1;
        }
        else return 0;
    }
}
