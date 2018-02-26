
PImage img;

int rows = 30;
int columns = 30;

int radius = 2;
float gravity = 50;
PVector[][] pos = new PVector[columns][rows];
PVector[][] vel = new PVector[columns][rows];
PVector[][] preSums = new PVector[columns][rows];
PVector airVel = new PVector(30, 0, 0);
PVector spherePos = new PVector(175, 130, 27.3);

float elapsedTime;
float startTime;

float restLength = 2;
float mass = 10;
float tension = 0.91;

float k = 6000;
float kd = 3000;
float kv = 20;

float sphereRadius = 15;
float sphereFriction = 0.8;

float airDensity = 1.225;
float dragCoefficient = 1.05;

float eyeX = 127.3;
float eyeY = 125;
float eyeZ = 120;
float centerX = 150;
float centerY = 130;
float centerZ = 27.3;
float upX = 0;
float upY = 1;
float upZ = 0;

void setup() {
  size(1000, 800, P3D);
  img = loadImage("The_Last_of_Us_Fireflies_Logo.png");
  
  camera(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ);
  perspective(PI / 3, 4 / 3, 0.1, 500);
  
  pos[0][0] = new PVector(100, 100, 0);  // first node
  vel[0][0] = new PVector(0, 0, 0);
  preSums[0][0] = new PVector(0, 0, 0);
  
  for(int i = 1; i < columns; i++) {  // top row
    pos[i][0] = new PVector(100, 100, pos[i-1][0].z + restLength * tension);
    vel[i][0] = new PVector(0, 0, 0);
    preSums[i][0] = new PVector(0, 0, 0);
  }
  
  for(int i = 0; i < columns; i++) {  // rest of nodes
    for(int j = 1; j < rows; j++) {
      pos[i][j] = new PVector(pos[i][j-1].x + restLength * tension, pos[i][j-1].y, pos[i][j-1].z);
      vel[i][j] = new PVector(0, 0, 0);
      preSums[i][j] = new PVector(0, 0, 0);
    }
  }
  sphereDetail(20);
  startTime = millis();
}

void draw() {
  background(125);
  println(frameRate);
  Update(elapsedTime/10000.0);  // purposely dividing by 10k instead of 1k
  TimeStep();
  CheckColWithSphere();
  UpdateCamera();
  Render();
}

void TimeStep() {
  elapsedTime = millis() - startTime;
  startTime = millis();
}

