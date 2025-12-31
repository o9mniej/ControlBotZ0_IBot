from flask import Flask, request, jsonify
from mistralai import Mistral
import os
import json

app = Flask(__name__)
client = Mistral(api_key=os.environ.get("MISTRAL_API_KEY"))

@app.route("/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON received"}), 400

        # Extract the system prompt and user messages
        system_prompt = ""
        user_inputs = []

        for msg in data.get("messages", []):
            role = msg.get("role")
            content = msg.get("content", "")
            if role == "system":
                system_prompt = content
            elif role in ["user", "assistant"]:
                user_inputs.append({"role": role, "content": content})
            else:
                # ignore unexpected roles
                continue

        if not user_inputs:
            return jsonify({"error": "No user messages found"}), 400

        # Set completion args from Roblox payload or default
        completion_args = data.get("options", {
            "temperature": 0.7,
            "max_tokens": 150,
            "top_p": 1
        })

        model_name = data.get("model", "mistral-medium-latest")

        # Call Mistral
        response = client.beta.conversations.start(
            inputs=user_inputs,
            model=model_name,
            instructions=system_prompt,
            completion_args=completion_args,
            tools=[]
        )

        # Return the content of the last assistant message
        if hasattr(response, "messages") and len(response.messages) > 0:
            last_msg = response.messages[-1]
            return jsonify({"message": {"content": last_msg.get("content")}})
        else:
            return jsonify({"error": "No response from Mistral"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(port=5000)
