/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package nl.dcc.buffer_bci;

/**
 *
 * @author H.G. van den Boorn
 */
public class TMS_INPUT_DEVICE_T
{
  public short Size; // Size of this structure in words (device not present: send 2)
  public short Totalsize; // Total size ID data from this device in words (device not present: send 2)
  public int SerialNumber; // Serial number of this input device
  public short Id; // Device ID
  public String DeviceDescription; // String pointer identifying the device
  public short NrOfChannels; // Number of channels of this input device
  public short DataPacketSize; // Size simple PCM data packet over all channels
  public TMS_CHANNEL_DESC_T[] Channel; // Pointer to all channel descriptions
}
