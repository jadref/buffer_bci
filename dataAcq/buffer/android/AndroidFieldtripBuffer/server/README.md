AndroidFieldtripBuffer
======================

An Android implementation of the Fieldtrip buffer, based on the [JavaFieldTripBuffer](https://github.com/Wieke/JavaFieldtripBuffer).

Development
=============

Set the development environment up as follows:

1. Set up eclipse with the following:
	- EGit
	- Android Development Tools
	- Android SDK 4.4W (API Level 20)
	- Android Support libraries
2. Import the project in this repository using EGit.
3. Import the [JavaFieldtripBuffer](https://github.com/Wieke/JavaFieldtripBuffer) project using EGit.
4. Import the appcompat_v7 project from <SDKPATH>/extras/android/support/v7/appcompat.
5. If the android project has build issues check the following:
	- FieldtripBuffer > Properties > Android should have appcompat_v7 as a project library (the path may be incorrect, if so remove and add it).
	- FieldtripBuffer > Properties > Java Build Path > Projects should contain the JavaFieldtripBuffer project.
	- FieldtripBuffer > Properties > Java Build Path > Order and Export should have ticked the box in front of the JavaFieldtripBuffer project.

Plan
==================

- [x] Create a service activity
	- [x] Ensure it keeps running even if the launcher app has been closed/destroyed
	- [ ] Apply performance optimizations to JavaFieldtripBuffer
	- [x] Add the wakelocks.
- [x] Create a launcher app.
	- [x] Start Buffer activity with portNumber and buffer size fields.
	- [x] Show/check if buffer is already running.
- [x] Optional stuff: add some basic monitoring things.
	- [x] Uptime
	- [x] Number of open connections
		- [x] List of open connections
			- [x] Last time of activity of each connection
	- [x] Number of samples
	- [x] Number of events
	- [x] Basic Header information (dataType, number of channels, sampling frequency
		- [x] Channel names
	- [ ] List of last X events
	- [ ] List of last X samples
- [x] Fix wait monitor bug.