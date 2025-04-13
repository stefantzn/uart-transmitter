#define LED_PIN 2    

void setup() {

  // setup pins
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // setup serial
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, 16, 17);
}

unsigned long lastMessageTime = 0;  

void loop() {

  // start reading
  if (Serial2.available() > 0) {
    char c = Serial2.read();
    
    Serial.print("Received: ");
    Serial.println(c);
    
    // led turned on (rising edge) if recieved 1 via uart
    if (c == '1') {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("LED turned on");
    }

    // led turned off (falling edge) if received 0 via uart
    else if (c == '0') {
      digitalWrite(LED_PIN, LOW);
      Serial.println("LED turned off");
    }

    lastMessageTime = millis();
  }
  
  // no messages coming through
  if (millis() - lastMessageTime > 1000) {
    Serial.println("Received: Nothing :(");
    lastMessageTime = millis();
  }
}
