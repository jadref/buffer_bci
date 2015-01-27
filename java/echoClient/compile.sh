echo Note: limiting java version for max compatability with JRE's
echo Building: javaclient
javac -target 1.4 -source 1.4 -classpath ../../dataAcq/buffer/java/BufferClient.jar javaclient.java
echo Building: eventViewer
javac -target 1.4 -source 1.4 -classpath ../../dataAcq/buffer/java/BufferClient.jar eventViewer.java
cp eventViewer.class ../../dataAcq/buffer/java
echo Building: syncGenerator
javac -target 1.5 -source 1.5 -classpath ../../dataAcq/buffer/java/BufferClient.jar syncGenerator.java
echo Building: filePlayback
cp filePlayback.class ../../dataAcq/buffer/java
javac -target 1.5 -source 1.5 -classpath ../../dataAcq/buffer/java/BufferClient.jar filePlayback.java
cp syncGenerator.class ../../dataAcq/buffer/java
