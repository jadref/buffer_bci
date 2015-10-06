package nl.dcc.fieldtripthreads.threads;

import java.io.IOException;
import java.util.Random;

import nl.fcdonders.fieldtrip.BufferClient;
import nl.fcdonders.fieldtrip.Header;

import nl.dcc.fieldtripthreads.base.Argument;
import nl.dcc.fieldtripthreads.base.ThreadBase;

public class SignalProxy extends ThreadBase {
	private String adress;
	private int port;
	private int nChannels;
	private double fSample;
	private int blockSize;
	private boolean run = true;
	private final BufferClient client = new BufferClient();
	Random generator;

	private double[][] genData() {
		double[][] data = new double[blockSize][nChannels];

		for (int x = 0; x < blockSize; x++) {
			for (int y = 0; y < nChannels; y++) {
				data[x][y] = generator.nextDouble();
			}
		}

		return data;
	}

	@Override
	public Argument[] getArguments() {
		final Argument[] arguments = new Argument[4];

		arguments[0] = new Argument("Buffer Adress", "localhost:1972");

		arguments[1] = new Argument("Number of channels", 3, false);
		arguments[2] = new Argument("Sampling frequency", 100.0, false);
		arguments[3] = new Argument("Block size", 5, false);

		return arguments;
	}

	@Override
	public String getName() {
		return "Signal Proxy";
	}

	@Override
	public void mainloop() {

		final String[] split = arguments[0].getString().split(":");
		adress = split[0];
		port = Integer.parseInt(split[1]);
		nChannels = arguments[1].getInteger();
		fSample = arguments[2].getDouble();
		blockSize = arguments[3].getInteger();
		generator = new Random();

		run = true;
		try {
			if (!client.isConnected()) {
				client.connect(adress, port);
			} else {
				android.updateStatus("Could not connect to buffer.");
				return;
			}

			android.updateStatus("Putting header");

			client.putHeader(new Header(nChannels, fSample, 10));
			double[][] data = genData();
			long delta = (long) (1000 / fSample) * blockSize;
			long time = 0;
			long sleepTime = 0;
			int n = 0;
			while (run) {
				time = System.currentTimeMillis();
				client.putData(data);
				data = genData();
				n = n + blockSize;
				if (n % 100 == 0) {
					android.updateStatus(Integer.toString(n)
							+ " samples added.");
				}
				sleepTime = delta - (System.currentTimeMillis() - time);
				if (sleepTime > 0) {
					Thread.sleep(sleepTime);
				}
			}
		} catch (final IOException e) {
			android.updateStatus("IOException caught, stopping.");
			return;
		} catch (InterruptedException e) {
			android.updateStatus("InterruptedException caught, stopping.");
			return;
		}
	}

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

	@Override
	public void validateArguments(final Argument[] arguments) {
		final String adress = arguments[0].getString();

		try {
			final String[] split = adress.split(":");
			arguments[0].validate();
			try {
				Integer.parseInt(split[1]);
			} catch (final NumberFormatException e) {
				arguments[0].invalidate("Wrong adress format.");
			}

		} catch (final ArrayIndexOutOfBoundsException e) {
			arguments[0].invalidate("Integer expected after colon.");
		}
	}

}
