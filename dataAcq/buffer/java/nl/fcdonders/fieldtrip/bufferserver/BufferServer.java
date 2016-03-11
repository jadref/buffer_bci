package nl.fcdonders.fieldtrip.bufferserver;

import java.io.IOException;
import java.net.ServerSocket;
import java.nio.ByteOrder;
import java.util.ArrayList;

import nl.fcdonders.fieldtrip.bufferserver.data.DataModel;
import nl.fcdonders.fieldtrip.bufferserver.data.Header;
import nl.fcdonders.fieldtrip.bufferserver.data.RingDataStore;
import nl.fcdonders.fieldtrip.bufferserver.data.SavingRingDataStore;
import nl.fcdonders.fieldtrip.bufferserver.exceptions.DataException;
import nl.fcdonders.fieldtrip.bufferserver.network.ConnectionThread;

/**
 * Buffer class, a thread that opens a serverSocket to listen for connections
 * and starts a connectionThread to handle them.
 *
 * @author wieke, jadref
 *
 */
public class BufferServer {

    // maintains list of started FieldTrip buffer servers by this class    
    static ArrayList<ServerSocket> serverSockets = new ArrayList<ServerSocket>();
    static final int serverPort = 1972;    // default server port
    static final int dataBufSize = 1024 * 60; // default save samples = 60s @ 1024Hz
    static final int eventBufSize = 10 * 60;   // default save events  = 60s @ 10Hz
    static final String savePath = ""; // default not saving data
    
    boolean run = false;

    private DataModel dataStore;
    private int portNumber;

    //
    // Main method Start(), starts running a server thread in the current thread.
    // Handles arguments.
    //
    // @param args <port> or <port> <nSamplesAndEvents> or <port> <nSamples>
    // <nEvents>
    //
    public BufferServer() {
        this.dataStore = null;
    }

