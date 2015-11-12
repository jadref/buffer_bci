using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class SliderEvent : MonoBehaviour {

	public Text sliderValue;
	public Slider slider;
	public bool showValue = false;

	private int value;

	public void onSlider() {
		if (showValue) {
			sliderValue.text = slider.value.ToString ();
		}
	}
}
