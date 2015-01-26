echo Building: javaclient
javac -classpath ../../dataAcq/buffer/java/BufferClient.jar javaclient.java
echo Building: eventViewer
javac -classpath ../../dataAcq/buffer/java/BufferClient.jar eventViewer.java
cp eventViewer.class ../../dataAcq/buffer/java
echo Building: syncGenerator
javac -classpath ../../dataAcq/buffer/java/BufferClient.jar syncGenerator.java
echo Building: filePlayback
cp filePlayback.class ../../dataAcq/buffer/java
javac -classpath ../../dataAcq/buffer/java/BufferClient.jar filePlayback.java
cp syncGenerator.class ../../dataAcq/buffer/java
