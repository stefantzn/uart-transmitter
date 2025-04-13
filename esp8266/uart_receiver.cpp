#define LED_PIN LED_BUILTIN  // This is GPIO2

unsigned long lastMessageTime = 0;
const unsigned long timeoutInterval = 1000; 

void setup() {

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);

  //  115200 baud
  Serial.begin(115200);
  while (!Serial) {
    ; 
  }
  
  lastMessageTime = millis();
}

void loop() {

  if (Serial.available() > 0) {

    char incomingByte = Serial.read();  
    Serial.println(incomingByte);

    // LED on (for some reason the LED is active low, so I drive the LED low)
    if (incomingByte == '1') {
      digitalWrite(LED_PIN, LOW);
      Serial.println("LED turned ON");
    }
    // LED off
    else if (incomingByte == '0') {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("LED turned OFF");
    }

    lastMessageTime = millis();
  }

  // Idle messages
  if (millis() - lastMessageTime >= timeoutInterval) {

    Serial.println("Received: Nothing :(");
    lastMessageTime = millis(); 
  }
}
