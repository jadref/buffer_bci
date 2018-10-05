package nl.ru.dcc.buffer_bci.screens;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class AddressInputScreen extends InstructScreen {
    public String host;
    public int port;
    
    public AddressInputScreen(String host, int port){
        super("Please enter host:port in diaglog box");
        this.host=host;
        this.port=port;
    }

    public void update(){
        String text = (String)JOptionPane.showInputDialog(null,null,
                                                          "Enter Utopia Server Address",
                                                          JOptionPane.QUESTION_MESSAGE,
                                                          null,
                                                          null,
                                                          this.host+":"+this.port);
        if( text == null ) { // user cancelled
            setDuration(0);
        } else {
            try {
                // parse the input, finish screen if successfully parsed
                String split[] = text.split(":");
                host = split[0];
                port = Integer.parseInt(split[1]);
                setDuration(0); // successful
            } catch (NumberFormatException e) {
            }
        }
    }
}
