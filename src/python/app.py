"""
SDLC Metrics Demo - Python Flask Application
Demonstrates CloudBees Unify metrics population from Python applications
"""

from flask import Flask, jsonify, request
from flask_wtf.csrf import CSRFProtect
from datetime import datetime, timezone
import os

app = Flask(__name__)
app.secret_key = os.urandom(32)
csrf = CSRFProtect(app)

# Application metadata
APP_VERSION = os.environ.get('APP_VERSION', '1.0.0')
APP_NAME = 'sdlc-metrics-demo-python'


@app.route('/')
def home():
    """Home endpoint with application information"""
    return jsonify({
        'application': APP_NAME,
        'version': APP_VERSION,
        'message': 'CloudBees Unify SDLC Metrics Demo',
        'timestamp': datetime.now(timezone.utc).isoformat()
    })


@app.route('/health')
def health():
    """Health check endpoint for monitoring"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now(timezone.utc).isoformat()
    })


@app.route('/api/calculator', methods=['POST'])
def calculator():
    """
    Calculator API endpoint
    Expects JSON: {"operation": "add", "a": 5, "b": 3}
    Supported operations: add, subtract, multiply, divide, power
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400

        operation = data.get('operation')
        a = data.get('a')
        b = data.get('b')

        if operation is None or a is None or b is None:
            return jsonify({'error': 'Missing required fields: operation, a, b'}), 400

        # Type validation
        try:
            a = float(a)
            b = float(b)
        except (TypeError, ValueError):
            return jsonify({'error': 'Invalid number format'}), 400

        # Perform calculation
        if operation == 'add':
            result = add(a, b)
        elif operation == 'subtract':
            result = subtract(a, b)
        elif operation == 'multiply':
            result = multiply(a, b)
        elif operation == 'divide':
            result = divide(a, b)
        elif operation == 'power':
            result = power(a, b)
        else:
            return jsonify({'error': f'Unknown operation: {operation}'}), 400

        return jsonify({
            'operation': operation,
            'a': a,
            'b': b,
            'result': result,
            'timestamp': datetime.now(timezone.utc).isoformat()
        })

    except ZeroDivisionError:
        return jsonify({'error': 'Division by zero'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Calculator functions
def add(a, b):
    """Add two numbers"""
    return a + b


def subtract(a, b):
    """Subtract two numbers"""
    return a - b


def multiply(a, b):
    """Multiply two numbers"""
    return a * b


def divide(a, b):
    """Divide two numbers"""
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b


def power(a, b):
    """Calculate a to the power of b"""
    return a ** b


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
