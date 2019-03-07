// @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeinde
// * 2018/2019
//This is the main. 
//please try not to add anything here, since this will be visible in all other coded.
//If you add another file to this project make sure it is a new separate class. If this is not done it will be considered part of the main by processing.
//Note: the methods in this file are public because however 

//import processing.android.PFragment;
import processing.core.PApplet;

private ProcessingSigViewer_Model model;
private ProcessingSigViewer_View view;
private ProcessingSigViewer_Controller controller;


public void settings() {
  fullScreen();
  //size(500,500);
}
public void setup() {
  this.model = new ProcessingSigViewer_Model();
  //model.popUp(this);
  model.setBufferClientClock(this);
  //model.makeSigViewer(this);

  this.view=new ProcessingSigViewer_View();
  view.makeSetup(new ControlP5(this));
  this.controller=new ProcessingSigViewer_Controller();
  controller.setModelView(model, view);

  //otherSketch = new OtherSketch(this, model, view, controller);
}


public void draw() {
  view.drawView();
}

//For some reason it is necessary to call this here to get the button functionality to work.
//If anyone can figure out a way to move this to the controller entirely please do.
void controlEvent(ControlEvent theEvent) {
  controller.controlEvent(theEvent);
}

public void mousePressed() {
  view.toggle(this);
}

public void keyPressed() {
  view.keyPressed(controller);
}
