import threading
import time

import serial
from flask import Flask, jsonify, render_template

#############################################################
# Arduinoで実行(シリアルモニタ開かない)→pyの▷vからRunCode選択 #
#############################################################

# ポート、ビットレート、タイムアウト(ポートからのデータ読み取る最大待機時間)
ser = serial.Serial('COM3', 9600, timeout=0.1)
# ser = serial.Serial('COM9', 9600, timeout=0.1)
data = [0,0,0,0,False] #近さ,温度*10,回転~300,ｽﾗｲﾀﾞ-~100,PIR 1/0

#
## 通信
#
PORT = 5500
# flask生成
app = Flask(__name__, static_folder='.', static_url_path='')
@app.route('/')
def index():
    return render_template('index.html')
@app.route('/data')
def get_data():
    jsonData = {
        'near': data[0],
        'temp': data[1],
        'rotate': data[2],
        'slide': data[3],
        'pir': data[4],
    }
    return jsonify(jsonData)
# サーバ起動
def run_flask_app():
    app.run(port=PORT, debug=True, use_reloader=False)
# 別スレッドでサーバー実行
if __name__ == '__main__':
    # Flaskサーバーを別スレッドで実行
    flask_thread = threading.Thread(target=run_flask_app)
    flask_thread.start()

#
## Arduinoから受取り
#
dataNum = 0
while True:
    try:
        # 1行ずつ受け取る
        line = ser.readline().decode('utf-8').strip()
        if line:
            if(dataNum==0):
                data[0]=int(line)
                dataNum+=1
            elif(dataNum==1):
                data[1]=int(line)
                dataNum+=1
            elif(dataNum==2):
                data[2]=int(line)
                dataNum+=1
            elif(dataNum==3):
                data[3]=int(line)
                dataNum+=1
            elif(dataNum==4):
                if line=="1":
                    data[4]=True
                else:
                    data[4]=False
                dataNum=0
            print(data)
        time.sleep(0.1) #一時停止。データが来るまで待つ用
    except Exception as e:
        print(f"Error: {e}")
        break
ser.close()