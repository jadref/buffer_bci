using UnityEngine;
using System.Collections;


/*
 * This script manages the Autopilot features of the drone.
 * Moves the drone on an Axis when the drone is locked out of that Axis
 * Allows for users to control only the desired Axis. 
 */
public class AutoPilot : MonoBehaviour {
    // Variable Definitions
    public GameObject Player;
    public GameObject T0, T1, T2, T3, T4, T5, T6, T7, T8, T9;
    public GameObject[] TargetList;

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
        Player.transform.Rotate(0, xRot, 0);
        Player.transform.Translate(x, y, z);
    }

    // Get the x component. Not critical for the Autopilot, so set to always return 0.
    private float GetXAxis()
    {
        if (SelectManager.XLockBool)
        {
            return 0;
        }

        else return 0;
    }

    //Get the y component. If closest target is higher, move up. if closest target is lower, move down. 
    //Otherwise don't move.
    private float GetYAxis()
    {
        if (SelectManager.YLockBool)
        {
            if (Player.transform.position.y < getClosestTarget().transform.position.y - 0.1)
            {
                return 1;
            }
            if (Player.transform.position.y > getClosestTarget().transform.position.y + 0.1)
            {
                return -1;
            }
            else return 0;
        }

        else return 0;
    }

    //Get the z component. Always move forward, backwards not usefull for Autopilot. 
    private float GetZAxis()
    {
        if (SelectManager.ZLockBool)
        {
           return 1;
        }

        else return 0;

    }

    //Get the Y rotation component, Turns you on the horizontal plane. Uses LookRotation to determine how far to turn for the closest target
    // Uses Slerp to gradually turn towards the target. 
    private float GetYRotation()
    {
        if (SelectManager.RotLockBool)
        {

            var newRotation = Quaternion.LookRotation(getClosestTarget().transform.position - Player.transform.position);
            newRotation.z = 0.0f;
            newRotation.x = 0.0f;
            Player.transform.rotation = Quaternion.Slerp(Player.transform.rotation, newRotation, Time.deltaTime * 3);
            
            
            return 0;
        }
        else return 0;
    }

    // Get the closest Target. Of all the targets that are still active, calculate the distance
    // Returns the closest Target. 
    private GameObject getClosestTarget()
    {
        TargetList = GameObject.FindGameObjectsWithTag("Target");
        float shortestDistance = 1000;
        GameObject closestTarget = new GameObject();
        for (int i = 0; i < TargetList.Length; i++)
        {
            if (Vector3.Distance(Player.transform.position, TargetList[i].transform.position) < shortestDistance)
            {
                closestTarget = TargetList[i];
                shortestDistance = Vector3.Distance(Player.transform.position, TargetList[i].transform.position);
            }
        }
        return closestTarget;
    }
}
