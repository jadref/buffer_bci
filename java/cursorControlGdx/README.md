cursorControlGDX
====================

This is a simple stimulus based experiment built using the GDX framework and the [buffer_bci](https://github.com/jadref/buffer_bci) project for input.

Graphics are handled by the [GDX library](http://libgdx.badlogicgames.com).

Installation
============

As with other GDX based systems this project uses [Gradle](http://www.gradle.org/) to automate the build process for the various target platforms (desktop,android,iOS and HTML).  If not already installed Gradle and all libGDX dependencies will be automatically downloaded and installed when you first try to build this project.

To build with [Eclipse](www.eclipse.org), NetBeans or Intellij IDEA follow the instructions [here](https://github.com/libgdx/libgdx/wiki/Setting-up-your-Development-Environment-%28Eclipse%2C-Intellij-IDEA%2C-NetBeans%29) and then for Eclipse [here](https://github.com/libgdx/libgdx/wiki/Gradle-and-Eclipse).

To build form the command-line use:
`./gradlew platform:command` for example to build the desktop version `./gradlew desktop:build` or to run the desktop version `./gradlew desktop:run`.
