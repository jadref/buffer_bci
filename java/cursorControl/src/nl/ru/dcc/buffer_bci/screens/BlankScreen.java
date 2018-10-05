package nl.ru.dcc.buffer_bci.screens;
import java.awt.*;

public class BlankScreen extends StimulusScreen {
    @Override
    public void draw(Component c, Graphics g) {
        g.setColor(WINDOWBACKGROUNDCOLOR);
        g.fillRect(0,0,c.getWidth(),c.getHeight());
    }
    @Override
    public void update(float delta) {}
}
