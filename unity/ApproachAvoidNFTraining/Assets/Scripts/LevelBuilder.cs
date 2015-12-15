using UnityEngine;
using System.Collections;

public class LevelBuilder : MonoBehaviour {

	public GameObject tunnelPrefab;
	public GameObject tunnelContainer;

	bool isInitialized;

	// Use this for initialization
	void Awake () {
		// Should already be initialized from the menu, but just in case.
		initialize ();
	}

	// Update is called once per frame
	void Update () {

	}

	public void initialize(){
		if (!isInitialized) {
			for (int i=0; i<8; ++i) {
				GameObject newSection = Instantiate (tunnelPrefab, new Vector3 (0, 0, i * 4f), Quaternion.identity) as GameObject;
				newSection.transform.parent = tunnelContainer.transform;
			}
			isInitialized = true;
		}
	}
}
