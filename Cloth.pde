
import peasy.PeasyCam;

PeasyCam cam;

int columns = 30;
int rows = 30;

int radius = 2;
float gravity = 50;

PVector[][] pos = new PVector[rows][columns];
PVector[][] vel = new PVector[rows][columns];
PVector[][] force = new PVector[rows][columns];

double elapsedTime;
double startTime;

float restLength = 20;
float mass = 1;
float tension = 0.94;

float k = 1000;
float kv = 300;

void setup() {
  size(1000, 800, P3D);
  
  cam = new PeasyCam(this, 400);
  
  pos[0][0] = new PVector(100, 100, 0);  // first node
  vel[0][0] = new PVector(0, 0, 0);
  force[0][0] = new PVector(0, 0, 0);
  
  for(int i = 1; i < rows; i++) {  // top row
    pos[i][0] = new PVector(100, 100, pos[i-1][0].z + restLength);
    vel[i][0] = new PVector(0, 0, 0);
    force[i][0] = new PVector(0, 0, 0);
  }
  
  for(int i = 0; i < rows; i++) {  // rest of nodes
    for(int j = 1; j < columns; j++) {
      pos[i][j] = new PVector(pos[i][j-1].x + restLength, pos[i][j-1].y, pos[i][j-1].z);
      vel[i][j] = new PVector(0, 0, 0);
      force[i][j] = new PVector(0, 0, 0);
    }
  }
  fill(0);
  startTime = millis();
}

void draw() {
  background(255);
  TimeStep();
  Update(elapsedTime/10000.0);  // purposely dividing by 10k instead of 1k
  Render();
}

void TimeStep() {
  elapsedTime = millis() - startTime;
  startTime = millis();
}

void Update(double dt) {
  for(int t = 0; t < 10; t++) {  // run our update 10 times with smaller timesteps
    
    for(int i = 0; i < rows; i++) {  
      for(int j = 1; j < columns; j++) {  // run through rows, skip top one
          float dx = (pos[i][j].x - pos[i][j-1].x);
          float dy = (pos[i][j].y - pos[i][j-1].y);
          float dz = (pos[i][j].z - pos[i][j-1].z);
          float stringLen = sqrt(sq(dx) + sq(dy) + sq(dz));
          float stringF = -k * (stringLen - tension * restLength);
          
          float dirX = dx / stringLen;
          float dirY = dy / stringLen;
          float dirZ = dz / stringLen;
          
          float dampFY = -kv * (vel[i][j].y - vel[i][j-1].y);
          float dampFX = -kv * (vel[i][j].x - vel[i][j-1].x);
          float dampFZ = -kv * (vel[i][j].z - vel[i][j-1].z);
          
          force[i][j].x = stringF * dirX + dampFX;
          force[i][j].y = stringF * dirY + dampFY;
          force[i][j].z = stringF * dirZ + dampFZ;
          
          float accY;
          float accX;
          float accZ;
          
          if(i+1 < rows) {
            accX = 0.5 * force[i][j].x / mass - 0.5 * force[i+1][j].x / mass;
          } else {
            accX = force[i][j].x / mass;
          }
          
          if(j+1 < columns) {
            accY = gravity + 0.5 * force[i][j].y / mass - 0.5 * force[i][j+1].y / mass;
          } else {
            accY = gravity + force[i][j].y / mass;
          }
          
          accZ = force[i][j].z / mass;
        
          vel[i][j].x += accX * dt;
          vel[i][j].y += accY * dt;
          vel[i][j].z += accZ * dt;
          
          pos[i][j].x += vel[i][j].x * dt;
          pos[i][j].y += vel[i][j].y * dt;
          pos[i][j].z += vel[i][j].z * dt;
      }
    }
  }
  for(int i = 0; i < rows; i++) {
    pos[i][0].y = 100;
  }
}

void Render() {
  for(int i = 0; i < rows; i++) {  // top row
    point(pos[i][0].x, pos[i][0].y, pos[i][0].z);
  }
  for(int i = 0; i < rows; i++) {  // rest of the rows
    for(int j = 1; j < columns; j++) {
      strokeWeight(1);
      line(pos[i][j].x, pos[i][j].y, pos[i][j].z, pos[i][j-1].x, pos[i][j-1].y, pos[i][j-1].z);
      strokeWeight(4);
      point(pos[i][j].x, pos[i][j].y, pos[i][j].z);
    }
  }
}
      