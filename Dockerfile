# Use Python 3.12 slim image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_CACHE_DIR=/tmp/uv-cache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Create app directory
WORKDIR /app

# Copy uv configuration files
COPY pyproject.toml uv.lock ./

# Install Python dependencies
RUN uv sync --frozen --no-dev

# Copy application code
COPY . .

# Create uploads directory with proper permissions
RUN mkdir -p /app/app/static/uploads/profiles /app/app/static/uploads/shops && \
    chmod -R 755 /app/app/static/uploads

# Create instance directory for SQLite database
RUN mkdir -p /app/instance && chmod 755 /app/instance

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uv", "run", "gunicorn", "run:app"]
