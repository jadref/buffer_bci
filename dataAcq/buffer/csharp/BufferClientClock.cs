/*
 * Copyright (C) 2013, Jason Farquhar
 *
 * Extension of bufferclient to add ability to fill in event sample number if it is negative
 * based on the output of the system clock and tracking the mapping between clock-time and sample-time
 */
using System;

namespace FieldTrip.Buffer
{
	public class BufferClientClock : BufferClient
	{

		protected ClockSync clockSync = null;
		public long maxSampError = 10000;
		// BODGE: very very very big!
		public long updateInterval = 3000;
		// at least every 3seconds
		public long minUpdateInterval = 10;
		// at least 10ms (100Hz) between clock updates
		protected int numWrong = 0;
		// count of number wrong predictions... if too many then reset the clock

		public BufferClientClock()
			: base()
		{
			clockSync = new ClockSync();
		}

		public BufferClientClock(double alpha)
			: base()
		{
			clockSync = new ClockSync(alpha);
		}

		public BufferClientClock(ByteOrder order)
			: base(order)
		{
			clockSync = new ClockSync();
		}

		public BufferClientClock(ByteOrder order, double alpha)
			: base(order)
		{
			clockSync = new ClockSync(alpha);
		}

		//--------------------------------------------------------------------
		// methods offering additional useful functionality

        /// <summary>
        /// Get the host associated with the FieldTrip buffer.
        /// </summary>
        /// <returns>The host associated with the FieldTrip buffer.</returns>
		public string getHost()
		{
			return sockChan.Host;
		}

        /// <summary>
        /// Get the port associated with the FieldTrip buffer.
        /// </summary>
        /// <returns>The port associated with the FieldTrip buffer.</returns>
		public int getPort()
		{
			return sockChan.Port;
		}

		//--------------------------------------------------------------------
		// overridden methods to
		// Fill in the estimated sample info

        /// <summary>
        /// Puts an event to the connected FieldTrip buffer.
        /// </summary>
        /// <param name="e">The event to send.</param>
		override public void putEvent(BufferEvent e)
		{
			if (e.sample < 0) {
				e.sample = (int)getSampOrPoll();
			}
			base.putEvent(e);
		}

        /// <summary>
        /// Sends an array of events to the connected FieldTrip buffer.
        /// </summary>
        /// <param name="e">The events to send.</param>
		override public void putEvents(BufferEvent[] e)
		{
			int samp = -1;
			for (int i = 0; i < e.Length; i++) {			 
				if (e[i].sample < 0) {
					if (samp < 0)
						samp = (int)getSampOrPoll();
					e[i].sample = samp;
				}
			}
			base.putEvents(e);
		}
		// use the returned sample info to update the clock sync
		override public SamplesEventsCount wait(int nSamples, int nEvents, int timeout)
		{
			//Console.WriteLine("clock update");
			SamplesEventsCount secount = base.wait(nSamples, nEvents, timeout);
			double deltaSamples = clockSync.getSamp() - secount.nSamples; // delta between true and estimated
			//Console.WriteLine("sampErr="+getSampErr() + " d(samp) " + deltaSamples + " sampThresh= " + clockSync.m*1000.0*.5);
			if (getSampErr() < maxSampError) {
				if (deltaSamples > clockSync.m * 1000.0 * .5) { // lost samples					 
					Console.WriteLine(deltaSamples + " Lost samples detected");
					clockSync.reset();
					//clockSync.b = clockSync.b - deltaSamples;
				} else if (deltaSamples < -clockSync.m * 1000.0 * .5) { // extra samples
					Console.WriteLine(-deltaSamples + " Extra samples detected");
					clockSync.reset();
				}
			}
			clockSync.updateClock(secount.nSamples); // update the rt->sample mapping
			return secount;
		}

        /// <summary>
        /// Get the header from the FieldTrip buffer.
        /// </summary>
        /// <returns>The header.</returns>
		override public Header getHeader()
		{
			Header hdr = base.getHeader();
			clockSync.updateClock(hdr.nSamples); // update the rt->sample mapping
			return hdr;
		}

        /// <summary>
        /// Connect to the FieldTrip buffer at the given address and port.
        /// </summary>
        /// <param name="address">The host where the FieldTrip buffer is running.</param>
        /// <param name="port">The port at which the FieldTrip buffer is running.</param>
        /// <returns></returns>
		override public bool connect(string address, int port)
		{
			clockSync.reset(); // reset old clock info (if any)
			return base.connect(address, port);
		}

		//--------------------------------------------------------------------
		// New methods to do the clock syncronization
		public long getSampOrPoll()
		{
			long sample = -1;
			bool dopoll = false;
			double time = getTime();
			if (getSampErr() > maxSampError || // error too big
			    time > (long)(clockSync.Tlast) + updateInterval || // simply too long since we updated
			    clockSync.N < 8) { // Simply not enough points to believe we've got a good estimate
				dopoll = true;
			}
			if (getSamp() < (long)(clockSync.Slast)) { // detected prediction before last known sample
				numWrong++; // increment count of number of times this has happened
				dopoll = true;
			} else {
				numWrong = 0;
			}
			if (time < (long)(clockSync.Tlast) + minUpdateInterval) { // don't update too rapidly
				dopoll = false;
			}
			if (dopoll) { // poll buffer for current samples
				if (numWrong > 5) { 
					clockSync.reset(); // reset clock if detected sysmetic error
					numWrong = 0;
				}
				long sampest = getSamp();
				//Console.Write("Updating clock sync: SampErr " + getSampErr() + 
				//					  " getSamp " + sampest + " Slast " + clockSync.Slast);
				sample = poll(0).nSamples; // force update if error is too big
				//Console.WriteLine(" poll " + sample + " delta " + (sample-sampest));
			} else { // use the estimated time
				sample = (int)getSamp();
			}
			return sample;
		}

		public long getSamp()
		{
			return clockSync.getSamp();
		}

		public long getSamp(double time)
		{
			return clockSync.getSamp(time);
		}

		public long getSampErr()
		{
			return Math.Abs(clockSync.getSampErr());
		}

		public double getTime() {
		   return clockSync.getTime();
		}
		// time in milliseconds
		public SamplesEventsCount syncClocks()
		{
			return	 syncClocks(new int[] { 100, 100, 100, 100, 100, 100, 100, 100, 100 });
		}

		public SamplesEventsCount syncClocks(int wait)
		{
			return	 syncClocks(new int[] { wait });
		}

		public SamplesEventsCount syncClocks(int[] wait)
		{
			clockSync.reset();
			SamplesEventsCount ssc;
			ssc = poll(0);
			for (int i = 0; i < wait.Length; i++) {			
				try {
					System.Threading.Thread.Sleep(wait[i]);
				} catch { // (InterruptedException e) 
				}
				ssc = poll(0);				
			}
			return ssc;
		}

		public ClockSync getClockSync() { return clockSync; }
	}
}
