/////////////////////////////////////////
//      BufferComm.cs
/////////////////////////////////////////

using System;
using FieldTrip.Buffer;

namespace FieldTrip.Buffer
{
	// Communication with the FiledTrip buffer
	class BufferComm
	{

		// Connection parametars
		static string hostname = "localhost";
		static int port = 1972;

		// Connection objects
		BufferClient C;
		Header hdr;

		// Event counter for num events in buffer so far
		int nEvents;

		// Num samples in buffer so far
		public int nSamples;

		// Constructor
		public BufferComm()
		{

			// Create communication obj and init the data 
			C = new BufferClient();
			nEvents = 0;
			nSamples = 0;
		}

		// Connect to the buffer
		public void Connect()
		{
			C.Connect(hostname, port);
		}

		// Return a float matrix array of the latest data in the FieldTrip buffer
		public float[,] GetData()
		{

			if (!C.IsConnected)
				return null;

			// Poll for the new data
			SamplesEventsCount sampevents = C.Poll();

			// Remember the Num samples in buffer so far
			if (nSamples == 0)
				nSamples = sampevents.NumSamples;
			if (sampevents.NumSamples == nSamples) {
				return null;
			}
			if (sampevents.NumSamples < nSamples) {
				nSamples = sampevents.NumSamples - 1;
				return null;
			}

			// Get just the newest data
			float[,] data = C.GetFloatData(nSamples, sampevents.NumSamples - 1);

			// Update the Num samples in buffer so far
			nSamples = sampevents.NumSamples - 1;

			return data;
		}

		// Get the values of the specified event type
		public double GetEvent(string commandType)
		{

			if (!C.IsConnected)
				return 0;

			// Poll for the new events
			SamplesEventsCount sampevents = C.Poll();

			// Remember the num events in buffer so far
			if (nEvents == 0)
				nEvents = sampevents.NumEvents - 2;
			if (sampevents.NumEvents - 1 == nEvents) {
				return -1;
			}
			if (sampevents.NumEvents < nEvents) {
				nEvents = sampevents.NumEvents;
				return -1;
			}

			// Get just the newest events
			BufferEvent[] events = C.GetEvents(nEvents, sampevents.NumEvents - 1);

			// Update the Num events in buffer so far
			nEvents = sampevents.NumEvents - 1;

			// Parse the event array and find the specified commandType event type
			// Return the value link to that event
			foreach (BufferEvent evt in events) {

				// check if the type is one we care about
				//ATTENTION: for buffer events use toString() lowercase NOT ToString()
				if (evt.GetType().ToString().Equals(commandType)) { // check if this event type matches

					//Convert.ToSingle(evt.getValue().array);
					//return Convert.ToSingle(evt.getValue().array);
					return double.Parse(evt.Value.ToString());
					//if (evt.getValue().toString().Equals(valueType)) { // check if the event value matches
					//    processEvent(evt);
					//}
				}
			}

			return -1;
		}

		public float[] GetEventArray(string commandType)
		{

			if (!C.IsConnected)
				return null;

			// Poll for the new events
			SamplesEventsCount sampevents = C.Poll();

			// Remember the num events in buffer so far
			if (nEvents == 0)
				nEvents = sampevents.NumEvents - 2;
			if (sampevents.NumEvents - 1 == nEvents) {
				return null;
			}
			if (sampevents.NumEvents < nEvents) {
				nEvents = sampevents.NumEvents;
				return null;
			}

			// Get just the newest events
			BufferEvent[] events = C.GetEvents(nEvents, sampevents.NumEvents - 1);

			// Update the Num events in buffer so far
			nEvents = sampevents.NumEvents - 1;

			// Parse the event array and find the specified commandType event type
			// Return the array of values link to that event
			foreach (BufferEvent evt in events) {

				// check if the type is one we care about
				//ATTENTION: for buffer events use toString() lowercase NOT ToString()
				if (evt.GetType().ToString().Equals(commandType)) { // check if this event type matches

					//Convert.ToSingle(evt.getValue().array);
					//return Convert.ToSingle(evt.getValue().array);
					//return double.Parse(evt.getValue().toString());
					return (float[])evt.Value.Array;
					//if (evt.getValue().toString().Equals(valueType)) { // check if the event value matches
					//    processEvent(evt);
					//}
				}
			}

			return null;
		}

		// Send the event to the FieldTrip buffer for int value
		public void SendEvent(string type, int value)
		{

			C.Poll();
			BufferEvent E = new BufferEvent(type, value, -1);
			C.PutEvent(E);
		}

		// Send the event to the FieldTrip buffer for string value
		public void SendEvent(string type, string value)
		{

			C.Poll();
			BufferEvent E = new BufferEvent(type, value, -1);
			C.PutEvent(E);
		}

		// Disconnect from the buffer
		public void Disconnect()
		{
			C.Disconnect();
		}
	}
}
