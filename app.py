from flask import Flask
from dotenv import load_dotenv
import os
# Load environment variables from .env file if it exists
load_dotenv()

from ui import setup_routes

# Initialize Flask app
app = Flask(__name__)
# Required for flash Flask error messaging
app.secret_key = os.urandom(24)

# Set up UI routes
setup_routes(app)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082)