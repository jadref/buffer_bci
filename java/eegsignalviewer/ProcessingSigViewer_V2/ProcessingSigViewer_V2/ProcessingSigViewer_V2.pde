// @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeinde
// * 2018/2019
//This is the main. 
//please try not to add anything here, since this will be visible in all other code.
//If you add another file to this project make sure it is a new separate class. If this is not done it will be considered part of the main by processing.

//import processing.android.PFragment;
import processing.core.PApplet;

private ProcessingSigViewer_Model model;
private ProcessingSigViewer_View view;
private ProcessingSigViewer_Controller controller;
private OtherSketch otherSketch;


public void settings() {
  fullScreen();
  //size(500,500); //when developing you might want to use this instead of fullScreen, such that it is easier to use.
}
// this is the firts thing that is called by processing automatically when you run the program. This is the base setup of your program. Do not run this seperately. 

public void setup() {
  this.model = new ProcessingSigViewer_Model();
  //for the android version:
  //model.popUp(this);
  model.setBufferClientClock(this);
  //model.makeSigViewer(this);

  this.view=new ProcessingSigViewer_View();
  view.makeSetup(new ControlP5(this));
  this.controller=new ProcessingSigViewer_Controller();
  controller.setModelView(model, view);
   
  otherSketch = new OtherSketch(this, model, view, controller);
}

// This function is executed in a loop by processing, starting right after the setup(). At the end of this function, the screen is updated.
public void draw() {
  view.drawView();
}

//For some reason it is necessary to call this here to get the button functionality to work.
//If anyone can figure out a way to move this to the controller entirely please do.
public void controlEvent(ControlEvent theEvent) {
  controller.controlEvent(theEvent);
}
