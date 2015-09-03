# README #

These are three Android Studio and one Unity project.

The UnityFieldtripServicesController is a Unity Android project that can be used as a base to create other Untiy Android projects which can control the FieldtripBufferServices. It also incorporates a Fieldtrip Buffer client (written in C#) which allows a Unity project to instantiate its own client and read and write from and to the Fieldtrip Buffer Server running on the device.   

The FieldtripBufferServicesController is an Android project designed to be a plugin to Unity. It allows communication with the FieldtripServerService and the FieldtripClientsService and exposes a number of functions that can be used to do this communication.

The FieldtripServerService creates an Android  service (with no activity) that starts, stops and controls a Fieltrip buffer server. 

The FieldtripClientsService creates an Android service (with no activity) that starts, stops and  controls a number of Fieltrip buffer clients. More clients can be added as classes, extensions of ThreadBase.

The FieldtripServerService and FieldtripClientService are designed to communicate with the FieldtripBufferServicesController through Intents.

The MatrixAlgebra provides a wrapper around the Commons Math (all Java) library. 

Versions:
Android Studio 1.0.1 or Intellij 14, 
Unity 5.0.1, 
Android API targeted 21, minimum 16


### How do I set it up? ###
Unity Android plugins work only on actual devices so a developing device must be used.

In a Unity project with the required Plugins/Android files setup one needs the FieldtripServicesControlerInterface.cs script which exposes the interface that the plugin provides to the Server and the Clients Services.

The UnityFieldtripBufferServicesController project gives an example of this setup and also provides a simple GUI that can be used to control the Server and the Clients.
To change Unity project, simply open it with Unity 5. 

The FieldtripServicesController Android studio is meant to create a .jar file that is then added in a Unity project and should not be installed itself on a device. After any changes to its code go with a terminal to the directory that its gradlew file is (Wherever_you_put_the_code/FieldtripBufferServiceController/gradlew) and run gradlew makeJar (in Windows you probably need to run gradlew.bat makeJar). The makeJar function can be found in the project's build.gradle file (in the app module). It generates a jar file of all the .class files of the project and puts it in FieldtripBufferServiceController/app/build/libs. This jar needs to be copied to the Unity project's Assets/Plugins/Android directory, together with the AndroidManifest.xml file and the res directory of the Android Studio project. After any code changes a new jar must be made and copied over, after any manifest changes the AndroidManifest.xml file must be copied over and after any changes in the res files the new res folder should be copied over.

The Fieldtrip Server and Clients Services are self contained Android studio projects. They should be installed to the developing Android device. Services don't provide a GUI so don't expect a application to pop up, they will run in the background once they are started by the Unity project (through the FieldtripBufferServicesController). The FieldTripClientService depends on the MatrixAlgebra library, just import the MatrixAlgebra.jar file. 

To add new threads with the Unity app, one needs to add a ThreadBase class to the edu.nl.ru.fieldtripclientservice.threads.ThreadList.
