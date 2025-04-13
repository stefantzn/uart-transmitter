#define LED_PIN 13  
int incomingByte = 0;           
unsigned long lastMessageTime = 0;
const unsigned long timeoutInterval = 1000; // 1 second timeout

void setup() {

  // initialize the  LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Baud rate = 115200
  Serial.begin(115200);

  // wait for serial monitor to open
  while (!Serial) {
    ; 
  }

  lastMessageTime = millis();
}

void loop() {

  // check if there is incoming data
  if (Serial.available() > 0) {

    // read data
    incomingByte = Serial.read();
    
    // LED on (rising edge)
    if (incomingByte == '1') {

      digitalWrite(LED_PIN, HIGH);
      Serial.println("LED turned on");
    }

    // LED off (falling edge)
    else if (incomingByte == '0') {

      digitalWrite(LED_PIN, LOW);
      Serial.println("LED turned off");
    }
    
    lastMessageTime = millis();
  }
  
  // Idle message
  if (millis() - lastMessageTime >= timeoutInterval) {

    Serial.println("Received: Nothing :(");

    lastMessageTime = millis();  
  }
}
