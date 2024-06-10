/*macro definitions of Rotary angle sensor and LED pin*/
// 超音波
#include "Ultrasonic.h"
Ultrasonic ultrasonic(6); //D6ピン

// 温湿度
#include "Grove_Temperature_And_Humidity_Sensor.h"
#define DHTTYPE DHT22 //このセンサ
#define DHTPIN 4 //4ピン
DHT dht(DHTPIN, DHTTYPE);
#if defined(ARDUINO_ARCH_AVR)
  #define debug Serial
#elif defined(ARDUINO_ARCH_SAMD) || defined(ARDUINO_ARCH_SAM)
  #define debug SerialUSB
#else
  #define debug Serial
#endif

// 回転
#define ROTARY_ANGLE_SENSOR A0
#define LED 3  //LED D3pin
#define ADC_REF 5 // ?
#define GROVE_VCC 5 // ?
#define FULL_ANGLE 300 //最大回転角

//スライダー
int adcPin = A1;

// PIR
#define PIR_MOTION_SENSOR 2

void setup()
{
    Serial.begin(9600);
    pinMode(ROTARY_ANGLE_SENSOR, INPUT); //回転
    pinMode(PIR_MOTION_SENSOR, INPUT); //PIR
    dht.begin();
    //pinMode(LED,OUTPUT);  //出力 
}

void loop()
{   
    // 超音波
    long RangeInInches;
    long RangeInCentimeters;
    RangeInCentimeters = ultrasonic.MeasureInCentimeters();
    int cm = RangeInCentimeters; //近さ
    // 温度
    float temp_hum_val[2] = {0};
    float temp = 0;
    if (!dht.readTempAndHumidity(temp_hum_val)) {
        temp = temp_hum_val[1];
    }
    int temp10 = (int)(temp*10);
    // 回転
    float voltage;
    int sensor_value = analogRead(ROTARY_ANGLE_SENSOR);
    voltage = (float)sensor_value*ADC_REF/1023;
    int degrees = (int)((voltage*FULL_ANGLE)/GROVE_VCC); // floatをキャスト
    // スライダー
    int slider_val = analogRead(adcPin);
    int slider = map(slider_val, 0, 1023, 0, 100);
    // PIR
    bool coming = digitalRead(PIR_MOTION_SENSOR);


    //int brightness;
    //brightness = map(degrees, 0, FULL_ANGLE, 0, 255);
    //analogWrite(LED,brightness);

    // Pythonへ渡す
    Serial.println(cm); //近さ 0~400cm
    Serial.println(temp10); //温度*10
    Serial.println(degrees); //回転 0~300
    Serial.println(slider); //スライダー ~100
    Serial.println(coming); //PIR 1/0
    delay(500);
}
