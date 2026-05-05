from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/ping", methods=["GET", "POST"])
def ping():
    print("✅ Request diterima dari Roblox!")
    data = request.get_json(silent=True)
    print("Data:", data)
    return jsonify({
        "status": "ok",
        "message": "Koneksi berhasil!",
        "received": data
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)