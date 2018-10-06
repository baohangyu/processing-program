import processing.serial.*;

PFont myFont;

color myColor;

Serial myPort;
String serials[];
String mySerialName="COM5";  //需要设置
int val;
ArrayList<Float> myDataV0;
ArrayList<Float> myDataV1;

int chkState=0;  //检查数据格式状态
int chkData[];
int chkIndex=0;
int lastV0=0;    //最近的数值总电压值,数值，不是真实电压
int lastV1=0;    //最近的数值电阻的电压，数值，不是真实电压

float vRef=5.0;    //参考电压
float vVal=1023;  //参考值
float vR=1000;    //使用的1000欧的充电电阻

float vU0=0;  //总电压值
float vUr=0;  //电阻两端的电压
float vU=0;  //电容两端的电压
float vQ=0;  //电容所带的电量

int calcState=0;  //计算Q的状态
int jiluStartBz=0;  //记录开始标志

float interTime=0.01;  //时间间隔是0.02s

int drawJs=0;

Qingkong qk;



float vTopMargin=300;
float vBottomMargin=50;
float vLeftMargin=100;
float vRightMargin=100;
float vStep=10;
float vYStep=50;
float vMaxX=2500;  //最大计数值


void setup(){
  size(1200,700);
  background(0);
  
  myColor=color(200);
  qk=new Qingkong(width-175,25,150,50);
  chkData=new int[8];
  
  myDataV0=new ArrayList<Float>();
  myDataV1=new ArrayList<Float>();
  myFont=loadFont("ArialMT-72.vlw");
  textFont(myFont,42);
  myPort = new Serial(this, mySerialName, 9600);
  frameRate(10);
}

void draw(){
  background(0);
  noStroke();
  fill(100);
  rect(0,0,width,100);
  
  fill(60);
  rect(0,101,width,5);
  
  fill(100);
  rect(0,106,width,100);
  
  qk.display();
  drawCurve();
  readData();
  
  
    textFont(myFont,36);
    
    fill(255);
    int startX=10;
    text("count:",startX,75);
    fill(255,255,0);
    startX+=120;
    text(myDataV1.size(),startX,75);
    startX+=250;
    
    fill(255);
    text("V0: ",startX,75);
    fill(255,255,0);
    startX+=75;
    vU0=lastV0/vVal*vRef;
    text(getStr(vU0)+"v",startX,75);
    startX+=250;
    
    fill(255);
    text("V1: ",startX,75);
    fill(255,255,0);
    startX+=75;
    vUr=lastV1/vVal*vRef;
    text(getStr(vUr)+"v",startX,75);
    
    //第二行
    fill(255);
    startX=10;
    text("U:",startX,181);
    fill(220,220,255);
    startX+=50;
    text(getStr(vU)+"v",startX,181);
    startX+=250;
    
    
    fill(255);
    text("Q:",startX,181);
    fill(220,220,255);
    startX+=50;
    text(getStr6(vQ)+"C",startX,181);
    startX+=250;
    
    
    fill(220,220,255);
    text("I",vLeftMargin-20,vTopMargin+20);
    text("t",width-vRightMargin+20,height-vBottomMargin+20);
    
    
    
    
    
    
  
  
}


