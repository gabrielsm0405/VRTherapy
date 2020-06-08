import processing.serial.*;
import gifAnimation.*;
import org.gicentre.utils.stat.*;

final int CONEXAO = 0;
final int COMUNICACAO = 1;

int PARAMETROPASSO = 5000;
int PARAMETROLEVANTA = 40000;

int tempoDiv = 30;

Serial btserial;

int estado = CONEXAO;

boolean blueConectado = false, tryBluetooth = false;

private class Dado{
    int x, y, z;
    int emg1, emg2;
    long tempo;
    int derX, derY, derZ, derEMG1, derEMG2;
}
ArrayList<Dado> dados = new ArrayList<Dado>();

Gif blueLoading;

XYChart x, y, z, emg1, emg2;

Table table;
String tableName="dados.csv";

boolean arquivoAberto = false;

PImage erro;

PFont fonte;

long initTime = 0, initTimeGraph = 0;

boolean pausa = false;

boolean tempoIniciado = false;

int inicioPlot=0;

boolean close = false;

int preX = 0, preY = 0, preZ = 0, preEMG1 = 0, preEMG2 = 0;
long preTime = 0;

long intervalStore = millis();
//String[] lines; //MODIFICAÇÃO

TextBox parametroLevanta = new TextBox();
TextBox parametroPasso = new TextBox();

public Event keyboardEvents[] = new Event[2];
public Event mouseEvents = new Event();

void keyPressed(){
  keyboardEvents[0].put(key);
  keyboardEvents[1].put(keyCode);
}

void mousePressed(){
  mouseEvents.put(mouseButton);
}

