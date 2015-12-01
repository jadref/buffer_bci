using UnityEngine;
using System.Collections;

public class Rest : MonoBehaviour {

	public MenuOptions menu;
	public Transform fixationCross;
	public float frequency = 0.5f;
	public float amplitude = 0.5f;

	private static float duration;
	private float startTime = 0f;
	private Transform trans;

	// Iinitialization
	void Awake ()
	{
		duration = (float)Config.restInterval;
		frequency = 1f / frequency;
	}

	// when made visible
	void OnEnable(){
		startTime = Time.time;
	}

	// Update is called once per frame
	void Update ()
	{
		if (gameObject.activeSelf)
		{
			float pulse = 0.5f + amplitude * (Mathf.PingPong (Time.time, frequency) / frequency);
			fixationCross.localScale = new Vector3(pulse, pulse, 0f);

			if ((Time.time - startTime) >= duration)
			{
				gameObject.SetActive (false);
				menu.nextStage();
			}
		}
	}
}
