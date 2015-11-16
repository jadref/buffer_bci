# README #

The FieldtripServerService creates an Android  service (with no activity) that starts, stops and controls a Fieltrip buffer server. 

The FieldtripClientsService creates an Android service (with no activity) that starts, stops and  controls a number of Fieltrip buffer clients. More clients can be added as classes, extensions of ThreadBase.
The FieldtripServerService and FieldtripClientService are designed to communicate with the FieldtripBufferServicesController through Intents.

Versions:
Android Studio 1.0.1 or Intellij 14, 
Unity 5.0.1, 
Android API targeted 21, minimum 16

The Fieldtrip Server and Clients Services are self contained Android studio projects. They should be installed to the developing Android device. Services don't provide a GUI so don't expect a application to pop up, they will run in the background (through the FieldtripBufferServicesController). The FieldTripClientService depends on the MatrixAlgebra library, just import the MatrixAlgebra.jar file. 