    public void Start() {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, savePath, 0);
    }

    public void Start(int serverPort) {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, savePath, 0);
    }

    public void Start(int serverPort, int dataBufSize) {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, savePath, 0);
    }

    public void Start(int serverPort, int dataBufSize, int eventBufSize) {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, savePath, 0);
    }

    public void Start(int serverPort, int dataBufSize, int eventBufSize, java.io.File file) {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, file.getPath(), 0);
    }

    public void Start(int serverPort, int dataBufSize, int eventBufSize, String path) {
        BufferServerStart(serverPort, dataBufSize, eventBufSize, path, 0);
    }

    private void BufferServerStart(int serverPort, int dataBufSize, int eventBufSize, String path, int verbosityLevel) {

        if (!path.isEmpty()) {
            this.dataStore = new SavingRingDataStore(dataBufSize, eventBufSize, path);
        } else {
            System.err.println("Not saving data!");
            this.dataStore = new RingDataStore(dataBufSize, eventBufSize);
        }

        if (this.portNumber == serverPort) {
            // First close previously opened server on this port
        }
        this.portNumber = serverPort;

        Thread runner;

        BufferServerThread bufferServerThread;
        bufferServerThread = new BufferServerThread(this, serverPort, dataBufSize, eventBufSize, verbosityLevel);

        runner = new Thread(bufferServerThread, "FieldTrip Buffer"); // (1) Create a new thread.       
        System.err.println("Start: " + runner.getName());
        runner.start(); // (2) Start the thread.        
    }

    public static void usage() {
        System.err.println("JAVA:   mybuffer = new BufferServer(); mybuffer.Start(PORT, sampLen, eventLen, savePath, verbosityLevel");
        System.err.println("MATLAB: mybuffer = nl.fcdonders.fieldtrip.bufferserver.BufferServer(); mybuffer.Start(PORT, samplen, eventlen, savePath, verbosityLevel)");
    }

    public ServerSocket serverSocket;
    private boolean disconnectedOnPurpose = false;
    private final ArrayList<ConnectionThread> threads = new ArrayList<ConnectionThread>();
    private FieldtripBufferMonitor monitor = null;
    private int nextClientID = 0;

    public void addMonitor(final FieldtripBufferMonitor monitor) {
        this.monitor = monitor;
        for (final ConnectionThread thread : threads) {
            thread.addMonitor(monitor);
        }
    }

    /**
     * Attempts to close the current serverSocket.
     *
     * @throws IOException
     */
    public void closeConnection() throws IOException {
        serverSocket.close();
    }

    /**
     * Flushes the events from the datastore.
     */
    public void flushEvents() {
        try {
            dataStore.flushEvents();
            if (monitor != null) {
                monitor.clientFlushedEvents(-1, System.currentTimeMillis());
            }
        } catch (final DataException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    /**
     * Flushes the header, data and samples from the dataStore.
     */
    public void flushHeader() {
        try {
            dataStore.flushHeader();
            if (monitor != null) {
                monitor.clientFlushedHeader(-1, System.currentTimeMillis());
            }
        } catch (final DataException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    /**
     * Flushes the samples from the datastore.
     */
    public void flushSamples() {
        try {
            dataStore.flushData();
            if (monitor != null) {
                monitor.clientFlushedData(-1, System.currentTimeMillis());
            }
        } catch (final DataException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    /**
     * Puts a header into the dataStore.
     *
     * @param nChans
     * @param fSample
     * @param dataType
     * @return
     */
    public boolean putHeader(final int nChans, final float fSample,
            final int dataType) {
        final Header hdr = new Header(nChans, fSample, dataType,
                ByteOrder.nativeOrder());
        try {
            dataStore.putHeader(hdr);
            if (monitor != null) {
                monitor.clientPutHeader(dataType, fSample, nChans, -1,
                        System.currentTimeMillis());
            }
            return true;
        } catch (final DataException e) {
            System.err.println("Error : " + e);
            return false;
        }
    }

    /**
     * Removes the connection from the list of threads.
     *
     * @param connection
     */
    public synchronized void removeConnection(final ConnectionThread connection) {
        threads.remove(connection);
    }

    public void listAllServerSockets() {
        // list all selectable sockets (clients/buffers)
        for (int i = 0; i < BufferServer.serverSockets.size(); i++) {
            System.out.printf("server socket: %s\n", BufferServer.serverSockets.get(i).toString());
        }
    }

    public void removeAllServerSockets() throws IOException {
        // remove all selectable sockets (clients/buffers)
        ServerSocket s;
        while (BufferServer.serverSockets.size() > 0) {
            s = BufferServer.serverSockets.get(0);
            if (s != null) {
                s.close();
            }
            BufferServer.serverSockets.remove(0);
        }
    }

    /**
     * Opens a serverSocket and starts listening for connections.
     *
     * @throws java.io.IOException
     */
    public void run() throws IOException {
        run = true;

        System.out.printf("Start listening for incoming client connections\n");
        //final Thread mainThread = Thread.currentThread();
        // Add shutdown hook to force close and flush to disk of open files if interrupted/aborted
        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                cleanup();
            }
        });
        try {
            serverSocket = new ServerSocket(portNumber);
            BufferServer.serverSockets.add(serverSocket);
            System.out.printf("Server socket opened on port: %d\n", portNumber);
        } catch (final IOException e) {
            System.err.println("Could not listen on port " + portNumber);
            System.out.printf("Could not listen on port: %d\n", portNumber);
            System.err.println(e);
        }
        try {
            while (run) {
                final ConnectionThread connection = new ConnectionThread(
                        nextClientID++, serverSocket.accept(), dataStore, this);
                connection.setName("Fieldtrip Client Thread "
                        + connection.clientAdress);
                connection.addMonitor(monitor);

                synchronized (threads) {
                    threads.add(connection);
                }
                connection.start();
            }
        } catch (final IOException e) {
            this.closeConnection();
            if (!disconnectedOnPurpose) {
                System.out.printf("Server socket disconnected, port: %d\n", portNumber);
                System.err.println(e);
            } else {
                for (final ConnectionThread thread : threads) {
                    thread.disconnect();
                }
            }
        }
    }

    /**
     * Stops the buffer thread and closes all existing client connections.
     */
    public void stopBuffer() {
        run = false; // stop listening for new clients
        try {
            if (serverSocket != null) {
                serverSocket.close();
            }
            for (final ConnectionThread thread : threads) {
                thread.disconnect();
            }
            disconnectedOnPurpose = true;
        } catch (final IOException e) {
            System.out.printf("%s\n", e.getMessage().toString());
            System.err.println(e);
        }
    }

    public void cleanup() {
        System.out.println("BufferServer:cleanup");
        dataStore.cleanup();
    }
}

class BufferServerThread implements Runnable {

    int serverPort;
    int dataBufSize;
    int eventBufSize;
    int logging;
    BufferServer buffer;

    public BufferServerThread() {
    }

    public BufferServerThread(BufferServer buf, int port, int bufsize, int eventsize, int verbositylevel) {
        serverPort = port;
        dataBufSize = bufsize;
        eventBufSize = eventsize;
        logging = verbositylevel;
        buffer = buf;
    }

    @Override
    public void run() {
        //Display info about this particular thread
        System.out.println(Thread.currentThread());
        try {
            buffer.addMonitor(new SystemOutMonitor(logging));
            buffer.run();
            buffer.cleanup(); // only gets here after stopBuffer() method was called
            BufferServer.serverSockets.remove(buffer.serverSocket);

        } catch (Exception e) {
            System.err.println(e);
        }
    }
}
