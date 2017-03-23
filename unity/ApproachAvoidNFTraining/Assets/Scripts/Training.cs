using UnityEngine;
using System.Collections;

public class Training : MonoBehaviour {

	public FieldtripServicesInterfaceMain FTSInterface;
	public MenuOptions menu;
	public GameObject ball;
	public GameObject tunnelPrefab;
	public GameObject tunnelContainer;
	public UnityEngine.UI.Text TrnSampEvent;
	public float smoothTime = 0.3f;
	public float turningRate = 100f;
	private float MINZPOS = 2f; // closest allowed position
	private float MAXZPOS = 15f; //furthest allowed position

	private float startTime = 0f;
	private Vector3 velocity = Vector3.zero;
	private bool isInitialized = false;

	private static float duration;
	private float alpha;
	private float alphaLatAvg = 0f;
	private int avgSamples = 1;
	private float badness;

	Renderer ballRenderMan;
	SkinnedMeshRenderer skinnedMeshRenderMan;
	Mesh skinnedMesh;

	Renderer[] tunnelRenderMans;


	// Initialization
	void Start ()
	{
		duration = (float)Config.trainingDuration;

		//skinnedMeshRenderMan = GetComponent<SkinnedMeshRenderer> ();
		//skinnedMesh = GetComponent<SkinnedMeshRenderer> ().sharedMesh;
	}

	// when made visible
	void OnEnable(){
		startTime = Time.time;
		ballRenderMan = ball.GetComponent<Renderer> ();
		ballRenderMan.material.SetFloat ("_Blend", 0);

		if (!isInitialized) {
			Initialize();
		}
	}

	// Update is called once per frame
	void Update ()
	{
		if (gameObject.activeSelf && FTSInterface.systemIsReady())
		{
			if ((Time.time-startTime) >= duration)
			{
				gameObject.SetActive (false);

				// Log session score and reset for performance sake
				// menu.logScore((float)alphaLatAvg);
				// alphaLatAvg = 0;
				// avgSamples = 1;

				menu.nextStage();
			}

			//TrnSampEvent.text = FTSInterface.getCurrentSampleNumber() + "/" + FTSInterface.getCurrentEventsNumber() + " (samp/evt)";

			// Tunnel rotation
			tunnelContainer.transform.Rotate (0, 0.02f, 0);

			// AlphaLat to Movement
			alpha = (float)FTSInterface.getAlpha();

			float currentPosZ = ball.transform.position[2];
			// Ensure 0=middle of the range and scale by alphaLIM
			float targetPosZ = (MINZPOS+MAXZPOS)/2 + -alpha/Config.alphaLimit*(MAXZPOS-MINZPOS);
			// limit range of Z pos
			targetPosZ=Mathf.Min(Mathf.Max(targetPosZ,MINZPOS),MAXZPOS);

			float targetRotX = turningRate * (targetPosZ - currentPosZ) / (2f * Mathf.PI * 0.5f);

			Vector3 targetPosition = new Vector3(0, 0, targetPosZ);
			ball.transform.position = Vector3.SmoothDamp(ball.transform.position, targetPosition, ref velocity, smoothTime);
			ball.transform.Rotate (targetRotX, 0, 0);

			/*
			// AlphaLat Rolling average to Ball Color
			alphaLatAvg = (alphaLatAvg * avgSamples + alpha) / (avgSamples + 1);
			avgSamples += 1;
			//Debug.Log (alphaLatAvg);

			float targetBlend = 0.5f + (alpha - alphaLatAvg)/Config.alphaLimit;
			float ballBlend = Mathf.Min(Mathf.Max(targetBlend,0f),1f);

			ballRenderMan.material.SetFloat ("_Blend", ballBlend);
			//skinnedMeshRenderMan.SetBlendShapeWeight (0, value * 100f);
			*/

			// Badness to Tunnel color
			float b = (float)FTSInterface.getBadness();
			// smooth badness to make it visible for longer
			if ( Config.badnessFilter>0 ) {
				badness = Config.badnessFilter * b + (1-Config.badnessFilter)*badness;
			} else {
				badness = b;
			}
			float badColor = Mathf.Max(0,badness-Config.badnessThreshold); // > .5 = bad
			badColor = Mathf.Min(badColor,Config.badnessLimit) / Config.badnessLimit; // 3 is max badness, linear between

			for (int i=0; i < tunnelRenderMans.Length; ++i) {
				tunnelRenderMans[i].material.SetFloat ("_Blend", badColor);
			}
		}
	}

	public void Initialize ()
	{
		if (!isInitialized) {
			int sections = 8;
			tunnelRenderMans = new Renderer[sections];
			for (int i=0; i<sections; ++i) {
				GameObject newSection = Instantiate (tunnelPrefab, new Vector3 (0, 0, i * 4f), Quaternion.identity) as GameObject;
				newSection.transform.parent = tunnelContainer.transform;
				tunnelRenderMans [i] = newSection.transform.GetComponent<Renderer>();
				tunnelRenderMans [i].material.SetFloat ("_Blend", 1);
			}
			isInitialized = true;
		}
	}
}
