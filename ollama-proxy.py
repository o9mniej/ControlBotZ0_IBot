# ollama_proxy_stable.py
from flask import Flask, request, jsonify
import requests
import json
import threading
import queue

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"  # Ollama local endpoint
MAX_PLAYERS = 12  # trim system prompt to first 12 players

app = Flask(__name__)

# Queue to handle incoming Roblox requests safely
request_queue = queue.Queue()

def sanitize_text(text):
    """Remove control characters and normalize line breaks"""
    if not text:
        return ""
    text = "".join(c for c in text if ord(c) >= 32 or c in "\n\r\t")
    text = text.replace("\u2028", "\n").replace("\u2029", "\n")
    return text

def sanitize_payload(payload):
    """Sanitize messages and trim system message"""
    messages = payload.get("messages", [])
    for msg in messages:
        if "content" in msg and isinstance(msg["content"], str):
            msg["content"] = sanitize_text(msg["content"])
    # trim system player list
    if messages and messages[0]["role"] == "system":
        lines = messages[0]["content"].split("\n")
        header = []
        players = []
        for line in lines:
            if line.startswith("- "):
                players.append(line)
            else:
                header.append(line)
        players = players[:MAX_PLAYERS]
        messages[0]["content"] = "\n".join(header + players)
    return payload

def worker():
    """Worker thread to process requests from queue sequentially"""
    while True:
        req_item = request_queue.get()
        if req_item is None:
            break
        payload, result_queue = req_item
        try:
            payload = sanitize_payload(payload)
            res = requests.post(OLLAMA_URL, json=payload, timeout=30)
            if res.status_code == 200:
                result_queue.put(res.json())
            else:
                result_queue.put({"error": f"Ollama HTTP {res.status_code}"})
        except Exception as e:
            result_queue.put({"error": str(e)})
        request_queue.task_done()

# start worker thread
threading.Thread(target=worker, daemon=True).start()

@app.route("/chat", methods=["POST"])
def chat_proxy():
    try:
        payload = request.get_json(force=True)
        # use a queue for this specific request to wait for result
        result_queue = queue.Queue()
        request_queue.put((payload, result_queue))
        # wait for result
        result = result_queue.get(timeout=60)  # wait up to 60s
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("Starting stable Ollama proxy on http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000)
