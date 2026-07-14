# Multi-stage Dockerfile for SDLC Metrics Demo
# Builds both C and Python applications

# Stage 1: Build C application
FROM gcc:12 as c-builder

WORKDIR /app

# Copy C source files
COPY src/c/ ./src/c/
COPY Makefile .

# Build C application
RUN make all

# Stage 2: Python application runtime
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy C binary from builder
COPY --from=c-builder /app/build/calculator /usr/local/bin/calculator

# Copy Python application
COPY src/python/ ./src/python/
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV PORT=5000
ENV APP_VERSION=1.0.0
ENV PYTHONUNBUFFERED=1

# Expose application port
EXPOSE 5000

# Set working directory for Python app
WORKDIR /app/src/python

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run Python application by default
CMD ["python", "app.py"]
