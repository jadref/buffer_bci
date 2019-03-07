
/**
 * Controller for the Signal Viewer. Handles all external events.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
public class ProcessingSigViewer_Controller {

  private ProcessingSigViewer_Model model;
  private ProcessingSigViewer_View view;

  public void ProcessingSigViewer_Controller() {
  }

  public void setModelView(ProcessingSigViewer_Model model, ProcessingSigViewer_View view) {
    this.model=model;
    this.view=view;
  }


  /**
   * Big control function for all possible events (e.g. buttons, textfields)
   * @param theEvent - the event that is happening (e.g. a button is clicked) 
   */
  public void controlEvent(ControlEvent theEvent) { // Here you state what happens when a certain button is activated
    //Standard Preprocessing
    if (theEvent.isGroup() && theEvent.getName().equals("Standard Preprocessing")) {
      println(theEvent.getArrayValue());
      switch((int)theEvent.getValue()) {
        case(1): // None
        model.setFilter(Filter.NONE);
        break;
        case(2): // Center
        model.setFilter(Filter.CENTER);
        break;
        case(3): // Detrend
        model.setFilter(Filter.DETREND);
        break;
      }
    }
    if (theEvent.isGroup() && theEvent.getName().equals("Spatial Filters")) {
      println(theEvent.getArrayValue());
      switch((int)theEvent.getValue()) {
        case(5): // None
        model.setFilter(SpatialFilter.NONE);
        break;
        case(6): // CAR
        model.setFilter(SpatialFilter.CAR);
        break;
        case(7): // SLAP
        model.setFilter(SpatialFilter.SLAP);
        break;
      }
    }
    //Gets the IP-address from the text field
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("IP-adress")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      println(model.getIp());
      model.setIp(theEvent.getStringValue());
      model.makeBuffer();
      view.initializeGraphWindow();
      view.setNames(model.getHeader().labels);
      view.setSigView(true);      
      println(model.getIp());
    }
    //Reads the Low Cut-Off
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("Low Cut-Off")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      String input = theEvent.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setLowFreq(freq);
      }
    }
    //Reads the High Cut-Off
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("High Cut-Off")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      String input = theEvent.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setHighFreq(freq);
      }
    }
    //For switching between view types
    if (theEvent.getName().equals("default")) {
      model.setViewType(ViewType.TIME);
    }
    if (theEvent.getName().equals("Frequency")) {
      model.setViewType(ViewType.FREQUENCY);
    }
    if (theEvent.getName().equals("50 Hz")) {
      model.setViewType(ViewType.HZ);
    }
    if (theEvent.getName().equals("Noisefrac")) {
      model.setViewType(ViewType.NOISEFRAC);
    }
    if (theEvent.getName().equals("Spect")) {
      model.setViewType(ViewType.SPECT);
    }
    if (theEvent.getName().equals("Power")) {
      model.setViewType(ViewType.POWER);
    }
    if (theEvent.getName().equals("Offset")) {
      model.setViewType(ViewType.OFFSET);
    }
  }
}
