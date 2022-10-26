/*
Plug&Sense Smart Security

Sensors:
                          | A | B | C | D | E | F |
                          |-----------------------|
  BME280                  |   |   |   |   | X |   |
  Ultrasound              | X |   |   |   |   |   |
  Liquid Flow             |   | X |   |   |   |   |
  Liquid Presence line    |   |   |   | X |   |   |
  Luminosity              |   |   | X |   |   |   |
                          |-----------------------|

  Socket F empty -> Only Relay Input-Output can be put on this socket for this station

Communication:
  XBee 868LP

Extra functions:
  RS485 bus (Not used in this instance)
*/

#include <WaspSensorEvent_v30.h> // specific librari for reading sensor values for Plug&Sense Smart Security station. 
#include <WaspXBee868LP.h> // library for the communication module
#include <WaspFrame.h>


char RX_ADDRESS[] = "0013A20041C3B126";

uint8_t error = 0;

// variables for storing data from sensors:
float temp;
float humd;
float pres;
uint16_t dist = 0;
uint32_t luxes = 0;
float flow = 0;
uint8_t line = 0;

flowClass yfg1(SENS_FLOW_YFG1);
liquidPresenceClass liquidPresence(SOCKET_D);

// functions for reading the sensors:
void ReadBME280(); // Reading temperature, hummidity and pressure values

void ReadUltrasound(); // reading the distance from the ultrasound sensor

void ReadLux(); // reading the luminosity level from the lux sensor

void ReadFlow(); // reading the water flow 

void ReadLine(); // reading liquid presence from liquid line sensor

void CreateFrame(uint8_t frame_type); // creading the frame that contains the sensor data

void sendPacket(); // send the frame to meshlium 

void DeepSleep(); // enter deep sleep for 30 minutes then wake up. 

//############################################################################################################

void setup()
{
  USB.ON();
  USB.println(F("Start program"));
  
  // Turn on the sensor board
  Events.ON();

    // Enable interruptions from the board
  Events.attachInt();

    // set Waspmote identifier
  frame.setID("TeleSmartSec1");

  // init XBee
  xbee868LP.ON( SOCKET1 );
}

//############################################################################################################

void loop()
{
  
  USB.println("New loop");

  ReadBME280();
  ReadUltrasound();
  ReadLux();
  ReadFlow();
  ReadLine();
  
  CreateFrame(BINARY);
  SendPacket();
  
  DeepSleep();
  
}
//############################################################################################################

// Function definitions

void ReadBME280(){
  
  //Temperature
  temp = Events.getTemperature();
  //Humidity
  humd = Events.getHumidity();
  //Pressure
  pres = Events.getPressure();
  
  USB.println("-----------------------------");
  USB.print("Temperature: ");
  USB.printFloat(temp, 2);
  USB.println(F(" Celsius"));
  USB.print("Humidity: ");
  USB.printFloat(humd, 1); 
  USB.println(F(" %")); 
  USB.print("Pressure: ");
  USB.printFloat(pres, 2); 
  USB.println(F(" Pa")); 
  USB.println("-----------------------------");
  
}

void ReadFlow(){

  flow = yfg1.flowReading();

  // Print the flow read value
  USB.println("-----------------------------");
  USB.print(F("Flow: "));
  USB.print(flow);
  USB.println(F(" l/min"));
  USB.println("-----------------------------");

}

void DeepSleep(){

  USB.println(F("enter deep sleep for 10 seconds"));
  PWR.deepSleep("00:00:30:00", RTC_OFFSET, RTC_ALM1_MODE1, SENSOR_ON);

  USB.ON();
  Events.ON();
  USB.println(F("wake up\n"));
  
}

void CreateFrame(uint8_t frame_type){

  // 1.1. create new frame
  USB.println(F("..CREATING FRAME PROCESS "));
  frame.createFrame(frame_type);

  // 1.2. add frame fields

  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel() );
  frame.addSensor(SENSOR_EVENTS_TC, temp);
  frame.addSensor(SENSOR_EVENTS_HUM, humd);
  frame.addSensor(SENSOR_EVENTS_PRES, pres);
  frame.addSensor(SENSOR_EVENTS_US, dist);
  frame.addSensor(SENSOR_EVENTS_LUXES, luxes);
  frame.addSensor(SENSOR_EVENTS_WF, flow); 
  frame.addSensor(SENSOR_EVENTS_LL, line);
  
  USB.println(F("\n1. Created frame to be sent:"));
  frame.showFrame();

}

void SendPacket() {

  USB.println(F("\nTry to send a packet..."));

  // send XBee packet
  error = xbee868LP.send( RX_ADDRESS, frame.buffer, frame.length );

  USB.println(F("\nSend a packet to the RX node: "));

  // check TX flag
  if ( error == 0 )
  {
    USB.println(F("send ok"));
  }
  else
  {
    USB.println(F("send error: "));
    USB.print(error);
  }

}

void ReadUltrasound(){
  
dist = Events.getDistance();  

  // Print values through the USB
  USB.println("-----------------------------");
  USB.print(F("Distance: "));
  USB.print(dist);
  USB.println(F(" cm"));
  USB.println("-----------------------------");
  
}

void ReadLux(){

  // Options:
  //    - OUTDOOR
  //    - INDOOR

luxes = Events.getLuxes(INDOOR);  

  USB.println("-----------------------------"); 
  USB.print(F("Luxes: "));
  USB.print(luxes);
  USB.println(F(" lux"));
  USB.println("-----------------------------");
  
}

void ReadLine(){

  line = liquidPresence.readliquidPresence();
  USB.println("-----------------------------"); 
  USB.print(F("Liquid detect: "));
  USB.print(line);
  USB.println("\n-----------------------------");
}

