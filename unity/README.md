# README #

 * Desktop: Start a background buffer+acquisation-driver+signal_processer as use for BCIs, e.g. by running [`debug_quickstart.bat`](../debug_quickstart.bat).
 * Android: Install the [BufferBCIApp](../dataAcq/buffer/android/BufferBCIApp), this will auto-start all the bits you need (buffer, hardware drivers, signal-analysis clients etc.) when requested at run-time.

There is then a unity application which runs the User interface and communicates with the BufferBCIApp to start the various components
