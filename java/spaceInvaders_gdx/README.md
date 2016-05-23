BufferBCI_SpaceInvaders
====================

Invaders is a simplistic 3D space invaders clone, using the [buffer_bci](https://github.com/jadref/buffer_bci) project for input.

### Setup
* Import project into IntelliJ IDEA
* Wait for all gradle dependencies to be pulled (can take a while)
* Add BufferClient.jar to the core subproject module settings

### Running
* Run buffer_bci buffer and dataAcq.
* Run FakeController C# project (sends controller input into the buffer).
* Run DesktopLauncher.main() method.
* Click inside the window to start the game.
* Use Q to press fake fire button and W to release fake fire button
* Use E to push the fake X-axis stick more to the left, R to push it more to the right. (a threshold exists)