void Update(float dt) {
  for(int t = 0; t < 10; t++) {  // run our update 10 times with smaller timesteps
    //reset preSums
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows; j++) {
        preSums[i][j] = new PVector(0, 0, 0);
      }
    }
    
    //horizontal
    for(int i = 0; i < columns - 1; i++) {
      for(int j = 0; j < rows; j++) {  // run through columns, skip top one
     
          PVector e = new PVector(pos[i+1][j].x - pos[i][j].x, 
                                  pos[i+1][j].y - pos[i][j].y, 
                                  pos[i+1][j].z - pos[i][j].z);
                                  
          float stringLen = sqrt(e.dot(e));
          e = new PVector(e.x / stringLen, e.y / stringLen, e.z / stringLen);
          
          float v1 = e.dot(vel[i][j]);
          float v2 = e.dot(vel[i+1][j]);
          
          float stringF = -k * (tension * restLength - stringLen);
          float dampF = -kv * (v1 - v2);
          float totForce = stringF + dampF;
          
          preSums[i][j] = new PVector(preSums[i][j].x + totForce * e.x * dt, 
                                      preSums[i][j].y + totForce * e.y * dt, 
                                      preSums[i][j].z + totForce * e.z * dt);;

          preSums[i+1][j] = new PVector(preSums[i+1][j].x - totForce * e.x * dt, 
                                        preSums[i+1][j].y - totForce * e.y * dt, 
                                        preSums[i+1][j].z - totForce * e.z * dt);
      }
    }
    //vertical
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows - 1; j++) {
     
          PVector e = new PVector(pos[i][j+1].x - pos[i][j].x, 
                                  pos[i][j+1].y - pos[i][j].y, 
                                  pos[i][j+1].z - pos[i][j].z);  

          float stringLen = sqrt(e.dot(e));
          e = new PVector(e.x / stringLen, e.y / stringLen, e.z / stringLen);
          
          float v1 = e.dot(vel[i][j]);
          float v2 = e.dot(vel[i][j+1]);
          
          float stringF = -k * (tension * restLength - stringLen);
          float dampF = -kv * (v1 - v2);
          float totForce = stringF + dampF;
          
          preSums[i][j] = new PVector(preSums[i][j].x + totForce * e.x * dt, 
                                      preSums[i][j].y + totForce * e.y * dt, 
                                      preSums[i][j].z + totForce * e.z * dt);

          preSums[i][j+1] = new PVector(preSums[i][j+1].x - totForce * e.x * dt, 
                                        preSums[i][j+1].y - totForce * e.y * dt, 
                                        preSums[i][j+1].z - totForce * e.z * dt);  
      }
    }
    //diag to the right
    for(int i = 0; i < columns - 2; i+=2) {
      for(int j = 0; j < rows - 2; j+=2) {
          float diagRestLength = 2 * sqrt(2) * restLength;
          PVector e = new PVector(pos[i+2][j+2].x - pos[i][j].x, 
                                  pos[i+2][j+2].y - pos[i][j].y, 
                                  pos[i+2][j+2].z - pos[i][j].z);
                                  
          float stringLen = sqrt(sq(e.x) + sq(e.y) + sq(e.z));
          e = new PVector(e.x / stringLen, e.y / stringLen, e.z / stringLen);
          
          float v1 = e.dot(vel[i][j]);
          float v2 = e.dot(vel[i+2][j+2]);
          
          float stringF = -kd * (tension * diagRestLength - stringLen);
          float dampF = -kv * (v1 - v2);
          float totForce= stringF + dampF;
          
          preSums[i][j] = new PVector(preSums[i][j].x + totForce* e.x * dt, 
                                      preSums[i][j].y + totForce* e.y * dt, 
                                      preSums[i][j].z + totForce* e.z * dt);

          preSums[i+2][j+2] = new PVector(preSums[i+2][j+2].x - totForce* e.x * dt, 
                                          preSums[i+2][j+2].y - totForce* e.y * dt, 
                                          preSums[i+2][j+2].z - totForce* e.z * dt);  
      }
    }
    //diag to the left
    for(int i = 2; i < columns; i+=2) {
      for(int j = 0; j < rows - 2; j+=2) {
          float diagRestLength = 2 * sqrt(2) * restLength;
          PVector e = new PVector(pos[i-2][j+2].x - pos[i][j].x, 
                                  pos[i-2][j+2].y - pos[i][j].y, 
                                  pos[i-2][j+2].z - pos[i][j].z);
                                  
          float stringLen = sqrt(sq(e.x) + sq(e.y) + sq(e.z));
          e = new PVector(e.x / stringLen, e.y / stringLen, e.z / stringLen);
          
          float v1 = e.dot(vel[i][j]);
          float v2 = e.dot(vel[i-2][j+2]);
          
          float stringF = -kd * (tension * diagRestLength - stringLen);
          float dampF = -kv * (v1 - v2);
          float totForce= stringF + dampF;
          
          preSums[i][j] = new PVector(preSums[i][j].x + totForce* e.x * dt, 
                                      preSums[i][j].y + totForce* e.y * dt, 
                                      preSums[i][j].z + totForce* e.z * dt);

          preSums[i-2][j+2] = new PVector(preSums[i-2][j+2].x - totForce* e.x * dt, 
                                          preSums[i-2][j+2].y - totForce* e.y * dt, 
                                          preSums[i-2][j+2].z - totForce* e.z * dt);  
      }
    }
    //drag
    for(int i = 0; i < columns - 1; i++) {
      for(int j = 0; j < rows - 1; j++) {
        PVector avgVel = new PVector(
        (vel[i][j].x + vel[i+1][j].x + vel[i][j+1].x)/3 - airVel.x,
        (vel[i][j].y + vel[i+1][j].y + vel[i][j+1].y)/3 - airVel.y,
        (vel[i][j].z + vel[i+1][j].z + vel[i][j+1].z)/3 - airVel.z);
        
        PVector right = new PVector(pos[i+1][j].x - pos[i][j].x,
                                    pos[i+1][j].y - pos[i][j].y,
                                    pos[i+1][j].z - pos[i][j].z);
        PVector down = new PVector(pos[i][j+1].x - pos[i][j].x,
                                   pos[i][j+1].y - pos[i][j].y,
                                   pos[i][j+1].z - pos[i][j].z);
        
        PVector norm = down.cross(right);
        
        PVector terms = new PVector(norm.x * avgVel.mag() * (avgVel.dot(norm)) / (2 * norm.mag()),
                                    norm.y * avgVel.mag() * (avgVel.dot(norm)) / (2 * norm.mag()),
                                    norm.z * avgVel.mag() * (avgVel.dot(norm)) / (2 * norm.mag()));
                                    
        float multiplyingFactor = -(1.0/8.0) * airDensity * dragCoefficient;
        
        PVector forceAero = new PVector(terms.x * multiplyingFactor,
                                        terms.y * multiplyingFactor,
                                        terms.z * multiplyingFactor);

        preSums[i][j] = new PVector(preSums[i][j].x + forceAero.x * dt,
                                    preSums[i][j].y + forceAero.y * dt,
                                    preSums[i][j].z + forceAero.z * dt);

        preSums[i+1][j] = new PVector(preSums[i+1][j].x + forceAero.x * dt,
                                      preSums[i+1][j].y + forceAero.y * dt,
                                      preSums[i+1][j].z + forceAero.z * dt);

        preSums[i+1][j+1] = new PVector(preSums[i+1][j+1].x + forceAero.x * dt,
                                        preSums[i+1][j+1].y + forceAero.y * dt,
                                        preSums[i+1][j+1].z + forceAero.z * dt);

        preSums[i][j+1] = new PVector(preSums[i][j+1].x + forceAero.x * dt,
                                      preSums[i][j+1].y + forceAero.y * dt,
                                      preSums[i][j+1].z + forceAero.z * dt);
      }
    }
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows; j++) {
        vel[i][j] = new PVector(vel[i][j].x + preSums[i][j].x,
                                vel[i][j].y + preSums[i][j].y + gravity * dt,
                                vel[i][j].z + preSums[i][j].z);
                                
        pos[i][j] = new PVector(pos[i][j].x + vel[i][j].x * dt, 
                                pos[i][j].y + vel[i][j].y * dt, 
                                pos[i][j].z + vel[i][j].z * dt);
      }
    }
    /*//fix top row
    for(int i = 0; i < columns; i++) {
      pos[i][0] = new PVector(pos[i][0].x - vel[i][0].x * dt, 
                              pos[i][0].y - vel[i][0].y * dt, 
                              pos[i][0].z - vel[i][0].z * dt);
      vel[i][0] = new PVector(0, 0, 0);
    }*/
  }
}

