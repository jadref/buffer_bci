package nl.ru.bcigames.StandardizedInterface;


import nl.ru.bcigames.ServerWrapper.Subscriber;

public class TestingOneshotsend_ConLoop_BufferedSending {

    public static void main(String[] args) throws InterruptedException {
        StandardizedInterface si = StandardizedInterface.getInstance();
        System.out.println("BufferBCI Hostname: " + StandardizedInterface.BufferClient.getHostname());
        System.out.println("BufferBCI Port: " + StandardizedInterface.BufferClient.getPort());
        StandardizedInterface.BufferClient.connect();

        Thread.sleep(1000);

        StandardizedInterface.StimuliSystem.setStimuliFile("stimulifiles/gold_10hz.txt");

        StandardizedInterface.StimuliSystem.startStimulus();

        Subscriber sub = si.getSubscriberInstance();

        sub.addKeyListener("StimulusUpdate");


        Thread.sleep(1000);
        while(StandardizedInterface.StimuliSystem.isRunning()){
            boolean[] stimStates = StandardizedInterface.StimuliSystem.getStimuliStates();
            StandardizedInterface.StimuliSystem.sendStimUpdateToServer(stimStates);
            Thread.sleep(10);
        }

        StandardizedInterface.BufferClient.disconnect();

    }
}
