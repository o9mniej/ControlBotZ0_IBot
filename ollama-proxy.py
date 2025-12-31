from flask import Flask, request, jsonify
import requests
import json

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"  # Ollama local endpoint

app = Flask(__name__)

@app.route("/chat", methods=["POST"])
def chat_proxy():
    try:
        payload = request.get_json(force=True)

        # sanitize user input
        for msg in payload.get("messages", []):
            if "content" in msg and isinstance(msg["content"], str):
                msg["content"] = "".join(c for c in msg["content"] if ord(c) >= 32 or c in "\n\r\t")

        # retry once if Ollama fails
        for _ in range(2):
            res = requests.post(OLLAMA_URL, json=payload, timeout=30)
            if res.status_code == 200:
                return jsonify(res.json())
        
        # still failed
        return jsonify({"error": "Ollama failed"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
