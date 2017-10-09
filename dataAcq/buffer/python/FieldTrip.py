"""
FieldTrip buffer (V1) client in pure Python

(C) 2010 S. Klanke
"""

# We need socket, struct, and numpy
import socket
import struct
import sys

VERSION = 1
PUT_HDR = 0x101
PUT_DAT = 0x102
PUT_EVT = 0x103
PUT_OK  = 0x104
PUT_ERR = 0x105
GET_HDR = 0x201
GET_DAT = 0x202
GET_EVT = 0x203
GET_OK  = 0x204
GET_ERR = 0x205
FLUSH_HDR = 0x301
FLUSH_DAT = 0x302
FLUSH_EVT = 0x303
FLUSH_OK  = 0x304
FLUSH_ERR = 0x305
WAIT_DAT = 0x402
WAIT_OK  = 0x404
WAIT_ERR = 0x405

DATATYPE_CHAR = 0
DATATYPE_UINT8 = 1
DATATYPE_UINT16 = 2
DATATYPE_UINT32 = 3
DATATYPE_UINT64 = 4
DATATYPE_INT8 = 5
DATATYPE_INT16 = 6
DATATYPE_INT32 = 7
DATATYPE_INT64 = 8
DATATYPE_FLOAT32 = 9
DATATYPE_FLOAT64 = 10
DATATYPE_UNKNOWN = 0xFFFFFFFF

CHUNK_UNSPECIFIED = 0
CHUNK_CHANNEL_NAMES = 1
CHUNK_CHANNEL_FLAGS = 2
CHUNK_RESOLUTIONS = 3
CHUNK_ASCII_KEYVAL = 4
CHUNK_NIFTI1 = 5
CHUNK_SIEMENS_AP = 6
CHUNK_CTF_RES4 = 7

# List for converting FieldTrip datatypes to Numpy datatypes
numpyType = ['int8', 'uint8', 'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64', 'float32', 'float64']
# Corresponding word sizes
wordSize = [1,1,2,4,8,1,2,4,8,4,8]
# FieldTrip data type as indexed by numpy dtype.num
# dType  dType.num  fieldTrip
# int8      1           1
# uint8     2           5
# int16     3           2
# uint16    4           6
# int32     5           2
# uint32    6           7
# int64     7           4
# uint64    8           8
# float32   11           9
# float64   12           10

dataTypesList = [-1, 5, 1, 6, 2, 7, 3, 8, 4, -1, -1, 9, 10]

try:
    import numpy

    def dataType(A):
        """ return the fieldtrip datatype of the input object """
        if isinstance(A, str):
            return DATATYPE_CHAR
        if isinstance(A, numpy.ndarray):
            dt = A.dtype
            if not(dt.isnative) or dt.num<1 or dt.num>=len(dataTypesList):
                return DATATYPE_UNKNOWN
            ft = dataTypesList[dt.num]
            if ft == -1:
                return DATATYPE_UNKNOWN
            else:
                return ft
        if isinstance(A, int):
            return DATATYPE_INT32
        if isinstance(A, float):
            return DATATYPE_FLOAT64
        return DATATYPE_UNKNOWN



    def serialize(A):
        """Returns Fieldtrip data type and string representation of the given object, if possible."""
        if isinstance(A, str):
            if sys.version_info[0]>=3 :
                return (0,bytes(A,'utf8'))
            else:
                return (0,A)

        if isinstance(A, list) or isinstance(A,tuple):
            # check list has all the same type
            dt0=dataType(A[0]);
            if all(dataType(x)==dt0 for x in A):
                if dt0==DATATYPE_CHAR:
                    return (dt0, struct.pack('c'*len(A), *A))
                elif dt0==DATATYPE_INT32:
                    return (dt0, struct.pack('i'*len(A), *A))
                elif dt0==DATATYPE_FLOAT32:
                    return (dt0, struct.pack('f'*len(A), *A))
                elif dt0==DATATYPE_FLOAT64:
                    return (dt0, struct.pack('d'*len(A), *A))

        if isinstance(A, numpy.ndarray):
            dt = A.dtype
            if not(dt.isnative) or dt.num<1 or dt.num>=len(dataTypesList):
                return (DATATYPE_UNKNOWN, None)

            ft = dataTypesList[dt.num]
            if ft == -1:
                return (DATATYPE_UNKNOWN, None)

            if A.flags['C_CONTIGUOUS']:
                # great, just use the array's buffer interface
                return (ft, str(A.data))

            # otherwise, we need a copy to C order
            AC = A.copy('C')
            return (ft, str(AC.data))

        if isinstance(A, int):
            return (DATATYPE_INT32, struct.pack('i', A))

        if isinstance(A, float):
            return (DATATYPE_FLOAT64, struct.pack('d', A))

        return (DATATYPE_UNKNOWN, None)

    def rawtoarray(shape, datatype, raw):
        return numpy.ndarray(shape, dtype=numpyType[datatype], buffer=raw)

    def arraysize(array):
        return (array.shape[0], array.shape[1])

    def validatearray(array):
        if not(isinstance(array, numpy.ndarray)) or len(array.shape)!=2:
                raise ValueError('Data must be given as a NUMPY array (samples x channels)')
