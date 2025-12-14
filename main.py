from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "<p>Hello, Flask!</p>"

if __name__ == '__main__':
    # CMD で gunicorn を使うため、このブロックは通常実行されないが、ローカルテスト用に残す
    app.run(host='0.0.0.0', port=5000)