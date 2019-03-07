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

  public void controlt4(Textarea t) {
    t.setVisible(false);
    model.setIp(t.getStringValue());

    model.makeBuffer();
    view.setNames(model.getHeader().labels);
    view.setSigView(true);
    println(model.getIp());
  }

  public void controlEvent(ControlEvent theEvent) { // Here you state what happens when a certain button is activated
    if (theEvent.isGroup() && theEvent.getName().equals("Standard Preprocessing")) {
      println("Standard processing");
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

  public void processTextField(String fieldName, Textarea textField) {
    String input;
    switch(fieldName) {
      case("Bad ch"):    
      break;
      case("High cutoff"):
      input = textField.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setHighFreq(freq);
      }
      break;
      case("Low cutoff"):
      input = textField.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setLowFreq(freq);
      }
      break;
      case("IP"):
      textField.setVisible(false);
      model.setIp(textField.getStringValue());
      println("IP Set");
      model.makeBuffer();
      println("sigviewer made");
      view.initializeGraphWindow();
      view.setNames(model.getHeader().labels);
      view.setSigView(true);

      break;
    default:
      break;
    }
  }
}
