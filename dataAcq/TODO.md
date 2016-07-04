
###Notes: TMSi mobita {mobita}
This device uses wifi to connect between the computer and the amplifier.  When recording data this connection *cannot* be disconnected.  Unfortunately, most OSs currently have a wifi auto-scan system which will periodically scan for 'better' wifi networks.  This scanning will interrupt data sending and cause the connection to be temporally lost for 1-3seconds.   To prevent this you need to prevent wifi auto-scanning, how this is done differs depending on OS.
* Linux: on most current linux wifi is managed by NetworkManager.  By stopping this process from running you can prevent wifi auto-scanning.  Do this by: `killall -STOP NetworkManager`.  To resume auto-scanning use: `killall -CONT NetworkManager`
* Windows: to stop network scanning follow the instructions [here](http://answers.microsoft.com/en-us/windows/forum/windows_7-networking/how-to-disable-automatic-scanning-for-wifi/4c8253ec-40c6-42c8-a9f7-00d78fce966c).


###Notes: Linux 64-bit
Currently this system comes only with 32-bit linux binary executables in the
`dataAcq\buffer\glnx86` directory.  These depend on the 32-bit version of the
standard libraries and thus will not work on 64-bit systems which do not have
these libaries installed.   Fortunately these libaries are easy to install on
modern linux systems.  Exactly how will vary depending on the distribution,
however on Ubuntu you should take the following steps:

1) *Do not* install `ia32-libs` as this is no longer uspported.   Instead
install the 3 packages: `lib32z1` `lib32ncurses5` `lib32bz2-1.0`

2) Add all the additional information for the 32-bit architecture using:
`sudo dpkg --add-architecture i386`

3) (Optional) For Emotiv Epoc support using *emokit* reinstall `mcrypt` as `mcrypt:i386`
