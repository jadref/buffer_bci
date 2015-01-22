set batdir=%~dp0
echo Starting : %batdir%\buffer\java\syncGenerator
java -cp buffer\java\BufferClient.jar:buffer/java syncGenerator localhost:1972 localhost:1973
