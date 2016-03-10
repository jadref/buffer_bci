public class TMS_VLDELTA_INFO_T
{
  public short Config; // Config&0x0001 -> 0: original VLDelta encoding 1: Huffman
						   // Config&0x0100 -> 0: same 1: different
  public short Length; // Size [bits] of the length block before a delta sample
  public short TransFreqDiv; // Transmission frequency divisor Transfreq = MainSampFreq / TransFreqDiv
  public short NrOfChannels;
//C++ TO JAVA CONVERTER TODO TASK: Java does not have an equivalent for pointers to value types:
//ORIGINAL LINE: ushort *SampDiv;
  public short SampDiv; // Real sample frequence divisor per channel
}