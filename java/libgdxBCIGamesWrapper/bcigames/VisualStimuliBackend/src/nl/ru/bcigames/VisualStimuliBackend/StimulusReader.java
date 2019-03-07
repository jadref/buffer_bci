/*
 * Copyright (c) 2019 Jeremy Constantin Börker, Anna Gansen, Marit Hagens, Codruta Lugoj, Wouter Loeve, Samarpan Rai and Alex Tichter
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package nl.ru.bcigames.VisualStimuliBackend;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

/**
 * Stimulus file reader.
 */
public class StimulusReader {

    public float[][] stimulusSequence = null;
    public int[] stimulusTime_ms = null;

    /**
     * Constructor for the stimulus file reader.
     * @param stimulusfile Location of the stimulus file one wants to use.
     */
    StimulusReader(String stimulusfile){
        try {
            BufferedReader br = new BufferedReader(new FileReader(stimulusfile));
            readFile(br);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    /**
     * Actual file reader. Code was provided by buffer_bci
     * @param bufferedReader Buffered file reader of the stimulus file.
     */
    private void readFile(BufferedReader bufferedReader) {
        // Read the stimTimes_ms
        try {
            float[][] tmpStimTime = readArray(bufferedReader);
            if (tmpStimTime.length > 1) {
                System.out.println("more than 1 row of stim Times?\n");
                throw new IOException("Vector stim times expected");
            }
            float[][] tmpstimSeq = readArray(bufferedReader);
            if (tmpstimSeq.length < 1) {
                System.out.println("No stimSeq found in file!");
                throw new IOException("no stimSeq in file");
            } else if (tmpstimSeq[0].length != tmpStimTime[0].length) {
                System.out.println("Mismatched lengths of stimTime (1x" + tmpStimTime[0].length + ")" +
                        " and stimSeq (" + tmpstimSeq.length + "x" + tmpstimSeq[0].length + ")");
                throw new IOException("stimTime and stimSeq lengths unequal");
            }
            // All is good convert stimTimes to int vector and construct
            int[] stimTime_ms = new int[tmpStimTime[0].length];
            for (int i = 0; i < tmpStimTime[0].length; i++) stimTime_ms[i] = (int) tmpStimTime[0][i];
            // Transpose the stimSeq into [epoch][stimulus], i.e. so faster change over stimulus
            float[][] stimSeq = new float[tmpstimSeq[0].length][tmpstimSeq.length];
            for (int si = 0; si < tmpstimSeq.length; si++) {
                for (int ei = 0; ei < tmpstimSeq[si].length; ei++) {
                    stimSeq[ei][si] = tmpstimSeq[si][ei];
                }
            }
            stimulusSequence = stimSeq;
            stimulusTime_ms = stimTime_ms;
        }catch(IOException e){
            e.printStackTrace();
        }

    }

    /**
     * Get the timing array of the stimulus times. Typically 1x255
     * @return the timing array
     */
    public int[] getStimTime(){
        return stimulusTime_ms;
    }

    /**
     * Get the stimulus sequence array. Typically 8x255
     * @return The stimulus sequence array
     */
    public float[][] getStimSeq(){
        return stimulusSequence;
    }

    /**
     * To string method for converting the two arrays for better readability.
     * @return
     */
    public String toString(){
        return toString(stimulusSequence,stimulusTime_ms);
    }

    /**
     * To string method for converting the two arrays for better readability.
     * @param stimSeq The stimulus sequence array.
     * @param stimTime_ms The timing array.
     * @return
     */
    public static String toString(float [][]stimSeq, int[] stimTime_ms){
        String str=new String();
        str = str + "# stimTime : ";
        if ( stimSeq==null ) {
            str += "<null>\n[]\n\n";
        }else{
            str += "1x" +  stimTime_ms.length + "\n";
            for(int i=0;i<stimTime_ms.length-1;i++) str += stimTime_ms[i]+"\t";
            str += stimTime_ms[stimTime_ms.length-1] + "\n";
            str += "\n\n"; // two new lines mark the end of the array
        }
        if ( stimSeq==null ) {
            str += "# stimSeq[]=<null>\n[]\n";
        } else {
            str += "# stimSeq : " + stimSeq.length + "x" + stimSeq[0].length + "\n";
            str += writeArray(stimSeq,false);
        }
        return str;
    }

    /**
     * Helper function to write an 2 dimensional float array to a string.
     * @param array array to write
     * @return String notation of the array.
     */
    public static String writeArray(float [][]array){ return writeArray(array,true); }

    /**
     * Actually write an 2 dimensional float array to a string.
     * @param array 2 dimensional float array
     * @param incSize also print inforamtion about the size of the array.
     * @return String notation of the array
     */
    public static String writeArray(float [][]array, boolean incSize){
        String str=new String();
        if ( incSize ) {
            str += "# size = " + array.length + "x" + array[0].length + "\n";
        }
        for ( int ti=0; ti<array.length; ti++){ // time points
            for(int i=0;i<array[ti].length-1;i++) str += array[ti][i] + "\t";
            str += array[ti][array[ti].length-1] + "\n";
        }
        str += "\n\n"; // two new-lines mark the end of the array
        return str;
    }

    /**
     * Reads a two dimensional array from a file and stores it in a 2 dimensional array.
     * @param bufferedReader bufferReader object of the file to read
     * @return 2 dimensional float array
     * @throws IOException
     */
    public static float[][] readArray(BufferedReader bufferedReader) throws IOException {
        if ( bufferedReader == null ) {
            System.out.println("could not allocate reader");
            throw new IOException("Couldnt allocate a reader");
        }
        int width = -1;

        // tempory store for all the values loaded from file
        ArrayList<float[]> rows=new ArrayList<float[]>(10);
        String line;
        int nEmptyLines = 0;
        //System.out.println("Starting new matrix");
        while ( (line = bufferedReader.readLine()) != null ) {
            // skip comment lines
            if ( line == null || line.startsWith("#") ){
                continue;
            } if ( line.length() == 0 ) { // double empty line means end of this array
                nEmptyLines++;
                if ( nEmptyLines > 1 && width > 0 ) { // end of matrix by 2 empty lines
                    //System.out.println("Got 2 empty lines");
                    break;
                } else { // skip them
                    continue;
                }
            }
            //System.out.println("Reading line " + rows.size());

            // split the line into entries on the split character
            String[] values = line.split("[ ,	]"); // split on , or white-space
            if ( width>0 && values.length != width ) {
                throw new IOException("Row widths are not consistent!");
            } else if ( width<0 ) {
                width = values.length;
            }
            // read the row
            float[] cols = new float[width]; // tempory store for the cols data
            for ( int i=0; i<values.length; i++ ) {
                try {
                    cols[i] = Float.valueOf(values[i]);
                } catch ( NumberFormatException e ) {
                    throw new IOException("Not a float number " + values[i]);
                }
            }
            // add to the tempory store
            rows.add(cols);
        }
        //if ( line==null ) System.out.println("line == null");

        if ( width<0 ) return null; // didn't load anything

        // Now put the data into an array
        float[][] array = new float[rows.size()][width];
        for ( int i=0; i<rows.size(); i++) array[i]=rows.get(i);
        return array;
    }
}