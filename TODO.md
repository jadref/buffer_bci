Bugs
====
[] Fix layout of channel plots when capfile is invalid...
[] Refactor matlab code into the matlab sub-directory

Basic buffer integeration
=========================
[] - Add async put_dat, put_evt, and wait_dat, methods to the java buffer client
[x] - audio2ft driver for testing

Platform/Language support
=========================
[] - Python support
  [X] - Pyschopy Examples
  [X] - Python based signal processing code  (partial implementation)
  [] - Python based signal viewer
[] - Android support
  [X] - Buffers server/clients applications
  [X] - Java based signal analysis routines
  [X] - Unity examples
  [X] - Raw-android examples
[] - Open Sound Control
  [X] - OSC2ft, osc messages to data
  [] - osc2evt, osc messages into buffer events
  [] - evt2osc, buffer events into osc messages (for sound/video integeration)

Demo BCIs
=========
[] - Simple (induced) Neuro-feedback example
[] - Finish ssep example
  [] - brain-test ssep example
[] - Finish cursor example
  [] - build 1-d & 2-d neurofeedback training system
  [] - brain-test cursor example
[] - Neurofeedback
  [] - add NF parameter setting GUI, i.e. freq range, and spatial filter
[] - sigViwer
	[] -- add sonification
[] - ERP Viewer
  [] - add a moving average mode to the ERP viewer
  [] - add a spatial filter and new layout
  [] - add spatial filter selection GUI


Signal Analysis
===============
[] - pre-proc apply methods
[] - Rationalize the pre-proc, train, and apply methods to reduce code duplication
[x] - AUC plots work with pre-specified sub-problems
[x] - c-based, java-based and python-based signal proxies
  [x] - fix the c-sig proxy so runs a the correct data rate
[x] - universum-SVM classifier support
[] - second order baseline adaptive sig-processing support in classifier
[] - convert demos to use string event values when possible to improve readability
[] - OSC2FT add the channel names when sending the header
[x] - Validate the 50Hz power as a bad-channel indicator.  
  [] - Add channel offset mode to sigViewer

Documentation
=============
[] - Documentation
