using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class QualityCheck : MonoBehaviour {

    public FieldtripServicesInterfaceMain FTSInterface;
    public Text QualityText;
    public Image QualityIndicatorL;
    public Image QualityIndicatorR;
    public Button AdvanceButton;
	public Text	SampEvent;
	public Text QualityL;
	public Text QualityR;

    private bool isEnabled = false;
    private bool curQualityStatusAllChannels = false;
    private int[] curQualityDuration = new int[] { 0, 0, 0 }; // first value is for timeout, the rest for channels
    private float avgQualityAllChannels = 0f;
    private int avgQualitySamples = 1;

    private float activeTreshold;
    private float rollingTreshold;
    private float badLimit;
	private float disconnectLimit;

    private Color themeGreen = new Color32(0x55, 0xAD, 0x5A, 0xFF);
    private Color themeRed = new Color32(0xAD, 0x34, 0x48, 0xFF);
    private Color themeOrange = new Color32(0xE0, 0xB1, 0x14, 0xFF);

    // Use this for initialization
    void Start () {
        setCalibration(false);
        QualityText.text = Config.qualityText;
        QualityIndicatorL.color = themeRed;
        QualityIndicatorR.color = themeRed;
		AdvanceButton.interactable = true;
		#if UNITY_ANDROID && !UNITY_EDITOR
			AdvanceButton.interactable = false;
		#endif
    }

    private bool CheckChannel(float value, int channel, Image indicator) {
        bool channelIsGood = false;
        bool codeOrange = false;

		if (value < activeTreshold && value > Config.qualityThresholdDisconnected) //Sometimes it takes a second for values to come in, will be 0 until then, so let's mark that as bad.
        {
            curQualityDuration[channel]++;
            if (curQualityDuration[channel] < Config.qualitySamplesRequired)
            {
                codeOrange = true;
            }
            else
            {
                channelIsGood = true;
            }
        }
        else
        {
            // channelIsGood and codeOrange remain false
            curQualityDuration[channel] = 0;
        }

        // QualityPanel

        if (QualityIndicatorL.IsActive()) {
            if (channelIsGood) { indicator.color = themeGreen; }
            else {
                if (codeOrange) {
                    float blendOrange = (1 / Config.qualitySamplesRequired) * curQualityDuration[channel];
                    indicator.color = Color32.Lerp(themeOrange,themeGreen, blendOrange);
                }
                else {
                    float blendBad = (1/Config.qualityLimitBadUncal) * (value - activeTreshold);
                    indicator.color = Color32.Lerp(themeOrange, themeRed, blendBad);
                }
            }
        }

        return channelIsGood;

    }

	// Update is called once per frame
	void Update () {
		if (isEnabled && FTSInterface.systemIsReady()) {
			SampEvent.text = FTSInterface.getCurrentSampleNumber() + "/" + FTSInterface.getCurrentEventsNumber() + " (samp/evt)";

            float qualityCh1 = FTSInterface.getQualityCh1();
			QualityL.text = qualityCh1.ToString("0.00");
            float qualityCh2 = FTSInterface.getQualityCh2();
			QualityR.text = qualityCh2.ToString("0.00");

            // Judge current quality
            bool channel1Good = CheckChannel(qualityCh1, 1, QualityIndicatorL);
            bool channel2Good = CheckChannel(qualityCh2, 2, QualityIndicatorR);

            if (channel1Good && channel2Good) {
                curQualityDuration[0] = 0;
                AdvanceButton.interactable = true;
                curQualityStatusAllChannels = true;
            }
            else {
                if (curQualityStatusAllChannels) {
                    curQualityDuration[0]++;
                    //allow for brief drop in quality
                    if (curQualityDuration[0] > Config.qualityTimeOut) {
                        AdvanceButton.interactable = false;
                        curQualityStatusAllChannels = false;
                    }
                }
            }

            // Calculate rolling average
            float channelsAvg = (qualityCh1 + qualityCh2) / 2.0f;

            avgQualityAllChannels = (channelsAvg + avgQualityAllChannels * avgQualitySamples) / (avgQualitySamples + 1);
            avgQualitySamples++;

            //Debug.Log("Q1=" + qualityCh1.ToString() + ", Q2=" + qualityCh2.ToString() + ", QA=" + avgQualityAllChannels.ToString());
        }
    }

    public bool getCurrentQualityStatus() {
        return curQualityStatusAllChannels;
    }

    public bool getAvgQualityStatus() {
		if (avgQualityAllChannels < rollingTreshold && avgQualityAllChannels > disconnectLimit) {
            // quality is good
            return true;
        }
        else {
            return false;
        }
    }

    public void enable(bool status) {
        isEnabled = status;
    }

    public void setCalibration(bool status) { // use raw-predictions so no-need to worry about calibrated/uncalibrated....
        // toggle between raw threshold and corrected threshold
//        if (status) {
//            activeTreshold = Config.qualityThresholdActiveCal;
//            rollingTreshold = Config.qualityThresholdRollingCal;
//            badLimit = Config.qualityLimitBadCal;
//			disconnectLimit = Config.qualityThresholdDisconnectedCal;
//        }
//        else {
            activeTreshold = Config.qualityThresholdActiveUncal;
            rollingTreshold = Config.qualityThresholdRollingUncal;
            badLimit = Config.qualityLimitBadUncal;
			disconnectLimit = Config.qualityThresholdDisconnected;
//        }
    }

    public void resetAverage() {
        avgQualityAllChannels = 0f;
        avgQualitySamples = 1;
    }
}