void readData(){
  byte[] inBuffer = new byte[100];
  while (myPort.available() > 0) {   
    int count=myPort.readBytes(inBuffer);
    for(int i=0;i<count;i++){
      int dataT=getUnsignedByte(inBuffer[i]);
      if(chkState==0){
        if(dataT==255){
          chkData[chkIndex]=dataT;
          chkState=1;
          chkIndex++;
        }
      }else if(chkState==1){
        if(dataT==0){
          chkData[chkIndex]=dataT;
          chkState=2;
          chkIndex++;
        }
      }else if(chkState==2){
        chkData[chkIndex]=dataT;
        chkIndex++;
        if(chkIndex==8){
          int sum=0;
          chkIndex=0;
          chkState=0;
          for(int j=0;j<7;j++){
            sum+=chkData[j];
          }
          int v0=chkData[3]*4+chkData[4];
          int v1=chkData[5]*4+chkData[6];
          if(chkData[7]==(sum%256)){
            if(v1>100){
              jiluStartBz=1;
            }
            if(jiluStartBz==1){
              if(v1>3){
                calcState=1;  //可以计算Q
                vU0=v0/vVal*vRef;
                vUr=v1/vVal*vRef;
                myDataV0.add(vU0);
                myDataV1.add(vUr);
                vU=vU0-vUr;
                float ir=vUr/vR;
                vQ+=ir*interTime;
                
                
              }else{
                if(calcState==1){
                  calculateQ();  //计算Q
                  calcState=0;
                }
                jiluStartBz=0;
              }
            }
            
            lastV0=v0;
            lastV1=v1;
          }else{
            v0=lastV0;
            v1=lastV1;
            if(v1>0&&jiluStartBz==1){
              vU0=v0/vVal*vRef;
              vUr=v1/vVal*vRef;
              myDataV0.add(vU0);
              myDataV1.add(vUr);
              vU=vU0-vUr;
              float ir=vUr/vR;
              vQ+=ir*interTime;
              
              
                
              
              
            }
          }
          
        }
      }
      
    }
    
  }
}


void mousePressed() {
  if(mouseX>=qk.x0&&mouseX<=qk.x1&&mouseY>=qk.y0&&mouseY<=qk.y1){
    myDataV0.clear();
    myDataV1.clear();
    vQ=0;
    vU=0;
  }
}

void mouseMoved() {
  if(mouseX>=qk.x0&&mouseX<=qk.x1&&mouseY>=qk.y0&&mouseY<=qk.y1){
    cursor(HAND);
    myColor=color(255,205,100);
  }else{
    myColor=color(200);
    cursor(ARROW);
  }
}

int getUnsignedByte (byte data){      //将data字节型数据转换为0~255 (0xFF 即BYTE)。
         return data&0x0FF ;
}

String getStr(float val){
  java.text.DecimalFormat df = new java.text.DecimalFormat("####.##");
  return df.format(val);
}

String getStr6(float val){
  java.text.DecimalFormat df = new java.text.DecimalFormat("####.######");
  return df.format(val);
}

//计算Q值
void calculateQ(){
  vQ=0;
  for(int i=0;i<myDataV1.size();i++){
    float ir=myDataV1.get(i)/vR;
    vQ+=ir*interTime;
  }
}



void drawCurve(){
  
  float vStartV=height-vBottomMargin-10;
  float vYStartV=vLeftMargin+vYStep;
  
  stroke(100);
  while(vStartV>vTopMargin){
    line(vLeftMargin,vStartV,width-vRightMargin,vStartV);
    vStartV-=vStep;
  }
  
  stroke(100);
  while(vYStartV<width-vRightMargin){
    line(vYStartV,vTopMargin,vYStartV,height-vBottomMargin);
    vYStartV+=vYStep;
  }
  
  stroke(255,255,0);
  line(vLeftMargin,vTopMargin,vLeftMargin,height-vBottomMargin);  //纵轴
  line(vLeftMargin,height-vBottomMargin,width-vRightMargin,height-vBottomMargin);  //横轴
  line(vLeftMargin,vTopMargin,width-vRightMargin,vTopMargin);  //上
  line(width-vRightMargin,vTopMargin,width-vRightMargin,height-vBottomMargin);  //上
  
  
  //绘图
  for(int k=0;k<myDataV1.size();k++){
    float drawX0=map(k,0,vMaxX,0,width-vLeftMargin-vRightMargin)+vLeftMargin;
    float drawY0=map(myDataV1.get(k),0,vRef,height-vTopMargin-vBottomMargin,0)+vTopMargin;
    noStroke();
    fill(200,200,255);
    ellipse(drawX0,drawY0,5,5);
  }
  
}