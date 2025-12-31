# ollama_proxy_sanitize.py
from flask import Flask, request, jsonify
import requests
import json

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"  # Ollama local endpoint

app = Flask(__name__)

def sanitize_text(text):
    """Remove control characters and normalize line breaks"""
    if not text:
        return ""
    # remove control chars except newline/tab/carriage return
    text = "".join(c for c in text if ord(c) >= 32 or c in "\n\r\t")
    # normalize unicode line separators
    text = text.replace("\u2028", "\n").replace("\u2029", "\n")
    return text

def sanitize_payload(payload, max_players=12):
    """Sanitize messages and optionally trim system message"""
    messages = payload.get("messages", [])
    for msg in messages:
        if "content" in msg and isinstance(msg["content"], str):
            msg["content"] = sanitize_text(msg["content"])
    # Trim system player list if present
    if messages and messages[0]["role"] == "system":
        lines = messages[0]["content"].split("\n")
        header = []
        players = []
        for line in lines:
            if line.startswith("- "):
                players.append(line)
            else:
                header.append(line)
        players = players[:max_players]  # keep only first N players
        messages[0]["content"] = "\n".join(header + players)
    return payload

@app.route("/chat", methods=["POST"])
def chat_proxy():
    try:
        payload = request.get_json(force=True)

        # Debug: show raw payload from Roblox
        print("=== Payload received from Roblox ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("===================================")

        # Sanitize payload
        payload = sanitize_payload(payload)

        # Debug: show sanitized payload sent to Ollama
        print("=== Payload sent to Ollama ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("===================================")

        # Retry once if Ollama fails
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
    print("Starting Ollama sanitize proxy on http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000)
