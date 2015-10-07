package nl.dcc.fieldtripthreads.base;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public interface AndroidHandle {

	public FileInputStream openReadFile(String path) throws IOException;

	public FileOutputStream openWriteFile(String path) throws IOException;

	public void toast(String message);

	public void toastLong(String message);

	public void updateStatus(String status);

}
