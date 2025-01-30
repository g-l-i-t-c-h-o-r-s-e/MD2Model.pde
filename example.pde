import java.util.Vector; //<>//
import java.util.Enumeration;
import peasy.*;

float zoom = 1.0;


MD2Model model;
MD2AliasTriangle triangle;
PShader shader;
PeasyCam cam;

void setup() {
  size(800, 600, P3D);
  noStroke();
  noSmooth();
  frameRate(60);

  cam = new PeasyCam(this, 500); // The second argument is the initial distance from the origin

  PImage texImage = loadImage("skinpage.jpg");
  model = new MD2Model("mareout.md2", texImage);

  //model.printAnimations();
  //shader = loadShader("flame.frag", "shader.vert");
}


void draw() {
  model.update();
  pushMatrix();
  drawproc();
  popMatrix();

  // Debugging information
  if (model != null) {
    // println("Current Frame: " + model.currentFrame + ", Next Frame: " + model.nextFrame);
  }
}


void drawproc() {
  background(0);
  lights();

  scale(4);
  noStroke();
  noSmooth();
  fill(255);
  model.draw();
}


void keyPressed() {
  if (key == 'o') {
    model.animationSpeed += 1; // Adjust the value for noticeable change
    println("Animation Speed Increased: " + model.animationSpeed);
  } else if (key == '-') {
    model.animationSpeed -= 10; // Adjust the value for noticeable change
    model.animationSpeed = max(model.animationSpeed, 1); // Prevent it from going below 1
    println("Animation Speed Decreased: " + model.animationSpeed);
  } else if (key == 'p' || key == 'P') {
    model.pingPongEffect = !model.pingPongEffect; // Toggle ping-pong effect
    println("Ping Pong Effect: " + model.pingPongEffect);
  } else if (key == '1') {
    model.setScale(1.0, 1.0, 1.0); // Reset to original scale
  } else if (key == '2') {
    model.setScale(5.0, 1.0, 1.0); // Scale only along X-axis
  }
}


void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom += e * 0.05;
  zoom = constrain(zoom, 0.5, 20.0); // Adjust these values as needed
}