except ImportError:

    def dataType(A):
        """ return the fieldtrip datatype of the input object """
        if isinstance(A, str):
            return DATATYPE_CHAR
        if isinstance(A, int):
            return DATATYPE_INT32
        if isinstance(A, float):
            return DATATYPE_FLOAT64
        return DATATYPE_UNKNOWN

    def serialize(A):
        if isinstance(A, str):
            if sys.version_info[0]>=3 :
                return (0,bytes(A,'utf8'))
            else:
                return (0,A)

        if isinstance(A, list) or isinstance(A,tuple):
            # check list has all the same type
            dt0=dataType(A[0]);
            if all(dataType(x)==dt0 for x in A):
                if dt0==DATATYPE_CHAR:
                    return (dt0, struct.pack('c'*len(A), *A))
                elif dt0==DATATYPE_INT32:
                    return (dt0, struct.pack('i'*len(A), *A))
                elif dt0==DATATYPE_FLOAT32:
                    return (dt0, struct.pack('f'*len(A), *A))
                elif dt0==DATATYPE_FLOAT64:
                    return (dt0, struct.pack('d'*len(A), *A))

        """I couldn't think of an elegant way of handling different datatypes since
        python only has a limited number of datatypes (int, long, float). So I just
        expect the user ot explicitly provide the datatype during input"""
        if isinstance(A, tuple):
            data, datatype = A
            nSamp, nChans = arraysize(data)
            raw = ""
            packformat = ['c','B','H','I','Q', 'b', 'h', 'i', 'q', 'f', 'd'][datatype] * nChans

            for sample in data:
                raw = struct.pack(packformat, sample)

            return (datatype, raw)

        return (DATATYPE_UNKNOWN, None)

    def rawtoarray(shape, datatype, raw):
        if isinstance(shape, tuple):
            nSamp, nChan = shape
            packformat = ['c','B','H','I','Q', 'b', 'h', 'i', 'q', 'f', 'd'][datatype] * nSamp * nChan

            data = struct.unpack(packformat, raw)
            array = list()

            for sample in range(0,shape[0]):
                start = sample*nChan;
                end = (sample+1)*nChan
                array.append(data[start:end])

            return array
        else:
            packformat = ['c','B','H','I','Q', 'b', 'h', 'i', 'q', 'f', 'd'][datatype] * shape
            return list(struct.unpack(packformat, raw))

    def arraysize(array):
        return (len(array[0]), len(array[0][0]))

    def validatearray(data):
        array, datatype = data
        if not(isinstance(array,list) and isinstance(array[0], list) and isinstance(datatype, int) and datatype >= 0 and datatype <= 10):
            raise ValueError('Data must be a python a tuple with (array, datatype), where array is a list of lists (samples by channels) of bools, ints or floats and 10 >= datatype >= 0.')

class Chunk:
    def __init__(self):
        self.type = 0
        self.size = 0
        self.buf = ''

class Header:
    """Class for storing header information in the FieldTrip buffer format"""
    def __init__(self):
        self.nChannels = 0
        self.nSamples = 0
        self.nEvents = 0
        self.fSample = 0.0
        self.dataType = 0
        self.chunks = {}
        self.labels = []

    def __str__(self):
        return 'Channels.: %i\nSamples..: %i\nEvents...: %i\nSampFreq.: %f\nDataType.: %s\n'%(self.nChannels, self.nSamples, self.nEvents, self.fSample, numpyType[self.dataType])

