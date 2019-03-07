/**
 * View for the Signal Viewer. Handles everything that needs to be shown to the user.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */

import controlP5.*;

public class ProcessingSigViewer_View {  
  ControlP5 controlP5;
  private color col = color(128);
  private RadioButton r1, r2;
  private CheckBox c1, c2;
  private Textarea t1, t2, t3, t4;
  private boolean sigView = false;
  String text1 = "";
  String text2 = "";
  String text3 = "";
  String text4 = "";
  private boolean toggled = false;
  private GraphWindow gw;

  public void initializeGraphWindow() {
    gw = new GraphWindow();
  }

  public ProcessingSigViewer_View() {
  }

  public void makeSetup(ControlP5 cp5) {
    controlP5 = cp5;

    addOptionButtons();
    addTabs();
  }

  public void setSigView(boolean t) {
    sigView = t;
  }

  public void setNames(String[] names) {
    gw.setNames(names);
  }

  public void drawView() {
    background(col); //background with variable col, if col gets changed, the background colour changes
    drawBoxes();
    writeText();
    t1.setText(text1);
    t2.setText(text2); 
    t3.setText(text3);
    t4.setText(text4);
    if (sigView) {
      gw.drawGraphs();
    }
  }


  private void addTabs() {
    ControlFont theFont = new ControlFont(createFont("Times", (int)(0.0083*width)), (int)(0.0083*width));

    controlP5.setFont(theFont);

    int w = width/7;
    int h = height/20;
    color tabColor = color(204, 255, 255);
    color txtColor = color(0);

    controlP5.getTab("default").setWidth(w).setHeight(h)
      .setLabel("Time")
      .setId(1)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .activateEvent(true);
    ;

    controlP5.addTab("Frequency").setWidth(w)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(2)
      .setHeight(h)
      .activateEvent(true);
    ;


    controlP5.addTab("50 Hz").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(3)
      .activateEvent(true);
    ;

    controlP5.addTab("Noisefrac").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(4)
      .activateEvent(true);
    ;

    controlP5.addTab("Spect").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(5)
      .activateEvent(true);
    ;

    controlP5.addTab("Power").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(6)
      ;

    controlP5.addTab("Offset").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(7)
      .activateEvent(true);
    ;
  }

  public void changeColour(int n) {
    col=color(n);
  }

  private void addOptionButtons() {
    //preprocessing radiobutton group
    r1 = controlP5.addRadioButton("Standard Preprocessing", (int)(0.03*width), (int)(0.1*height)).setSize((int)(0.03*width), (int)(0.05*height));
    r1.addItem("None", 1);
    r1.addItem("Center", 2);
    r1.addItem("Detrend", 3);
    r1.moveTo("global");

    //Bad Chan Rm
    c1 = controlP5.addCheckBox("check1", (int)(0.03*width), (int)(0.3*height)).setSize((int)(0.03*width), (int)(0.05*height));
    c1.addItem("Bad Chan Rm", 4);
    c1.moveTo("global");
    t1 = controlP5.addTextarea("").setPosition((int)(0.03*width), (int)(0.37*height)).setSize((int)(0.15*width), (int)(0.03*height)).setColorBackground(0).setFont(createFont("arial", 20));
    t1.moveTo("global");

    // Spatial filter radiobutton group
    r2 = controlP5.addRadioButton("Spatial Filters", (int)(0.03*width), (int)(0.48*height)).setSize((int)(0.03*width), (int)(0.05*height));
    r2.addItem(" None", 5); // if this one is on, the r1 button with the same name dissapears, how to fix this?
    r2.addItem(" CAR", 6); //I don't think two items can have the same name
    r2.addItem(" SLAP", 7);
    r2.moveTo("global");
    r2.setSpacingRow(30);

    //Adapt Filter
    c2 = controlP5.addCheckBox("check2").setPosition((int)(0.13*width), (int)(0.48*height)).setSize((int)(0.03*width), (int)(0.05*height));
    c2.addItem("whiten", 9);
    c2.addItem("rm ArtCh", 10);
    c2.addItem("rm EMG", 11);
    c2.moveTo("global");
    c2.setSpacingRow(30);

    //Spectral Filter
    t2 = controlP5.addTextarea("Low Cut-Off").setPosition((int)(0.03*width), (int)(0.81*height)).setSize((int)(0.15*width), (int)(0.03*height)).setColorBackground(0).setFont(createFont("arial", 20));
    t2.moveTo("global"); 
    t3 = controlP5.addTextarea("High Cut-Off").setPosition((int)(0.03*width), (int)(0.88*height)).setSize((int)(0.15*width), (int)(0.03*height)).setColorBackground(0).setFont(createFont("arial", 20));
    t3.moveTo("global");

    t4 = controlP5.addTextarea("IP-adress").setPosition((int)(0.3*width), (int)(0.42*height)).setSize((int)(0.4*width), (int)(0.03*height)).setColorBackground(0).setFont(createFont("arial", 20));
    t4.moveTo("global");
  }

