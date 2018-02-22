
import peasy.PeasyCam;

PeasyCam camera;

int rows = 30;
int columns = 30;

int radius = 2;
float gravity = 0.05;
PVector[][] pos = new PVector[columns][rows];
PVector[][] vel = new PVector[columns][rows];
PVector spherePos = new PVector(130, 125, 30);

float elapsedTime;
float startTime;

float restLength = 2;
float mass = 0.5;
float tension = 0.91;

float k = 2000;
float kv = 80;

float sphereRadius = 10;

void setup() {
  size(1000, 800, P3D);

  camera = new PeasyCam(this, 120, 120, (width/48.0) / tan (PI*30.0 / 180.0), 100);
  camera.setSuppressRollRotationMode();
  
  pos[0][0] = new PVector(100, 100, 0);  // first node
  vel[0][0] = new PVector(0, 0, 0);
  
  for(int i = 1; i < columns; i++) {  // top row
    pos[i][0] = new PVector(100, 100, pos[i-1][0].z + restLength * tension);
    vel[i][0] = new PVector(0, 0, 0);
  }
  
  for(int i = 0; i < columns; i++) {  // rest of nodes
    for(int j = 1; j < rows; j++) {
      pos[i][j] = new PVector(pos[i][j-1].x + restLength * tension, pos[i][j-1].y, pos[i][j-1].z);
      vel[i][j] = new PVector(0, 0, 0);
    }
  }
  sphereDetail(20);
  startTime = millis();
}

void draw() {
  background(255);
  println(frameRate);
  TimeStep();
  Update(elapsedTime/10000.0);  // purposely dividing by 10k instead of 1k
  CheckColWithSphere();
  Render();
}

void TimeStep() {
  elapsedTime = millis() - startTime;
  startTime = millis();
}

void Update(float dt) {
  for(int t = 0; t < 10; t++) {  // run our update 10 times with smaller timesteps
    
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
          float force = stringF + dampF;
          
          vel[i][j] = new PVector(vel[i][j].x + force * e.x * dt, 
                                  vel[i][j].y + force * e.y * dt, 
                                  vel[i][j].z + force * e.z * dt);;
          vel[i+1][j] = new PVector(vel[i+1][j].x - force * e.x * dt, 
                                    vel[i+1][j].y - force * e.y * dt, 
                                    vel[i+1][j].z - force * e.z * dt);
      }
    }
    //vertical
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows - 1; j++) {
     
          PVector e = new PVector(pos[i][j+1].x - pos[i][j].x, 
                                  pos[i][j+1].y - pos[i][j].y, 
                                  pos[i][j+1].z - pos[i][j].z);
                                  
          float stringLen = sqrt(sq(e.x) + sq(e.y) + sq(e.z));
          e = new PVector(e.x / stringLen, e.y / stringLen, e.z / stringLen);
          
          float v1 = e.dot(vel[i][j]);
          float v2 = e.dot(vel[i][j+1]);
          
          float stringF = -k * (tension * restLength - stringLen);
          float dampF = -kv * (v1 - v2);
          float force = stringF + dampF;
          
          vel[i][j] = new PVector(vel[i][j].x + force * e.x * dt, 
                                  vel[i][j].y + force * e.y * dt, 
                                  vel[i][j].z + force * e.z * dt);
          vel[i][j+1] = new PVector(vel[i][j+1].x - force * e.x * dt, 
                                    vel[i][j+1].y - force * e.y * dt, 
                                    vel[i][j+1].z - force * e.z * dt);  
      }
    }
    //gravity
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows; j++) {
        vel[i][j] = new PVector(vel[i][j].x, vel[i][j].y + gravity, vel[i][j].z);
      }
    }
    //fix top row
  //  for(int i = 0; i < columns; i++) {
    //  pos[i][0].y = 100;
    //  vel[i][0] = new PVector(0, 0, 0);
   // }
    for(int i = 0; i < columns; i++) {
      for(int j = 0; j < rows; j++) {
        pos[i][j] = new PVector(pos[i][j].x + vel[i][j].x * dt, 
                                pos[i][j].y + vel[i][j].y * dt, 
                                pos[i][j].z + vel[i][j].z * dt);
      }
    }
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
        
        vel[i][j] = new PVector((vel[i][j].x - 2 * reflect * norm.x) * 0.9,
                                (vel[i][j].y - 2 * reflect * norm.y) * 0.9,
                                (vel[i][j].z - 2 * reflect * norm.z) * 0.9);
      }
    }
  }
            
}



void Render() {
  pushMatrix();
  fill(255, 0, 0);
  noStroke();
  translate(spherePos.x, spherePos.y, spherePos.z);
  sphere(sphereRadius);
  popMatrix();
  stroke(1);
  
    strokeWeight(1);
  //horizontal
  for(int i = 0; i < columns - 1; i++) {  // rest of the columns
    for(int j = 0; j < rows; j++) {
      line(pos[i][j].x, pos[i][j].y, pos[i][j].z, pos[i+1][j].x, pos[i+1][j].y, pos[i+1][j].z);
    }
  }
  //vertical
  for(int i = 0; i < columns; i++) {  // rest of the columns
    for(int j = 0; j < rows - 1; j++) {
      line(pos[i][j].x, pos[i][j].y, pos[i][j].z, pos[i][j+1].x, pos[i][j+1].y, pos[i][j+1].z);
    }
  }
  fill(0, 0, 0);
  strokeWeight(4);
  // points
  for(int i = 0; i < columns; i++) {
    for(int j = 0; j < rows; j++) {
     point(pos[i][j].x, pos[i][j].y, pos[i][j].z);
    }
  }
}
      