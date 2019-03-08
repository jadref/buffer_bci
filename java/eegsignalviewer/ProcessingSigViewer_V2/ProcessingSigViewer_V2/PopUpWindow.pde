/**
 * The window which pops up at the start to ask for an IP-address.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */

import controlP5.*;

class OtherSketch extends PApplet {

private Textfield text;
private String Ip;
ControlP5 cp;
private ProcessingSigViewer_V2 parent;
private ProcessingSigViewer_Model model;
private ProcessingSigViewer_View view;
private ProcessingSigViewer_Controller controller;

public OtherSketch(ProcessingSigViewer_V2 parent, ProcessingSigViewer_Model model, ProcessingSigViewer_View view, ProcessingSigViewer_Controller controller)
  {
    //store a reference to the first sketch so we can do things with it
    this.parent = parent;
    this.view = view;
    this.model = model;
    this.controller = controller;
 
    ////This will actually launch the new sketch
    runSketch(new String[] {
      "OtherSketch"  //must match the name of this class
      }
      , this);  //the second argument makes sure this sketch is created instead of a brand new one...
    
  }
  public void settings() {
    size((int)(0.2*parent.width),(int)(0.2*parent.height));
  }
  
  public void setup(){
    cp = new ControlP5(this);
    text = cp.addTextfield("IP-adress").setPosition((int)(0.3*width), (int)(0.42*height)).setSize((int)(0.4*width), 20).setValue("127.0.0.1"); 
  }
  //setStringValue
 
  public void draw() {
    background(125, 125, 125);
  }

  public void exit()
  {
    parent.otherSketch = null;
    dispose();
  }
    void controlEvent(ControlEvent theEvent) {  
     controller.controlEvent(theEvent);
  }



public void input(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'input' : "+theText);
}

  public String getIP(){
    return Ip;
  }
}