class Event:
    """Class for storing events in the FieldTrip buffer format"""
    def __init__(self, type = None, value=None, sample=-1, offset=0, duration=0):
        if isinstance(type,Event):
            self.deserialize(S)
        else:
            self.type = type   if not type is None else ''
            self.value = value if not value is None else ''
            self.sample = sample
            self.offset = offset
            self.duration = duration

    def __str__(self):
        return '(t:%s v:%s s:%i o:%i d:%i)\n'%(str(self.type),str(self.value), self.sample, self.offset, self.duration)

    def deserialize(self, buf):
        bufsize = len(buf)
        if bufsize < 32:
            return 0

        (type_type, type_numel, value_type, value_numel, sample, offset, duration, bsiz) = struct.unpack('IIIIIiiI', buf[0:32])

        self.sample = sample
        self.offset = offset
        self.duration = duration

        st = type_numel * wordSize[type_type]
        sv = value_numel * wordSize[value_type]

        if bsiz+32 > bufsize or st+sv > bsiz:
            raise IOError('Invalid event definition -- does not fit in given buffer')

        raw_type = buf[32:32+st]
        raw_value = buf[32+st:32+st+sv]

        if type_type == 0: # str type, decode to string value
            self.type = raw_type.decode()
        else:
            self.type = rawtoarray((type_numel), type_type, raw_type)

        if value_type == 0:#str type, decode to string value
            self.value = raw_value.decode()
        else:
            self.value = rawtoarray((value_numel), value_type, raw_value)

        return bsiz + 32

    def serialize(self):
        """Returns the contents of this event as a string, ready to send over the network,
           or None in case of conversion problems.
        """
        type_type, type_buf = serialize(self.type)
        if type_type == DATATYPE_UNKNOWN:
            return None
        type_size = len(type_buf)
        type_numel = type_size / wordSize[type_type]

        value_type, value_buf = serialize(self.value)
        if value_type == DATATYPE_UNKNOWN:
            return None
        value_size = len(value_buf)
        #print str(value_size) + " = " + str(value_buf)
        value_numel = value_size / wordSize[value_type]

        bufsize = type_size + value_size

        # original
        # S = struct.pack('IIIIiiiI', type_type, type_numel, value_type, value_numel, int(self.sample), int(self.offset), int(self.duration), bufsize)
        # mine:
        S = struct.pack('iiiiiiii', int(type_type), int(type_numel), int(value_type), int(value_numel), int(self.sample), int(self.offset), int(self.duration), bufsize)
        return S + type_buf + value_buf