  private void writeText() {
    textSize(16);
    fill(color(0)); // letter colour
    text("Pre-processing", (0.027*width), (0.085*height)); // naming of the groups
    text("Spatial filter", (0.027*width), (0.47*height));
    text("Adapt filter", (0.127*width), (0.47*height));
    text("Spectral filter", (0.027*width), (0.8*height));
    textSize(12);
  }
  private void drawBoxes() {
    fill(color(110)); //fills the figures made after this line
    // rect belonging to pre-processing
    rect((0.025*width), (0.07*height), (0.17*width), (0.2*height));//blocks around the groups
    // rect belonging to Spatial Filter
    rect((0.025*width), (0.45*height), (0.075*width), (0.3*height));
    //  rect belonging to adapt filter
    rect((0.125*width), (0.45*height), (0.075*width), (0.3*height));
    //  rect belonging to Bad chan RM
    rect((0.025*width), (0.30*height), (0.17*width), (0.14*height));
    //  rect belonging to spectral filter
    rect((0.025*width), (0.77*height), (0.17*width), (0.2*height));
    // rect beloning to graphs
    fill(color(255));
    rect(((0.20*width)+20), (height/22)+10, (int)(0.77*width), (int)(0.99*height));
  }


  private boolean locationTextarea(Textarea ta) {
    return (abs(mouseX - ta.getPosition()[0]) < ((int)(0.13*width)) && 
      abs(mouseY - ta.getPosition()[1]) < ((int)(0.03*height)));
  }


  void keyPressed(ProcessingSigViewer_Controller controller) {

    if (locationTextarea(t1)) {
      if (keyCode == BACKSPACE || keyCode == 67) {
        text1 = deleteText(text1);
      } else if (keyCode == DELETE) {
        text1 = "";
      } else if (keyCode == ENTER) {
        controller.processTextField("Bad ch", t1);
      } else if (keyCode != SHIFT) {
        text1 += key;
      }
    } else if (locationTextarea(t2)) {
      if (keyCode == BACKSPACE || keyCode == 67) {
        text2 = deleteText(text2);
      }
      if (keyCode == ENTER || keyCode ==66) {
        controller.processTextField("Low cutoff", t2);
      } else if (keyCode == DELETE) {
        text2 = "";
      } else if (keyCode != SHIFT) {
        text2 += key;
      }
    } else if (locationTextarea(t3)) {
      if (keyCode == BACKSPACE || keyCode == 67) {
        text3 = deleteText(text3);
      }
      if (keyCode == ENTER || keyCode ==66) {
        controller.processTextField("High cutoff", t3);
      } else if (keyCode == DELETE) {
        text3 = "";
      } else if (keyCode != SHIFT) {
        text3 += key;
      }
    } else if (locationTextarea(t4)) {
      if (keyCode == ENTER || keyCode ==66) {
        controller.processTextField("IP", t4);
      }
      if (keyCode == BACKSPACE || keyCode == 67) {
        text4 = deleteText(text4);
      } else if (keyCode == DELETE) {
        text4 = "";
      } else if (keyCode == ENTER) {
        //controller.controlEvent();
      } else if (keyCode != SHIFT) {
        text4 += key;
      }
    }
  }

  private String deleteText(String text) {
    if (text.length() > 0) { 
      text = text.substring(0, text.length()-1);
    }
    return text;
  }

  void toggle(PApplet parent) {
    if (!toggled) {
      if (mouseInTextField()) {
        KetaiKeyboard.toggle(parent); 
        toggled = true;
      }
    } else {
      if (!mouseInTextField()) {
        KetaiKeyboard.toggle(parent); 
        toggled = false;
      }
    }
  }

// check whether the mous is in a text field.
  boolean mouseInTextField() {
    if ((abs(mouseX - t1.getPosition()[0]) < ((int)(0.13*width)) && abs(mouseY - t1.getPosition()[1]) < ((int)(0.03*height)))) //in bad ch rem textfield
      return true;
    else if (abs(mouseX - t2.getPosition()[0]) < ((int)(0.13*width)) && abs(mouseY - t2.getPosition()[1]) < ((int)(0.03*height))) //low cut off
      return true;
    else if (abs(mouseX - t3.getPosition()[0]) < ((int)(0.13*width)) && abs(mouseY - t3.getPosition()[1]) < ((int)(0.03*height))) //high cut off
      return true;
    else if (abs(mouseX - t4.getPosition()[0]) < ((int)(0.13*width)) && abs(mouseY - t4.getPosition()[1]) < ((int)(0.03*height))) {//ip
      if (t4.isVisible()) return true;
    }
    return false;
  }
}
