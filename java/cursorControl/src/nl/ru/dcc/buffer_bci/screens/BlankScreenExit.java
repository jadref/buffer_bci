package nl.ru.dcc.buffer_bci.screens;
import java.awt.*;

public class BlankScreenExit extends BlankScreen {

    @Override
    public void draw(Component c, Graphics g){
        super.draw(c,g);
        System.exit(0);
    }

    @Override
    public void update(float delta) {
    }
}
