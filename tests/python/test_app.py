"""
Unit tests for SDLC Metrics Demo Python Application
Tests calculator functions and API endpoints
"""

import pytest
import sys
import os

# Add src directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src/python')))

from app import app, add, subtract, multiply, divide, power


@pytest.fixture
def client():
    """Create test client for Flask application"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


# Calculator function tests
class TestCalculatorFunctions:
    """Test calculator mathematical functions"""

    def test_add_positive(self):
        assert add(2, 3) == 5
        assert add(10, 20) == 30

    def test_add_negative(self):
        assert add(-5, -3) == -8
        assert add(-10, 10) == 0

    def test_subtract(self):
        assert subtract(10, 5) == 5
        assert subtract(5, 10) == -5
        assert subtract(0, 0) == 0

    def test_multiply(self):
        assert multiply(4, 5) == 20
        assert multiply(0, 100) == 0
        assert multiply(-4, 5) == -20

    def test_divide(self):
        assert divide(20, 4) == 5
        assert divide(10, 2) == 5
        assert divide(-20, 4) == -5

    def test_divide_by_zero(self):
        with pytest.raises(ZeroDivisionError):
            divide(10, 0)

    def test_power(self):
        assert power(2, 3) == 8
        assert power(5, 0) == 1
        assert power(10, 2) == 100


# API endpoint tests
class TestAPIEndpoints:
    """Test Flask API endpoints"""

    def test_home_endpoint(self, client):
        response = client.get('/')
        assert response.status_code == 200
        data = response.get_json()
        assert 'application' in data
        assert 'version' in data
        assert data['application'] == 'sdlc-metrics-demo-python'

    def test_health_endpoint(self, client):
        response = client.get('/health')
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'healthy'

    def test_calculator_add(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'add', 'a': 5, 'b': 3})
        assert response.status_code == 200
        data = response.get_json()
        assert data['result'] == 8

    def test_calculator_subtract(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'subtract', 'a': 10, 'b': 4})
        assert response.status_code == 200
        data = response.get_json()
        assert data['result'] == 6

    def test_calculator_multiply(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'multiply', 'a': 6, 'b': 7})
        assert response.status_code == 200
        data = response.get_json()
        assert data['result'] == 42

    def test_calculator_divide(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'divide', 'a': 20, 'b': 5})
        assert response.status_code == 200
        data = response.get_json()
        assert data['result'] == 4

    def test_calculator_divide_by_zero(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'divide', 'a': 10, 'b': 0})
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data

    def test_calculator_invalid_operation(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'modulo', 'a': 10, 'b': 3})
        assert response.status_code == 400

    def test_calculator_missing_fields(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'add', 'a': 5})
        assert response.status_code == 400

    def test_calculator_invalid_numbers(self, client):
        response = client.post('/api/calculator',
                               json={'operation': 'add', 'a': 'five', 'b': 3})
        assert response.status_code == 400
