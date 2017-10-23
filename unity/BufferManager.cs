using UnityEngine;
using System.Collections;
using System.Threading;
using System.Linq;
using UnityEngine.UI;
using FieldTrip.Buffer;

/*
 * This script manages the connection to the Buffer
  * and processes events.
   *
    */


public class BufferManager : MonoBehaviour
{
    public Text StatusLabel;
        BufferClientClock client = new BufferClientClock();
            public string hostname = "localhost";
                public int port = 1972;
                    float counter = 0;
                        Header hdr;
                            int nEvents;
                                public static string currentBCIAction;
                                    public static int highestPredictionindex;
                                        string predictions;
                                            double[] predictionArray;

    // Use this for initialization
        void Start()
            {
                    //BufferEvent testevent = new BufferEvent("classifier.prediction",new double[] { 0.20, 0.80 },100);
                            DontDestroyOnLoad(gameObject);
                                    highestPredictionindex = 10;
                                            //double[] output = (double[])testevent.getValue().array;
                                                   // for (int i = 0; i<output.Length; i++)
                                                          // {
                                                                 //     print(output[i]);
                                                                         //}
                                                                                // double maxValue = output.Max();
                                                                                      //  int maxIndex = output.ToList().IndexOf(maxValue);
                                                                                            //  print(maxValue);
                                                                                                  //  print(maxIndex);
                                                                                                      }

    // Update is called once per frame
        // Slow the update rate by a counter to prevent overflow.
            void Update()
                {
                        counter += Time.deltaTime;
                                if (counter > 0.2)
                                        {
                                                    counter = 0;
                                                                if (client.isConnected())
                                                                            {
                                                                                            processBufferEvents();
                                                                                                        }
                                                                                                                }

    }

    // Find events from the buffer and process them according to their type.
        public void processBufferEvents (){

        int timeout = 5000;
                print(hdr.nEvents);

        try
                {
                            print("Waiting for events...");
                                        SamplesEventsCount sec = client.waitForEvents(nEvents -1, timeout);
                                                    if (sec.nEvents > nEvents)
                                                                {
                                                                                BufferEvent[] evs = client.getEvents(nEvents, sec.nEvents - 1);
                                                                                                nEvents = sec.nEvents;
                                                                                                                print("Got " + evs.Length + " events");

                //grab the newest event (This means it only take 1 event every update)
                                BufferEvent evt = evs[evs.Length-1];
                                                string evttype = evt.getType().toString();

                // Handle Exit event
                                if (evttype.Equals("exit"))
                                                {
                                                                    client.disconnect();
                                                                                    }

                // Handle keyboard events
                                else if (evttype.Equals("keyboard"))
                                                {
                                                                    predictions = evt.getValue().toString();
                                                                                        currentBCIAction = predictions;
                                                                                                            print(predictions);
                                                                                                                            }
                                                                                                                                            // handle predictions events
                                                                                                                                                            else if (evttype.Equals("classifier.prediction"))
                                                                                                                                                                            {
                                                                                                                                                                                                // Get highest prediction
                                                                                                                                                                                                                    predictionArray = (double[])evt.getValue().array;

                    double maxValue = predictionArray.Max();
                                        int maxIndex = predictionArray.ToList().IndexOf(maxValue);
                                                            highestPredictionindex = maxIndex;
                                                                                // set variable to index of highest prediction or some other boundary.
                                                                                                    //highestPredictionindex = 1;
                                                                                                                    }
                                                                                                                                }
                                                                                                                                        }
                                                                                                                                                catch
                                                                                                                                                        {
                                                                                                                                                                    print("catch Error");
                                                                                                                                                                            }

    }

    // Connects to the Buffer
        public void connectBuffer()
            {

        hdr = null;
                    try
                                {
                                                print("Connecting to " + hostname + ":" + port + "...");
                                                                client.connect(hostname, port);
                                                                                print("done");
                                                                                                print("Getting Header...");
                                                                                                                if (client.isConnected())
                                                                                                                                {
                                                                                                                                                    hdr = client.getHeader();

                }
                                print("done.");
                                            StatusLabel.text = "Connected";
                                                        StatusLabel.color = new Color(0, 255, 0);

            }
                        catch
                                    { //(IOException e)
                                                    hdr = null;
                                                                }
                                                                            if (hdr == null)
                                                                                        {
                                                                                                        print("Invalid Header... waiting");

            }
                        else
                                    {
                                                    print("Succes!");
                                                                }

       nEvents = hdr.nEvents;



    }

}