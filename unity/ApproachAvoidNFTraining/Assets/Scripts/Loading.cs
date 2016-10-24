using UnityEngine;
using System.Collections;

public class Loading : MonoBehaviour {

	public GameObject Spinner;
	public GameObject LoadingButton;

	// Set on start
	void onEnable() {
		Spinner.SetActive (true);
		LoadingButton.SetActive (false);
	}

	// Update is called once per frame
	void Update () {
		if (gameObject.activeSelf && !LoadingButton.activeSelf)
		{
			Spinner.transform.Rotate(Vector3.forward, -200 * Time.deltaTime);
		}
	}
}
