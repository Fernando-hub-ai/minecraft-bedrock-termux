#include <Wire.h>
#include <RTClib.h>

RTC_DS3231 rtc;

void setup() {
  Serial.begin(9600);
  if (!rtc.begin()) {
    Serial.println("No se encuentra el módulo RTC");
    while (1);
  }
  // La siguiente línea ajusta el RTC a la fecha y hora de compilación de tu PC:
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__))); 
  Serial.println("¡Hora configurada exitosamente!");
}

void loop() {
  // Déjalo vacío
}

            