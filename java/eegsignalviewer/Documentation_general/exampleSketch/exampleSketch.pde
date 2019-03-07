void setup() {
  size(640, 360);
}
int xPos = 30;
int yPos = 50;
int margin = 20;

void draw() {
  rect(xPos, yPos, 100, 50, 7);
  //smooth();//????
  fill(#FFFFFF); // if you dont fill the rectangle here, it is filled by whatever next fill, which is the text so then you cant read anything...

  textSize(10);
  text("Hello World!", xPos + margin, yPos + margin+10);
  fill(#000000);
  
}
