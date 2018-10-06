class Qingkong{
  private float x0;
  private float y0;
  private float x1;
  private float y1;
  private float w;
  private float h;
  public Qingkong(float x0,float y0,float w,float h){
    this.x0=x0;
    this.y0=y0;
    this.w=w;
    this.h=h;
    this.x1=x0+w;
    this.y1=y0+h;
  }
  
  public void display(){
    fill(myColor);
    stroke(255,105,20);
    rect(x0,y0,w,h);
    
    
    fill(50);
    
    text("clear", x0+32, y0+38);
  }
}