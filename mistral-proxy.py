import os
from flask import Flask, request, jsonify
from mistralai import Mistral

app = Flask(__name__)

# ========================
# CONFIGURE MISTRAL CLIENT
# ========================
client = Mistral(api_key=os.environ.get("MISTRAL_API_KEY"))

# ========================
# ROUTE
# ========================
@app.route("/chat", methods=["POST"])
def chat_proxy():
    data = request.get_json()

    # Debug: log what we got from Roblox
    print("==== Received from Roblox ====")
    print(data)
    print("==============================")

    try:
        # Build the inputs for Mistral
        # Expecting `messages` in the payload like your Lua code
        inputs = []
        for msg in data.get("messages", []):
            inputs.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

        # Completion arguments
        completion_args = {
            "temperature": data.get("temperature", 0.7),
            "max_tokens": data.get("max_tokens", 150),
            "top_p": 1
        }

        # Instructions from system prompt
        instructions = ""
        for msg in inputs:
            if msg["role"] == "system":
                instructions = msg["content"]

        # Call Mistral API
        response = client.beta.conversations.start(
            inputs=inputs,
            model="mistral-medium-latest",
            instructions=instructions,
            completion_args=completion_args,
            tools=[]
        )

        # Debug: log full Mistral response
        print("==== Response from Mistral ====")
        print(response)
        print("===============================")

        # Return Mistral output in Pollinations-style format
        # This ensures your Lua bot doesn't need to change
        return jsonify({
            "choices": [
                {"message": {"role": "assistant", "content": response.output_text}}
            ]
        })

    except Exception as e:
        print("AI request failed:", e)
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(port=5000)
