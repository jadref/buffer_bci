using UnityEngine;
using System.Collections;

public class Rest : MonoBehaviour {

	public MenuOptions menu;
	public Transform fixationCross;
	public float frequency = 0.5f;
	public float amplitude = 0.5f;

	private static float duration;
	private static int sessions;

	private bool preMeasure = true;
	private bool firstSession = true;
	private float t = 0f;
	private Transform trans;

	// Iinitialization
	void Awake ()
	{
		duration = (float)Config.restInterval;
		sessions = (int)Config.trainingBlocks;
		frequency = 1f / frequency;
	}

	// Update is called once per frame
	void Update ()
	{
		if (gameObject.activeSelf)
		{
			t += Time.deltaTime;
			float pulse = 0.5f + amplitude * (Mathf.PingPong (Time.time, frequency) / frequency);
			fixationCross.localScale = new Vector3(pulse, pulse, 0f);

			if (t >= duration)
			{
				t = 0f;
				gameObject.SetActive (false);

				if (preMeasure)
				{
					preMeasure = false;
					menu.EndRestBaseline();
				}
				else if (sessions > 0)
				{
					sessions -= 1;
					menu.EndRest ();
					if (firstSession)
					{
						firstSession = false;
						menu.LoadTrainingIntro ();
					}
					else
					{
						menu.LoadTraining();
					}
				}
				else {
					menu.Disconnect(true);

					if ((bool)Config.questionaire)
					{
						menu.LoadQuestionPage(1);
					}
					else if ((bool)Config.evaluation)
					{
						menu.LoadEvaluationPage();
					}
					else
					{
						menu.LoadStartMenu();
					}
				}
			}
		}
	}
}
