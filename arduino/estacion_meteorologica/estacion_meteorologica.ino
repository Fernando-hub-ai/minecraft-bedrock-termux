#include <LiquidCrystal.h>

// Indicamos los pines: RS, Enable, D4, D5, D6, D7
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

void setup() {
  lcd.begin(16, 2);        // La pantalla tiene 16 columnas y 2 filas
  lcd.print("Hola Mundo!"); // Esto se escribe en la primera fila
}

void loop() {
  lcd.setCursor(0, 1);     // Nos movemos a la fila 2 (índice 1), columna 0
  lcd.print("Arduino Uno");
}
