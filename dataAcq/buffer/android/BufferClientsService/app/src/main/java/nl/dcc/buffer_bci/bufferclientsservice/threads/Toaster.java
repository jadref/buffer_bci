package nl.dcc.buffer_bci.bufferclientsservice.threads;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.Header;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

import java.io.IOException;
import java.io.PrintWriter;

public class Toaster extends ThreadBase {
    private final BufferClient client = new BufferClient();

    /**
     * Connects to the buffer
     */
    protected Header connect(String hostname, int port) {
        Header header=null;
        while (header == null && run) {
            try {
                System.out.println( "Connecting to " + hostname + ":" + port);
                if ( !client.isConnected() ) {
                    client.connect(hostname, port);
                }
                //C.setAutoReconnect(true);
                if (client.isConnected()) {
                    header = client.getHeader();
                }
            } catch (IOException e) {
                header = null;
            }
            if (header == null) {
                System.out.println( "Invalid Header... waiting");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    run=false;
                }
            }
        }
        return header;
    }

    /**
     * Is used by the androidHandle app to determine what kind of arguments the thread
     * requires.
     */
    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[7];

        /**
         * Declares a string argument, presented as simple text field. This one
         * is gong to be parsed in validateArguments.
         */
        arguments[0] = new Argument("Buffer Address", "localhost:1972");

        /**
         * Declares another string argument.
         */
        arguments[1] = new Argument("Triggering event type", "Toaster.toast");

        /**
         * Declares an integer argument, but presented as single choice of a
         * group.
         */
        final String[] options = {"long", "short"};
        arguments[2] = new Argument("Toast duration", 0, options);

        /**
         * Declares an array of boolean arguments, presented as a list of
         * checkboxes.
         */
        final String[] content = {"type", "value", "sample", "offset", "duration"};
        final boolean[] defaultContent = {false, true, false, false, false, false};
        arguments[3] = new Argument("Toast content", defaultContent, content);

        /**
         * Declares an integer argument, presented as a text field but options
         * are limited to numbers only. Double and unsigned options available.
         */
        arguments[4] = new Argument("Timeout", 500, false);

        /**
         * Declares a single boolean argument, presented as a toggle button.
         */
        arguments[5] = new Argument("Save to file?", false);

        /**
         * Another string argument.
         */
        arguments[6] = new Argument("File Path", "toastlist");

        return arguments;
    }

    /**
     * Is used by the androidHandle app to determine the name of the Class.
     */
    @Override
    public String getName() {
        return "Toaster";
    }

    /**
     * Is called from within the public void run() method of a Thread object.
     * <p/>
     * Before the mainloop is called, the arguments and androidHandle variables are
     * set through functions defined in ThreadBase.
     */
    @Override
    public void mainloop() {

        /**
         * While the validate arguments function may have already parsed some of
         * the arguments. It necessarily needs to happen here again because
         * mainloop() and validateArguments() will not be called on the same
         * instance of this class.
         */
        final String[] split = arguments[0].getString().split(":");
        String address = split[0];
        int port = Integer.parseInt(split[1]);
        String eventType = arguments[1].getString();
        boolean longMessage = arguments[2].getSelected() == 1;
        boolean[] content = arguments[3].getChecked();
        Integer timeout = arguments[4].getInteger();
        boolean save = arguments[5].getBoolean();
        String path = arguments[6].getString();
        run = true;

        try {
            /**
             * connect() is a convenience function defined in ThreadBase. It
             * connects to the buffer if able and waits for the header. Returns
             * false if the buffer could not be reached at the specified
             * address/port.
             */
            Header hdr = connect(address,port);
            if ( hdr==null) {
                androidHandle.updateStatus("Could not connect to buffer.");
                run = false;
                return;
            }

            /**
             * The status message will be shown in the list of threads in the
             * app.
             */
            androidHandle.updateStatus("Waiting for events.");

            /**
             * The openWriteFile() and openReadFile() functions can be used to
             * access files on the device's external storage (usually the
             * sdcard).
             */
            PrintWriter floor = null;
            if (save) {
                floor = new PrintWriter(androidHandle.openWriteFile(path));
            }
            int nEventsOld = hdr.nEvents;

            while (run) {

                SamplesEventsCount count = client.waitForEvents(nEventsOld, timeout);

                if (count.nEvents != nEventsOld) {
                    BufferEvent[] events = client.getEvents(nEventsOld, count.nEvents - 1);
                    for (BufferEvent e : events) {
                        if (e.getType().toString().contentEquals(eventType)) {
                            StringBuilder message = new StringBuilder("");
                            if (content[0]) {

                                message.append(e.getType().toString());
                            }

                            if (content[1]) {
                                message.append(", ");
                                message.append(e.getValue().toString());
                            }

                            if (content[2]) {
                                message.append(", ");

                                message.append(e.sample);
                            }

                            if (content[3]) {
                                message.append(", ");
                                message.append(e.offset);

                            }
                            if (content[4]) {
                                message.append(", ");
                                message.append(e.duration);

                            }

                            /**
                             * The small feedback popups that are sometimes
                             * shown at the bottom/center of the screen on
                             * androidHandle devices are called toast. Calling the
                             * toast() or toastLong() methods will create such a
                             * popup.
                             *
                             */
                            if (longMessage) {
                                androidHandle.toastLong(message.toString());
                            } else {
                                androidHandle.toast(message.toString());
                            }
                            androidHandle.updateStatus("Last toast: " + message.toString());
                            if (save && floor != null) {
                                floor.write(message.toString() + "\n");
                                floor.flush();
                            }

                        }
                    }

                    nEventsOld = count.nEvents;
                }

            }
        } catch (final IOException e) {
            androidHandle.updateStatus("IOException caught, stopping.");
        }
    }

    /**
     * Called when the thread needs to stop. (When the stop threads button is
     * pressed in the app.) Is overridden so the buffer connection can be closed
     * neatly.
     */
    @Override
    public void stop() {
        super.stop();
        try {
            client.disconnect();

        } catch (final IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    /**
     * Used by the androidHandle app to determine if the arguments given by the user
     * are okay. If an argument is wrong, call the invalidate() method with some
     * kind reason for the invalidation in as the argument, this message will be
     * shown in red next to the input fields.
     */
    @Override
    public void validateArguments(final Argument[] arguments) {
        final String address = arguments[0].getString();

        try {
            final String[] split = address.split(":");
            try {
                Integer.parseInt(split[1]);
            } catch (final NumberFormatException e) {
                arguments[0].invalidate("Wrong address format.");
            }

        } catch (final ArrayIndexOutOfBoundsException e) {
            arguments[0].invalidate("Integer expected after colon.");
        }

    }
}
