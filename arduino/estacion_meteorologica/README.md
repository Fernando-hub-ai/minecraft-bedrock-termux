# Estación Meteorológica Básica

## Componentes utilizados
- Arduino Uno
- DHT11 (temp/humedad)
- OLED 0.96" I2C (SSD1306)
- Servo SG90
- Módulo relé 1 canal
- Breadboard + cables Dupont

## Conexiones

| Componente       | Pin Arduino |
|------------------|-------------|
| DHT11 Data       | D7          |
| OLED SDA         | A4 (SDA)    |
| OLED SCL         | A5 (SCL)    |
| Servo señal      | D9          |
| Relé señal       | D8          |

### DHT11
- VCC → 5V
- DATA → D7 (con resistencia pull-up de 10kΩ a 5V)
- GND → GND

### OLED 0.96" I2C
- VCC → 5V
- GND → GND
- SDA → A4
- SCL → A5

### Servo SG90
- Rojo → 5V
- Café → GND
- Naranja → D9

### Relé
- VCC → 5V
- GND → GND
- IN → D8

## Comportamiento
- Muestra temperatura y humedad en la OLED cada 2 segundos.
- Si temperatura > 28°C:
  - Relé se activa (HIGH)
  - Servo gira a 90°
- Si temperatura ≤ 28°C:
  - Relé se desactiva
  - Servo vuelve a 0°

## Librerías necesarias (Instalar desde el Gestor de Librerías)
- Adafruit SSD1306
- Adafruit GFX
- DHT sensor library (by Adafruit)
- Servo (incluida con Arduino IDE)
