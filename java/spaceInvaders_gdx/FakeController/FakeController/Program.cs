using System;
using FieldTrip.Buffer;
using System.Threading;

namespace FakeController
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            BufferClientClock client = new BufferClientClock();
            Header hdr = null;

            while (hdr == null)
            {
                try
                {
                    client.connect("localhost", 1972);
                    if (client.isConnected())
                    {
                        hdr = client.getHeader();
                    }
                }
                catch
                {
                    hdr = null;
                }

                if (hdr == null)
                {
                    Console.WriteLine("Invalid Header... waiting");
                    Thread.Sleep(1000);
                }
            }
            Console.WriteLine("Connected, press ESC to quit.");
            Console.WriteLine( hdr );

            float axis = 0;

            bool running = true;
            new Thread(() =>
                {
                    while (running)
                    {
                        lock (client)
                        {
                            client.putEvent(new BufferEvent("AXIS_X", axis, -1));

                        }
                        Thread.Sleep(100);
                    }
                }).Start();

            while (running)
            {
                var key = Console.ReadKey();
                if (key.Key == ConsoleKey.Escape)
                {
                    running = false;
                }
                else if (key.Key == ConsoleKey.Q)
                {
                    lock (client)
                    {
                        client.putEvent(new BufferEvent("BTN_FIRE", "down", -1));
                        Console.WriteLine( "Pressed down");
                    }
                }
                else if (key.Key == ConsoleKey.W)
                {
                    lock (client)
                    {
                        client.putEvent(new BufferEvent("BTN_FIRE", "up", -1));
                        Console.WriteLine( "Pressed up" );
                    }
                }
                else if (key.Key == ConsoleKey.E)
                {
                    axis -= 0.2f;
                    Console.WriteLine( "Pressed left" );
                }
                else if (key.Key == ConsoleKey.R)
                {
                    axis += 0.2f;
                    Console.WriteLine( "Pressed right" );
                }
            }

            Console.WriteLine();
        }
    }
}