package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * Created by Lars on 1-12-2015.
 */
public class InstructScreen extends CursorControlScreen {
    private static final BitmapFont font = new BitmapFont(Gdx.files.internal("data/font16.fnt"), Gdx.files.internal("data/font16.png"), false);

    private String instruction;
    private SpriteBatch batch;
    private GlyphLayout layout;

    public InstructScreen() {
        this("");
    }


    public InstructScreen(String instruction) {
        this.instruction = instruction;
        batch = new SpriteBatch();
        layout = new GlyphLayout();
    }

    public void setInstruction(String instruction) {
        this.instruction = instruction;
        layout.setText(font, instruction);
    }

    @Override
    public void draw() {
        int x = (int)(getWidth()* .1);
        int y = (int)(getHeight() - (getHeight() * .3)); // In GL, y is flipped.

        Gdx.gl.glClearColor(0,0,0,0);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        batch.begin();
        font.draw(batch, layout, x, y);
        batch.end();
    }

    @Override
    public void update(float delta) {

    }

    @Override
    public void dispose() {
        super.dispose();

        batch.dispose();
    }
}
