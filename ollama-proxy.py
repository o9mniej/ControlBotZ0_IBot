# ollama_proxy_debug.py
from flask import Flask, request, jsonify
import requests
import json

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"  # Ollama local endpoint

app = Flask(__name__)

@app.route("/chat", methods=["POST"])
def chat_proxy():
    try:
        payload = request.get_json(force=True)

        # Debug: print the payload Roblox sent
        print("=== Payload received from Roblox ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("===================================")

        # sanitize user input minimally (optional)
        for msg in payload.get("messages", []):
            if "content" in msg and isinstance(msg["content"], str):
                msg["content"] = "".join(c for c in msg["content"] if ord(c) >= 32 or c in "\n\r\t")

        # Debug: print the sanitized payload going to Ollama
        print("=== Payload sent to Ollama ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("===================================")

        # retry once if Ollama fails
        for attempt in range(2):
            try:
                res = requests.post(OLLAMA_URL, json=payload, timeout=30)
                if res.status_code == 200:
                    print("=== Ollama Response ===")
                    print(res.text)
                    print("=======================")
                    return jsonify(res.json())
                else:
                    print(f"Attempt {attempt+1} failed: HTTP {res.status_code}")
            except Exception as e:
                print(f"Attempt {attempt+1} exception: {e}")

        return jsonify({"error": "Ollama failed"}), 500

    except Exception as e:
        print(f"Proxy exception: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("Starting Ollama debug proxy on http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000)
