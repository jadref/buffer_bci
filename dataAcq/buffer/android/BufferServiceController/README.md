# Introduction #

This project is a stand-alone version of the BufferServiceController from the BufferBCIApp.  It provides and example implementation of an application which can interact with the buffer server and clients services provided by the BufferBCIApp.  As such you can integerate it into your own applications if you want to directly control the start-up of the server and which clients should run, e.g. to start the server, then and acquistation device, and then a signal processor.  Such that the user only sees one 'application' running.

This code is also used to package up a .jar to be imported into the Unity buffer bci example on Android for this purpose.

# Dependencies #
This project depends on:
- The BufferClient.jar from the BufferBCI project (https://github.com/jadref/buffer_bci/tree/master/dataAcq/buffer/java)

