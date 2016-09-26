# Dependencies # 
IMPORTANT: This is only a small part of the buffer_bci framework. For all dependencies and related code, go to https://github.com/jadref/buffer_bci
 
# Packaging # 
The ApproachAvoidNFTraining.apk file is created with Unity. Open this project and choose File>Build Settings in Unity 5 and select the Android Platform and click Build. The main scene is used for the app, two other scenes are included for testing purposes. 

# How To #
Start the App, power on the Muse. Tap connect, which will boot the FieldTripServerService and FieldTripClientService and attempt to connect with the Muse. Once the connection is established, you can start the training. During the training phase, the player will have to try and control the ball with brainpower. Color of the ball will signal badness (green = good, red/orange = bad), color of the tunnel will signal channel quality (neutral = good, red = bad).

# Config #
In the folder Assets>Scripts there's a Config.cs file for quick access to some of the parameters.

IMPORTANT: This is only a small part of the buffer_bci framework. For all dependencies and related code, go to https://github.com/jadref/buffer_bci