//check and see if points in cloth collide with sphere
void CheckColWithSphere() {
  for(int i = 0; i < columns; i++) {
    for(int j = 0; j < rows; j++) {
      float collisionDistance = sphereRadius + 0.1;
      
      PVector norm = new PVector(pos[i][j].x - spherePos.x, 
                                 pos[i][j].y - spherePos.y, 
                                 pos[i][j].z - spherePos.z); 
                              
      float distance = sqrt(sq(norm.x) + sq(norm.y) + sq(norm.z));
      
      if(distance < collisionDistance) {        
        norm = norm.normalize();
        float dist = collisionDistance - distance;
        
        pos[i][j] = new PVector(pos[i][j].x + dist * norm.x,
                                pos[i][j].y + dist * norm.y,
                                pos[i][j].z + dist * norm.z);
                                
        float reflect = vel[i][j].dot(norm);
        
        vel[i][j] = new PVector((vel[i][j].x - 2 * reflect * norm.x) * sphereFriction,
                                (vel[i][j].y - 2 * reflect * norm.y) * sphereFriction,
                                (vel[i][j].z - 2 * reflect * norm.z) * sphereFriction);
      }
    }
  }           
}

// camera rotation and movement
void UpdateCamera() {
    /*
  eye:wasd
  look:mouse = sin(dy)*sin(dx) * look
  right = look.cross(up)
  up = look.cross(right)
  */
  if (keyPressed) {
    if(key == 'w' || key == 'W') {
      eyeZ -= 1;
      centerZ -= 1;
    }
    if (key == 's' || key == 'S') {
      eyeZ += 1;
      centerZ += 1;
    }
    if (key == 'a' || key == 'A') {
      eyeX -= 1;
      centerX -= 1;
    }
    if (key == 'd' || key == 'D') {
      eyeX += 1;
      centerX += 1;
    }
      camera(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ);
  }
}  



void Render() {
  pushMatrix();
  fill(255, 0, 0);
  noStroke();
  translate(spherePos.x, spherePos.y, spherePos.z);
  sphere(sphereRadius);
  popMatrix();

  for(int i = 0; i < columns - 1; i++) {
    for(int j = 0; j < rows - 1; j++) {
      beginShape(QUADS);
      texture(img);
      vertex(pos[i][j].x, pos[i][j].y, pos[i][j].z, i * img.width / (columns - 1), j * img.height / (rows - 1));
      vertex(pos[i+1][j].x, pos[i+1][j].y, pos[i+1][j].z, (i + 1) * img.width / (columns - 1), j * img.height / (rows - 1));
      vertex(pos[i+1][j+1].x, pos[i+1][j+1].y, pos[i+1][j+1].z, (i + 1) * img.width / (columns - 1), (j + 1) * img.height / (rows - 1));
      vertex(pos[i][j+1].x, pos[i][j+1].y, pos[i][j+1].z, i * img.width / (columns - 1), (j + 1) * img.height / (rows - 1));  
      endShape();
    }
  }
}
      