using UnityEngine;
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;

namespace FieldTrip.Buffer
{
	public class BufferTimer  {
	
		private List<int> bufferSamples;
		private List<double> times;
		private int max_num_of_samples;
		private double rsquared=0;
	    private double yintercept=0;
	    private double slope=0;
		
		public BufferTimer(float fs){
			bufferSamples = new List<int>();
			times = new List<double>();
			max_num_of_samples = (int)fs * 60; //the regression is done over 1 minute worth of data
		}
		
		
		public void addSampleToRegression(int sample){
			bufferSamples.Add(sample);
			DateTime now = DateTime.UtcNow;
			int nowInMillis = (((now.Hour*60)+now.Minute)*60+now.Second)*1000+now.Millisecond;
			times.Add(nowInMillis);
			if(bufferSamples.Count>max_num_of_samples){
				bufferSamples.RemoveAt(0);
				times.RemoveAt(0);
			}
			Regression.LinearRegression(times.ToArray(), bufferSamples.ToArray().Select(i => (double)i).ToArray() ,0 , times.Count, out rsquared, out yintercept, out slope);
		}
		
		public void reset(){
			bufferSamples.Clear ();
			times.Clear ();
		}

		public int getSampleNow(){
			DateTime now = DateTime.UtcNow;
			int nowInMillis = (((now.Hour*60)+now.Minute)*60+now.Second)*1000+now.Millisecond;
			int sample = (int)(yintercept + slope * nowInMillis);
			//Debug.Log("rsquared="+rsquared+", nowInMillis="+nowInMillis+", yintercept="+yintercept+", slope="+slope+", sample="+sample);
			return sample;
		}
		
		public int getSampleAtTime(DateTime time){
			int timeInMillis =  (((time.Hour*60)+time.Minute)*60+time.Second)*1000+time.Millisecond;
			int sample = (int)(yintercept + slope * timeInMillis);
			Debug.Log(sample);
			return sample;
		}
		
	}
}	
	
	
	
class Regression
{
    /// Fits a line to a collection of (x,y) points.
    /// <param name="xVals">The x-axis values.</param>
    /// <param name="yVals">The y-axis values.</param>
    /// <param name="inclusiveStart">The inclusive inclusiveStart index.</param>
    /// <param name="exclusiveEnd">The exclusive exclusiveEnd index.</param>
    /// <param name="rsquared">The r^2 value of the line.</param>
    /// <param name="yintercept">The y-intercept value of the line (i.e. y = ax + b, yintercept is b).</param>
    /// <param name="slope">The slop of the line (i.e. y = ax + b, slope is a).</param>
    public static void LinearRegression(double[] xVals, double[] yVals,
                                        int inclusiveStart, int exclusiveEnd,
                                        out double rsquared, out double yintercept, out double slope)
    {
        if(xVals.Length == yVals.Length){
            double sumOfX = 0;
            double sumOfY = 0;
            double sumOfXSq = 0;
            double sumOfYSq = 0;
            double ssX = 0;
            double ssY = 0;
            double sumCodeviates = 0;
            double sCo = 0;
            double count = exclusiveEnd - inclusiveStart;

            for (int ctr = inclusiveStart; ctr < exclusiveEnd; ctr++)
            {
                double x = xVals[ctr];
                double y = yVals[ctr];
                sumCodeviates += x * y;
                sumOfX += x;
                sumOfY += y;
                sumOfXSq += x * x;
                sumOfYSq += y * y;
            }
            ssX = sumOfXSq - ((sumOfX * sumOfX) / count);
            ssY = sumOfYSq - ((sumOfY * sumOfY) / count);
            double RNumerator = (count * sumCodeviates) - (sumOfX * sumOfY);
            double RDenom = (count * sumOfXSq - (sumOfX * sumOfX)) * (count * sumOfYSq - (sumOfY * sumOfY));
            sCo = sumCodeviates - ((sumOfX * sumOfY) / count);

            double meanX = sumOfX / count;
            double meanY = sumOfY / count;
            double dblR = RNumerator / Math.Sqrt(RDenom);
            rsquared = dblR * dblR;
            yintercept = meanY - ((sCo / ssX) * meanX);
            slope = sCo / ssX;
        }else{
        	rsquared=0;
        	yintercept=0;
        	slope=0;
        	throw new IOException("The lengths of the y and x data sets aren't equal");
        }
    }
}
