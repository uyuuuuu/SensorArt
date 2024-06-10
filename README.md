# GroveセンサーによるインタラクティブなShader Artシステム

## 概要
センサーへの操作によってモニターの画を操作するVJシステム

## 背景
一般的なMIDIコントローラーではボタンでの操作が多い。このシステムでは気温、手をかざす、手を近づけるといったセンサへのインプットでより直感的に音楽に乗りながら画に変化を与えられる。

## 操作方法
- センサとPCをUSBでつなげてArduinoIDEから書き込み
- requirements.txtでインポート
- 自身のCOMポート番号にSensorReceiver.pyの冒頭を書き換える
- SensorReceiver.pyを実行してローカルサーバー立ち上げ
- http://127.0.0.1:5500/に入る

## 使用センサ
- Grove Ultrasonic Ranger(超音波)
- Grove Temperature & Humidity Sensor Pro(気温)
- Grove Slide Potentiometer(スライダー)
- Grove Rotary Angle Sensor(回転角度)
- Grove PIR Motion Sensor(動きを検知)

## 使用言語など
- Arduino
- Python
 - Flask
- Java Script
- GLSL
- HTML

## 実装について
ジェネラティブアートの系譜に則りThree.jsでPlane1枚だけを全画面に表示し、描く画はそのマテリアルのShader(主にfrag.glsl)によってのみ表現される。

## センサの与える画面効果
- 超音波：手を近づけると動きが遅くなる
- 気温：小数第一位の数字で画面の色が変化
- スライダー：3種類の画面切り替え
- 回転角度：画面の歪み
- 動きを検知：画面ノイズ


## 動作例
<video src="https://drive.google.com/file/d/1fV36zJB3zyy30MrnYjZlkL4gcRidTe2v/view?usp=sharing" controls="true" width="600"></video>