void setup(){
  //lines = loadStrings("teste_passo_3.txt"); //MODIFICAÇÃO
  size(displayWidth, displayHeight);
  background(#021B35);
  
  blueLoading = new Gif(this, "blueloading.gif");
  blueLoading.play();
  
  erro = loadImage("erro.png");
  
  x = new XYChart(this);
  x.setMaxY(65535);
  x.setMinY(0);
  x.setLineWidth(2);
  x.showXAxis(true);
  x.showYAxis(true);
  
  y = new XYChart(this);
  y.setMaxY(65535);
  y.setMinY(0);
  y.setLineWidth(2);
  y.showXAxis(true);
  y.showYAxis(true);
  
  z = new XYChart(this);
  z.setMaxY(65535);
  z.setMinY(0);
  z.setLineWidth(2);
  z.showXAxis(true);
  z.showYAxis(true);
  
  emg1 = new XYChart(this);
  emg1.setMaxY(65535);
  emg1.setMinY(0);
  emg1.setLineWidth(2);
  emg1.showXAxis(true);
  emg1.showYAxis(true);
  
  emg2 = new XYChart(this);
  emg2.setMaxY(65535);
  emg2.setMinY(0);
  emg2.setLineWidth(2);
  emg2.showXAxis(true);
  emg2.showYAxis(true);
  
  table = new Table();
  table.addColumn("Tempo");
  table.addColumn("X");
  table.addColumn("Y");
  table.addColumn("Z");
  table.addColumn("EMG1");
  table.addColumn("EMG2");
  table.addColumn("Modulo da derivada X");
  table.addColumn("Modulo da derivada Y");
  table.addColumn("Modulo da derivada Z");
  table.addColumn("Modulo da derivada EMG1");
  table.addColumn("Modulo da derivada EMG2");
  
  fonte = loadFont("ProcessingSansPro-Semibold-48.vlw");
  textFont(fonte);
  
  keyboardEvents[0]=new Event();
  keyboardEvents[1]=new Event();
  
  parametroLevanta.defineName("parametroLevanta");
  parametroLevanta.sizeTextBox(100, 25);
  parametroLevanta.posTextBox(925, 5);
  parametroLevanta.defineForm("rect");
  parametroLevanta.defineFillColor(255);
  parametroLevanta.defineCursor("TEXT");
  parametroLevanta.defineTextFont("ProcessingSansPro-Semibold-48.vlw", 20);
  parametroLevanta.definePassinAction("noAction");
  parametroLevanta.text = "40000";
  
  parametroPasso.defineName("parametroPasso");
  parametroPasso.sizeTextBox(100, 25);
  parametroPasso.posTextBox(1225, 5);
  parametroPasso.defineForm("rect");
  parametroPasso.defineFillColor(255);
  parametroPasso.defineCursor("TEXT");
  parametroPasso.defineTextFont("ProcessingSansPro-Semibold-48.vlw", 20);
  parametroPasso.definePassinAction("noAction");
  parametroPasso.text = "5000";
}

boolean createdThreadRecebimento = false;
void draw(){
  switch(estado){
    case CONEXAO:
      conexao();
      
      if(tryBluetooth){
        if(!createdThreadRecebimento){
          initTimeGraph = millis();
          thread("recebimento");
          
          createdThreadRecebimento = true;
        }
        
        if(blueConectado){
          estado = COMUNICACAO;
          background(#021B35);
        }
      }
    break;
    case COMUNICACAO:
      comunicacao();
      
      if(!blueConectado && !pausa){
         estado = CONEXAO;
         
         background(#021B35);
      }
    break;
  }
  
  attEvents();
}

boolean createdThread = false, passarEstado = false;
void conexao(){  
  imageMode(CENTER);
  image(blueLoading, displayWidth/2, displayHeight/2);
  
  if(!createdThread && !tryBluetooth){
    createdThread = true;
    thread("tryBluetooth"); 
  }  
}

int c1 = 0;
void tryBluetooth(){
  do{
    if(c1 >= Serial.list().length){
      c1 = 0;
    }
    
    try{
      btserial = new Serial(this, Serial.list()[c1], 9600);
    }
    catch(RuntimeException e){}
    
    c1++;
  }while(btserial == null);
  
  
  tryBluetooth = true;
    
  createdThread = false;
}

long interval = millis();
long intervalTest = millis();
int contDoc = 0;
void recebimento(){
  final int ESPERARFLAG = 0;
  final int ESPERARDADOS = 1;
  
  long blueInterval = millis();
  int estado = ESPERARFLAG, cont = 0;
  int datain = 1; 
  int x=0, y=0, z=0, emg1=0, emg2=0;
  
  while(true){
    switch(estado){
      case ESPERARFLAG:     
        if(btserial.available() > 0){
        //if((long) millis() - intervalTest >= 5){
          //intervalTest = millis();
          datain = btserial.read();
          datain = 240;
          
          if(datain == 240){
            cont++;
          }
          else{
            cont = 0; 
          }
        }
        
        if(cont == 2){
          cont = 0;
          x = 0;
          y = 0;
          z = 0;
          emg1 = 0;
          emg2 = 0;
          
          estado = ESPERARDADOS;
        }
      break;
      case ESPERARDADOS:
        if(btserial.available() > 0){
        //if((long) millis() - intervalTest >= 5){
          //intervalTest = millis();
          datain = btserial.read();
          //datain = 128;
          
          if(datain != 240){
           cont++;
           if(cont <= 2) x = x << 8 | datain;
           else if(cont <= 4) y = y << 8 | datain;
           else if(cont <= 6) z = z << 8 | datain;
           else if(cont <= 8) emg1 = emg1 << 8 | datain;
           else if(cont <= 10) emg2 = emg2 << 8 | datain;
           
           if(cont == 10){
             cont = 0;
             estado = ESPERARFLAG;
             
             //MODIFICAÇÃO
             //String[] coord = split(lines[contDoc], "\t");
             //contDoc++;
             //if(contDoc >= lines.length) contDoc = 0;
             //println("X= "+coord[0]+"  Y= "+coord[1]+"  Z= "+coord[2]);
               //x = int(coord[0]);
               //y = int(coord[1]);
               //z = int(coord[2]);             
               
             Dado medicao = new Dado();
             
             if(!tempoIniciado){
              initTime = millis();
              tempoIniciado = true;
             }
             medicao.tempo = millis() - initTime;
             
             medicao.x = x;
             medicao.y = y;
             medicao.z = z;
             medicao.emg1 = emg1;
             medicao.emg2 = emg2;
             if(medicao.tempo != 0){ 
               medicao.derX = 45*abs(medicao.x - preX)/(int) (medicao.tempo - preTime);
               medicao.derY = 45*abs(medicao.y - preY)/(int) (medicao.tempo - preTime);
               medicao.derZ = 45*abs(medicao.z - preZ)/(int) (medicao.tempo - preTime);
               medicao.derEMG1 = 45*abs(medicao.emg1 - preEMG1)/(int) (medicao.tempo - preTime);
               medicao.derEMG2 = 45*abs(medicao.emg2 - preEMG2)/(int) (medicao.tempo - preTime);
             }
             
             preX = medicao.x;
             preY = medicao.y;
             preZ = medicao.z;
             preEMG1 = medicao.emg1;
             preEMG2 = medicao.emg2;
             preTime = medicao.tempo;
             
             dados.add(medicao);
             
             blueInterval = millis();
             blueConectado = true;
           }
          }
          else{
            cont = 1;
            estado = ESPERARFLAG;
          }
        }
      break;
    }
    
    if((long) millis() - blueInterval >= 5000){
      println("Bluetooth Desconectado");
      btserial.stop();
      cont = 0;
      inicioPlot = dados.size();
      blueConectado = false;
      tryBluetooth = false;
      createdThreadRecebimento = false;
      return;
    }
    
    if(close){
      println("closing thread");
      btserial.stop();
      return; 
    }
    
    delay(1);
  }
}

boolean controlKey = false;
boolean val = true, der = false;
float XF=0, YF=0, ZF=0, XFANT=0;
long tempoLev = millis(), tempoSen = millis();
boolean levantado = false, pico = false, mudanca = false, estadoAnt = false, possivelPasso = false;
long tempoPico = millis(), tempoMudanca = millis(), tempoPossivelPasso = millis();
int contPassos = 0;
void comunicacao(){
  int tamDados = tempoDiv;
  if(tamDados > dados.size()){
    tamDados = dados.size();
  }
  
  if(key == ' ' && keyPressed && !controlKey){
    pausa = !pausa;
    inicioPlot = dados.size();
  }
  controlKey = keyPressed;
  
  if(!pausa){
    float xx[] = new float[tamDados];
    float xy[] = new float[tamDados];
    
    float yx[] = new float[tamDados];
    float yy[] = new float[tamDados];
    
    float zx[] = new float[tamDados];
    float zy[] = new float[tamDados];
    
    float emg1x[] = new float[tamDados];
    float emg1y[] = new float[tamDados];
    
    float emg2x[] = new float[tamDados];
    float emg2y[] = new float[tamDados];
    
    if(tamDados + inicioPlot < dados.size()){
      for(int c1=inicioPlot; c1 < tamDados + inicioPlot; c1++){
        xx[c1-inicioPlot] = dados.get(c1).tempo-initTimeGraph;
        if(val){
          XF = 0*XF + 1*dados.get(c1).x;
          //xy[c1-inicioPlot] = dados.get(c1).x; MODIFICAÇÃO
          xy[c1-inicioPlot] = XF;          
        }
        else if(der){
          xy[c1-inicioPlot] = dados.get(c1).derX;
        }
        
        yx[c1-inicioPlot] = dados.get(c1).tempo-initTimeGraph;
        if(val){
          YF = 0.9*YF + 0.1*dados.get(c1).y;
          //yy[c1-inicioPlot] = dados.get(c1).y; MODIFICAÇÃO
          yy[c1-inicioPlot] = YF;
        }
        else if(der){
          yy[c1-inicioPlot] = dados.get(c1).derY;
        }
        
        zx[c1-inicioPlot] = dados.get(c1).tempo-initTimeGraph;
        if(val){
          ZF = 0.9*ZF + 0.1*dados.get(c1).z;
          //zy[c1-inicioPlot] = dados.get(c1).z; MODIFICAÇÃO
          zy[c1-inicioPlot] = ZF;
        }
        else if(der){
          zy[c1-inicioPlot] = dados.get(c1).derZ;
        }
        
        emg1x[c1-inicioPlot] = dados.get(c1).tempo-initTimeGraph;
        if(val){
          emg1y[c1-inicioPlot] = dados.get(c1).emg1;
        }
        else if(der){
          emg1y[c1-inicioPlot] = dados.get(c1).derEMG1;
        }
        
        emg2x[c1-inicioPlot] = dados.get(c1).tempo-initTimeGraph;
        if(val){
          emg2y[c1-inicioPlot] = dados.get(c1).emg2;
        }
        else if(der){
          emg2y[c1-inicioPlot] = dados.get(c1).derEMG2;
        }
      }
      
      //MODIFICAÇÃO
      if(ZF>PARAMETROLEVANTA){
        //if((long) millis() - tempoLev >= 500){
          //tempoSen = millis();
          if(estadoAnt == false){
            println("Levantou");
            mudanca = true;
            tempoMudanca = millis();
          }
          levantado = true;
          estadoAnt = true;
        //}
      }
      else{
        //if((long) millis() - tempoSen >= 500){
          //tempoLev = millis();
          if(estadoAnt == true){
            println("Sentou");
             mudanca = true;
             tempoMudanca = millis();
          }
          levantado = false;
          estadoAnt = false;
        //}
      }
      if(mudanca){
          if((long) millis() - tempoMudanca >= 1000){
            mudanca = false;  
          }
      }
      //if(levantado) println("Levantado");
      //else println("Sentado");
      
      if(XF>=PARAMETROPASSO + 30000){
        pico = true;
        tempoPico = millis();
      }
      else if(pico){
          if((long) millis() - tempoPico >= 500){
            pico = false;
          }
          
          if(XF<= 30000 - PARAMETROPASSO){
              pico = false;
              possivelPasso = true;
              tempoPossivelPasso = millis();
          }
      }
      
      if(possivelPasso){
          //if((long) millis() - tempoPossivelPasso >= 500){
            if(mudanca == false){
              println("Deu um passo");
              contPassos++;
            }
            possivelPasso = false;
          //}
      }
      
      x.setData(xx, xy);
      
      y.setData(yx, yy);
      
      z.setData(zx, zy);
      
      emg1.setData(emg1x, emg1y);
      
      emg2.setData(emg2x, emg2y);
      
      inicioPlot++;
      
      if((long) millis() - intervalStore >= 5000){
        for(int c1=0; c1<inicioPlot; c1++){
          TableRow newRow = table.addRow();
          
          newRow.setLong("Tempo", dados.get(c1).tempo);
          newRow.setInt("X", dados.get(c1).x);
          newRow.setInt("Y", dados.get(c1).y);
          newRow.setInt("Z", dados.get(c1).z);
          newRow.setInt("EMG1", dados.get(c1).emg1);
          newRow.setInt("EMG2", dados.get(c1).emg2);
          newRow.setInt("Modulo da derivada X", dados.get(c1).derX);
          newRow.setInt("Modulo da derivada Y", dados.get(c1).derY);
          newRow.setInt("Modulo da derivada Z", dados.get(c1).derZ);
          newRow.setInt("Modulo da derivada EMG1", dados.get(c1).derEMG1);
          newRow.setInt("Modulo da derivada EMG2", dados.get(c1).derEMG2);
        }
        try{
          saveTable(table, tableName);
          arquivoAberto = false;
        }
        catch(NullPointerException e){
          arquivoAberto = true;
        }
        
        for(int c1=0; c1<inicioPlot; c1++){
          dados.remove(0);
        }
        inicioPlot = 0;
        
        if(!arquivoAberto){
          intervalStore = millis();
        }
      }
    }
  }
  else if(arquivoAberto){
     background(#021B35);
     imageMode(CENTER);
     image(erro, displayWidth/2, displayHeight/2);
     textAlign(CENTER);
     textSize(25);
     text("O Arquivo de Amazenamento esta sendo usado", displayWidth/2, displayHeight/2+erro.height*4/5);
     inicioPlot = dados.size();
  }
  
  background(#021B35);
  
  textSize(15);
  x.draw(10, 20, (width-10)/3, (height-20)/2);
  y.draw(10+(width-10)/3, 20, (width-10)/3, (height-20)/2);
  z.draw(10+2*(width-10)/3, 20, (width-10)/3, (height-20)/2);
  emg1.draw(10, 20+(height-10)/2, (width-10)/2, (height-85)/2);
  emg2.draw(10+(width-10)/2, 20+(height-10)/2, (width-10)/2, (height-85)/2);
  
  if(pausa){
    PVector mouseCoord = new PVector();
    mouseCoord.x = mouseX;
    mouseCoord.y = mouseY;
    
    if(mouseX>=10 && mouseX<=10+(width-10)/3 && mouseY>=10 && mouseY<=10+(height-10)/2 && x.getScreenToData(mouseCoord) != null){
      detalhamento(x.getScreenToData(mouseCoord));
    }
    if(mouseX>=10+(width-10)/3 && mouseX<=10+(width-10)/3+(width-10)/3 && mouseY>=10 && mouseY<=10+(height-10)/2 && y.getScreenToData(mouseCoord) != null){
      detalhamento(y.getScreenToData(mouseCoord));
    }
    if(mouseX>=10+2*(width-10)/3 && mouseX<=10+2*(width-10)/3+(width-10)/3 && mouseY>=10 && mouseY<=10+(height-10)/2 && z.getScreenToData(mouseCoord) != null){
      detalhamento(z.getScreenToData(mouseCoord));
    }
    if(mouseX>=10 && mouseX<=10+(width-10)/2 && mouseY>=10+(height-10)/2 && mouseY<=10+(height-10)/2+(height-75)/2 && emg1.getScreenToData(mouseCoord) != null){
      detalhamento(emg1.getScreenToData(mouseCoord));
    }
    if(mouseX>=10+(width-10)/2 && mouseX<=10+(width-10)/2+(width-10)/2 && mouseY>=10+(height-10)/2 && mouseY<=10+(height-10)/2+(height-75)/2 && emg2.getScreenToData(mouseCoord) != null){
      detalhamento(emg2.getScreenToData(mouseCoord));
    }
  }
  
  fill(255);
  textSize(20);
  text("Eixo X", 10 + (width-10)/6, 20+10);
  text("Eixo Y", 10+(width-10)/3 + (width-10)/6, 20+10);
  text("Eixo Z", 10+2*(width-10)/3 + (width-10)/6, 20+10);
  text("EMG 1", 10 + (width-10)/4, 20+(height-10)/2 + 10);
  text("EMG 2", 10+(width-10)/2 + (width-10)/4, 20+(height-10)/2 + 10);
  
  if(arquivoAberto){
    rectMode(CENTER);
    fill(255);
    rect(width/2, height/2, width*1/3, height*1/3);
    imageMode(CENTER);
    erro.resize(width*1/3/4, 0);
    image(erro, width/2, height/2);
    
    textAlign(CENTER);
    fill(0);
    text("O arquivo de armazenamento está aberto", width/2, height/2+height*1/3/3);
  }
  
  int corVal = #FFFFFF, corDer = #FFFFFF;
  if(mouseX>=10 && mouseX<=10+10 && mouseY>=5 && mouseY<=5+10){
    corVal = #B4B2B2;
    if(mousePressed){
      val = true;
      der = false;
    }
  }
  else{
    corVal = #FFFFFF;
  }
  if(mouseX>=60 && mouseX<=60+10 && mouseY>=5 && mouseY<=5+10){
    corDer = #B4B2B2;
    if(mousePressed){
      val = false;
      der = true;
    }
  }
  else{
    corDer = #FFFFFF;
  }
  
  if(val){
    corVal = #B4B2B2; 
  }
  if(der){
    corDer = #B4B2B2; 
  }
  
  rectMode(CORNER);
  textAlign(LEFT);
  fill(corVal);
  rect(10, 5, 10, 10);
  text("Val", 10+12, 5+10);
  fill(corDer);
  rect(60, 5, 10, 10);
  text("|Der|", 60+12, 5+10);
  
  if(levantado == true){
    text("Levantado", 110+12, 5+10);  
  }
  else{
    text("Sentado", 110+12, 5+10);  
  }
  
  text("Contador de passos: "+str(contPassos), 400+12, 5+10);
  
  text("Parametro Levanta: ", 700, 5+10);
  text("Parametro Passo: ", 1000, 5+10);
  
  parametroLevanta.TextBox();
  parametroPasso.TextBox();
  
  PARAMETROLEVANTA = int(parametroLevanta.text);
  PARAMETROPASSO = int(parametroPasso.text);
}

void detalhamento(PVector coord){
  int tamX = 100, tamY = 50;
  int posY = mouseY;
  
  if(mouseY-tamY - tamY <= 0){
    posY = mouseY + tamY;
  }
  
  noStroke();
  fill(#AFAAAA, 50);
  rect(mouseX, posY-tamY, tamX, tamY);
  
  fill(255);
  text("X: " + str(coord.x), mouseX+tamX/10, posY-tamY*2/3);
  text("Y: " + str(coord.y), mouseX+tamX/10, posY-tamY*0.5/3);
}

void mouseWheel(MouseEvent event){
  float e = event.getCount();
  int tamX = 50, tamY = 25;
  int posY = mouseY;
  
  if(!pausa && blueConectado){
    tempoDiv += e;
  
    if(tempoDiv<5) tempoDiv = 5;
    if(tempoDiv>50) tempoDiv = 50;
  
    if(mouseY-tamY - tamY <= 0){
      posY = mouseY + tamY;
    }
  
    noStroke();
    fill(#AFAAAA, 50);
    rect(mouseX, posY-tamY, tamX, tamY);
  
    fill(255);
    text(nf((float) 50/tempoDiv*10, 1, 1) + "%", mouseX+tamX/10, posY-tamY*1.5/3);
  }
}

void exit() {
  close = true;
  delay(1000);
 
  super.exit();
}

void attEvents(){
  mouseEvents.removeOne();
  keyboardEvents[0].removeOne();
  keyboardEvents[1].removeOne();
}
