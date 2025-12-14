FROM python:3.11-slim

# Prevents Python from writing .pyc files and buffers
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy only what we need (single-file app)
COPY main.py /app/

# Install runtime dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir flask gunicorn

EXPOSE 5000

# Use gunicorn to serve the Flask app, binding to all interfaces
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "main:app"]
