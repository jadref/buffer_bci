using UnityEngine;
using System.Collections;

public class Training : MonoBehaviour {

	public FieldtripServicesInterfaceMain FTSInterface;
	public MenuOptions menu;
	public GameObject ball;
	public GameObject tunnelPrefab;
	public GameObject tunnelContainer;
	public float smoothTime = 0.3f;
	public float turningRate = 100f;

	private float time = 0f;
	private Vector3 velocity = Vector3.zero;
	private bool isInitialized = false;

	private static float duration;

	Renderer ballRenderMan;
	SkinnedMeshRenderer skinnedMeshRenderMan;
	Mesh skinnedMesh;

	Renderer[] tunnelRenderMen;


	// Initialization
	void Start ()
	{
		duration = (float)Config.trainingInterval;
		ballRenderMan = ball.GetComponent<Renderer> ();
		ballRenderMan.material.SetFloat ("_Blend", 0);

		if (!isInitialized) {
			Initialize();
		}

		//skinnedMeshRenderMan = GetComponent<SkinnedMeshRenderer> ();
		//skinnedMesh = GetComponent<SkinnedMeshRenderer> ().sharedMesh;
	}

	// Update is called once per frame
	void Update ()
	{
		if (gameObject.activeSelf)
		{
			time += Time.deltaTime;
			if (time >= duration)
			{
				time = 0f;
				gameObject.SetActive (false);
				menu.EndTraining();
				menu.LoadRest();
			}

			// Tunnel rotation
			tunnelContainer.transform.Rotate (0, 0.02f, 0);

			// AlphaLat to Movement
			float a = (float)FTSInterface.getAlpha();

			float currentPosZ = ball.transform.position[2];
			float targetPosZ = 11f + -a*10f;
			float targetRotX = turningRate * (targetPosZ - currentPosZ) / (2f * Mathf.PI * 0.5f);

			Vector3 targetPosition = new Vector3(0, 0, targetPosZ);
			ball.transform.position = Vector3.SmoothDamp(ball.transform.position, targetPosition, ref velocity, smoothTime);
			ball.transform.Rotate (targetRotX, 0, 0);

			// Badness to Ball Color
			float b = (float)FTSInterface.getBadness();

			ballRenderMan.material.SetFloat ("_Blend", b);
			//skinnedMeshRenderMan.SetBlendShapeWeight (0, value * 100f);

			// Channel quality to tunnel Color
			float c1 = (float)FTSInterface.getQualityCh1();
			float c2 = (float)FTSInterface.getQualityCh2();

			float cmax = Mathf.Max (c1,c2);

			for (int i=0; i < tunnelRenderMen.Length; ++i) {
				tunnelRenderMen[i].material.SetFloat ("_Blend", cmax);
			}
		}
	}

	public void Initialize ()
	{
		if (!isInitialized) {
			int sections = 8;
			tunnelRenderMen = new Renderer[sections];
			for (int i=0; i<sections; ++i) {
				GameObject newSection = Instantiate (tunnelPrefab, new Vector3 (0, 0, i * 4f), Quaternion.identity) as GameObject;
				newSection.transform.parent = tunnelContainer.transform;
				tunnelRenderMen [i] = newSection.transform.GetComponent<Renderer>();
				tunnelRenderMen [i].material.SetFloat ("_Blend", 1);
			}
			isInitialized = true;
		}
	}
}