class Client:
    """Class for managing a client connection to a FieldTrip buffer."""
    def __init__(self):
        self.isConnected = False
        self.sock = []

    def connect(self, hostname='localhost', port=1972):
        """connect([hostname, port]) -- make a connection, default host:port is localhost:1972."""
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((hostname, port))
        self.sock.setblocking(True)
        self.isConnected = True

    def disconnect(self):
        """disconnect() -- close a connection."""
        if self.isConnected:
            self.sock.close()
            self.sock = []
            self.isConnected = False

    def sendRaw(self, request):
        """Send all bytes of the string 'request' out to socket."""
        if not(self.isConnected):
            raise IOError('Not connected to FieldTrip buffer')

        N = len(request);
        nw = self.sock.send(request)
        while nw<N:
            nw += self.sock.send(request[nw:])

    def sendRequest(self, command, payload=None):
        if payload is None:
            request = struct.pack('HHI', VERSION, command, 0)
        else:
            request = struct.pack('HHI', VERSION, command, len(payload)) + payload

        self.sendRaw(request)

    def receiveResponse(self, minBytes=0):
        """Receive response from server on socket 's' and return it as (status,bufsize,payload)."""

        resp_hdr = self.sock.recv(8)
        while len(resp_hdr) < 8:
            resp_hdr += self.sock.recv(8-len(resp_hdr))

        (version, command, bufsize) = struct.unpack('HHI', resp_hdr)

        if version!=VERSION:
            self.disconnect()
            raise IOError('Bad response from buffer server - disconnecting')

        if bufsize > 0:
            payload = self.sock.recv(bufsize)
            while len(payload) < bufsize:
                payload += self.sock.recv(bufsize - len(payload))
        else:
            payload = None
        return (command, bufsize, payload)

    def getHeader(self):
        """getHeader() -- grabs header information from the buffer an returns it as a Header object."""

        self.sendRequest(GET_HDR)
        (status, bufsize, payload) = self.receiveResponse()

        if status==GET_ERR:
            return None

        if status!=GET_OK:
            self.disconnect()
            raise IOError('Bad response from buffer server - disconnecting')

        if bufsize < 24:
            self.disconnect()
            raise IOError('Invalid HEADER packet received (too few bytes) - disconnecting')

        (nchans, nsamp, nevt, fsamp, dtype, bfsiz) = struct.unpack('IIIfII', payload[0:24])

        H = Header()
        H.nChannels = nchans
        H.nSamples = nsamp
        H.nEvents = nevt
        H.fSample = fsamp
        H.dataType = dtype

        if bfsiz > 0:
            offset = 24
            while offset + 8 < bufsize:
                (chunk_type, chunk_len) = struct.unpack('II', payload[offset:offset+8])
                offset+=8
                if offset + chunk_len < bufsize:
                   break
                H.chunks[chunk_type] = payload[offset:offset+chunk_len]
                offset += chunk_len

            if CHUNK_CHANNEL_NAMES in H.chunks:
                labels = H.chunks[CHUNK_CHANNEL_NAMES].decode() #convert from byte->char
                L = labels.split('\0')
                numLab = len(L);
                if numLab>=H.nChannels:
                    H.labels = L[0:H.nChannels]

        return H

    def putHeader(self, nChannels, fSample, dataType, labels = None, chunks = None):
        haveLabels = False
        extras = ''
        if not(labels is None):
            serLabels = ''
            try:
                for n in range(0,nChannels):
                    serLabels+=labels[n] + '\0'
            except:
                raise ValueError('Channels names (labels), if given, must be a list of N=numChannels strings')

            extras = struct.pack('II', CHUNK_CHANNEL_NAMES, len(serLabels)) + serLabels
            haveLabels = True

        if not(chunks is None):
            for chunk_type, chunk_data in chunks:
                if haveLabels and chunk_type==CHUNK_CHANNEL_NAMES:
                    # ignore channel names chunk in case we got labels
                    continue
                extras += struct.pack('II', chunk_type, len(chunk_data)) + chunk_data

        sizeChunks = len(extras)

        hdef = struct.pack('IIIfII', nChannels, 0, 0, fSample, dataType, sizeChunks)
        request = struct.pack('HHI', VERSION, PUT_HDR, sizeChunks + len(hdef)) + hdef + extras
        self.sendRaw(request)
        (status, bufsize, resp_buf) = self.receiveResponse()
        if status != PUT_OK:
            raise IOError('Header could not be written')


    def getData(self, index = None):
        """getData([indices]) -- retrieve data samples and return them as a Numpy array, samples in rows(!).
            The 'indices' argument is optional, and if given, must be a tuple or list with inclusive, zero-based
            start/end indices.
        """

        if index is None:
            request = struct.pack('HHI', VERSION, GET_DAT, 0)
        else:
            indS = int(index[0])
            indE = int(index[1])
            request = struct.pack('HHIII', VERSION, GET_DAT, 8, indS, indE)
        self.sendRaw(request)

        (status, bufsize, payload) = self.receiveResponse()
        if status == GET_ERR:
            return None

        if status != GET_OK:
            self.disconnect()
            raise IOError('Bad response from buffer server - disconnecting')

        if bufsize < 16:
            self.disconnect()
            raise IOError('Invalid DATA packet received (too few bytes)')

        (nchans, nsamp, datype, bfsiz) = struct.unpack('IIII', payload[0:16])

        if bfsiz < bufsize - 16 or datype >= len(numpyType):
            raise IOError('Invalid DATA packet received')

        raw = payload[16:bfsiz+16]
        D = rawtoarray((nsamp, nchans), datype, raw)

        return D


    def getEvents(self, indices = None):
        """getEvents([indices]) -- retrieve events and return them as a list of Event objects.
            The 'indices'=[start end] argument is optional, and if given, must be a tuple or list with
            inclusive, zero-based start/end indices. The 'type' and 'value' fields of the event
            will be converted to strings or Numpy arrays.
        """

        if indices is None:
            request = struct.pack('HHI', VERSION, GET_EVT, 0)
        else:
            indS = int(indices[0])
            if len(indices)==1:
                indE = indS
            else:
                indE = int(indices[-1])
            if indE < indS :
                return []
            request = struct.pack('HHIII', VERSION, GET_EVT, 8, indS, indE)
        self.sendRaw(request)

        (status, bufsize, resp_buf) = self.receiveResponse()
        if status == GET_ERR:
            raise IOError('Bad response from buffer server')
            return []

        if status != GET_OK:
            self.disconnect()
            raise IOError('Bad response from buffer server - disconnecting')

        offset = 0
        E = []
        while 1:
            e = Event()
            nextOffset = e.deserialize(resp_buf[offset:])
            if nextOffset == 0:
                break
            E.append(e)
            offset = offset + nextOffset

        return E


    def putEvents(self, E):
        """putEvents(E) -- writes a single or multiple events, depending on whether an 'Event'
           object, or a list of 'Event' objects is given as an argument.
        """
        if isinstance(E,Event):
            buf = E.serialize()
        else:
            buf = ''
            num = 0
            for e in E:
                if not(isinstance(e,Event)):
                    raise 'Element %i in given list is not an Event'%num
                buf = buf + e.serialize()
                num = num + 1

        self.sendRequest(PUT_EVT, buf)
        (status, bufsize, resp_buf) = self.receiveResponse()

        if status != PUT_OK:
            raise IOError('Events could not be written.')


    def putData(self, D):
        """putData(D) -- writes samples that must be given as a NUMPY array, samples x channels.
           The type of the samples (D) and the number of channels must match the corresponding
           quantities in the FieldTrip buffer.
        """

        validatearray()

        (nSamp, nChan) = arraysize(D)

        (dataType, dataBuf) = serialize(D)

        dataBufSize = len(dataBuf)

        request = struct.pack('HHI', VERSION, PUT_DAT, 16+dataBufSize)
        dataDef = struct.pack('IIII', nChan, nSamp, dataType, dataBufSize)
        self.sendRaw(request + dataDef + dataBuf )

        (status, bufsize, resp_buf) = self.receiveResponse()
        if status != PUT_OK:
            raise IOError('Samples could not be written.')

    def poll(self):

        request = struct.pack('HHIIII', VERSION, WAIT_DAT, 12, 0, 0, 0)
        self.sendRaw(request)

        (status, bufsize, resp_buf) = self.receiveResponse()

        if status != WAIT_OK or bufsize < 8:
            raise IOError('Polling failed.')

        return struct.unpack('II', resp_buf[0:8])

    def wait(self, nsamples, nevents, timeout):
        if nsamples<0: nsamples=2**32-1 # convert -1 -> maxint
        if nevents<0:  nevents =2**32-1 # convert -2 -> maxint
        request = struct.pack('HHIIII', VERSION, WAIT_DAT, 12, int(nsamples), int(nevents), int(timeout))
        self.sendRaw(request)

        (status, bufsize, resp_buf) = self.receiveResponse()

        if status != WAIT_OK or bufsize < 8:
            raise IOError('Wait request failed.')

        return struct.unpack('II', resp_buf[0:8])

