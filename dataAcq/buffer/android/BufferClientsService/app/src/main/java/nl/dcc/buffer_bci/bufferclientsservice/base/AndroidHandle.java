package nl.dcc.buffer_bci.bufferclientsservice.base;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public interface AndroidHandle {

    FileInputStream openReadFile(String path) throws IOException;

    InputStream openAsset(String path) throws IOException;

    FileOutputStream openWriteFile(String path) throws IOException;

    void toast(String message);

    void toastLong(String message);

    void updateStatus(String status);
}
