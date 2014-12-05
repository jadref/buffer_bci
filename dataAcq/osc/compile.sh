#javac -source 1.5 -target 1.5 -classpath ../buffer/java/Buffer.jar com/illposed/osc/utility/*.java com/illposed/osc/*.java osc2ft.java
javac -source 1.5 -target 1.5 -classpath ../buffer/java/BufferClient.jar:./JavaOSC.jar osc2ft.java
# to run use:
#java -cp ../dataAcq/buffer/java/Buffer.jar:.:JavaOSC.jar osc2ft /data:777