if __name__ == "__main__":
    # Just a small demo for testing purposes...
    # This should be moved to a separate file at some point
    import sys

    hostname = 'localhost'
    port = 1972

    if len(sys.argv)>1:
        hostname = sys.argv[1]
    if len(sys.argv)>2:
        try:
            port = int(sys.argv[2])
        except:
            print('Error: second argument (%s) must be a valid (=integer) port number'%sys.argv[2])
            sys.exit(1)
        
    ftc = Client()        
        
    print('Trying to connect to buffer on %s:%i ...'%(hostname,port))
    ftc.connect(hostname, port)
    
    print('\nConnected - trying to read header...')
    H = ftc.getHeader()

    if H is None:
        print('Failed!')
    else:
        print(H)
        print(H.labels)

        if H.nSamples > 0:
            print('\nTrying to read last sample...')
            indices = H.nSamples - 1
            D = ftc.getData([indices, indices])
            print(D)

        if H.nEvents > 0:
            print('\nTrying to read last 100 events...')
            E = ftc.getEvents([max(0,H.nEvents-100), H.nEvents-1])
            for e in E:
                print(e)

        E=Event('test',1)
        print('\nTrying to put an event:'+str(E))
        ftc.putEvents(E)
        E=Event('test','str')
        print('\nTrying to put an event:'+str(E))
        ftc.putEvents(E)
        print('\n Reading sent event...')
        (nSamp,nEvents)=ftc.poll()
        E = ftc.getEvents([nEvents-2, nEvents-1])
        for e in E:
            print(e)

    print(ftc.poll())
    ftc.disconnect()
