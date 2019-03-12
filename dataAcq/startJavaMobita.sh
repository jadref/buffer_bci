#!/bin/bash
cd `dirname "${BASH_SOURCE[0]}"`
java -cp buffer/java/Mobita2ft.jar:buffer/java/BufferClient.jar Mobita2ft.Mobita2ft $@
