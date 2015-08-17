#!/bin/bash
cd `dirname $0`
mcs /r:../../dataAcq/buffer/csharp/FieldTrip.Buffer.dll csharpclient/csharpclient.cs
