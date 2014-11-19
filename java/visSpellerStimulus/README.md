Visual-Speller-Stimulus
=======================

Stimulus presentation for a visual speller, created using the libGDX framework.

So far only contains a proof of concept stimulus presentation in order to test performance.

Graphics are handled by the [GDX library](http://libgdx.badlogicgames.com).

Installation
============

As with other GDX based systems this project uses [Gradle](http://www.gradle.org/) to automate the build process for the various target platforms (desktop,android,iOS and HTML).  If not already installed Gradle and all libGDX dependencies will be automatically downloaded and installed when you first try to build this project.

To build with [Eclipse](www.eclipse.org), NetBeans or Intellij IDEA follow the instructions [here](https://github.com/libgdx/libgdx/wiki/Setting-up-your-Development-Environment-%28Eclipse%2C-Intellij-IDEA%2C-NetBeans%29) and then for Eclipse [here](https://github.com/libgdx/libgdx/wiki/Gradle-and-Eclipse).


Definition
==========

Based on [jadref's matrixSpeller](https://github.com/jadref/buffer_bci/tree/master/matrixSpeller).

```
Training:
	Send event stimulus.training with value start
	Show grid in gray 2000 ms

	Sequence repeat 5 times:
		Send event stimulus.sequence with value start
		send event stimulus.targetSymbol with value of target
		Show target symbol in green 2000 ms

		Stimulus repeat 5 times for each column and row:
			Show grid in gray 150 ms
			Send event stimulus.rowFlash with value of flashed row
			Send event stimulus.columnFlash with value of flashed column
			Send event stimulus.tgtFlash with true if row/column contains target
			Flash column/rows white 150 ms

		Send event stimulus.sequence with value end

	send event stimulus.training with value end

Feedback:
	Send event stimulus.feedback with value start
	Show grid in gray 2000 ms

	Sequence repeat X times:
		Send event stimulus.sequence with value start

		Stimulus repeat 5 times for each column and row:
			Show grid in gray 150 ms
			Send event stimulus.rowFlash with value of flashed row
			Send event stimulus.columnFlash with value of flashed column
			Flash column/rows white 150 ms
		
		Show grid grey 950 ms (waiting for the classifier)
		Send event stimulus.sequence with value end
		
		Get new classifier events.
		Correlate classifier events with flash sequence to determine prediction symbol.
		Send event stimulus.prediction with value of prediction symbol.
		Show prediction symbol in red 5000 ms
		
	send event stimulus.feed with value end
```

State Diagram
=============

![Program/Experiment state diagram](./master/doc/program_states.png)


Project Directory Layout
========================

This project follows the standard libGDX/Gradle directory layout. 

settings.gradle            <- definition of sub-modules. By default core, desktop, android, html, ios
build.gradle               <- main Gradle build file, defines dependencies and plugins
gradlew                    <- script that will run Gradle on Unix systems
gradlew.bat                <- script that will run Gradle on Windows
gradle                     <- local gradle wrapper
local.properties           <- Intellij only file, defines android sdk location

core/
    build.gradle           <- Gradle build file for core project*
    src/                   <- Source folder for all your game's code

desktop/
    build.gradle           <- Gradle build file for desktop project*
    src/                   <- Source folder for your desktop project, contains Lwjgl launcher class

android/
    build.gradle           <- Gradle build file for android project*
    AndroidManifest.xml    <- Android specific config
    assets/                <- contains for your graphics, audio, etc.  Shared with other projects.
    res/                   <- contains icons for your app and other resources
    src/                   <- Source folder for your Android project, contains android launcher class

html/
    build.gradle           <- Gradle build file for the html project*
    src/                   <- Source folder for your html project, contains launcher and html definition
    webapp/                <- War template, on generation the contents are copied to war. Contains startup url index page and web.xml


ios/
    build.gradle           <- Gradle build file for the ios project*
    src/                   <- Source folder for your ios project, contains launcher
