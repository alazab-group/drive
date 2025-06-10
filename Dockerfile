FROM python:3.11-slim-bookworm

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    pkg-config \
    # Database clients
    default-mysql-client \
    postgresql-client \
    # Node.js and npm
    nodejs \
    npm \
    # Media processing
    libmagic1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    # Fonts
    fonts-liberation \
    fonts-noto-cjk \
    # PDF generation
    wkhtmltopdf \
    # SSL and crypto
    libssl-dev \
    libffi-dev \
    # Git
    git \
    # Process management
    supervisor \
    # Image processing (for thumbnails and previews)
    libjpeg-dev \
    libpng-dev \
    libwebp-dev \
    libtiff-dev \
    libopenjp2-7-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    # Audio/Video processing
    ffmpeg \
    # Archive tools
    unrar \
    p7zip-full \
    # XML/HTML processing
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # File system tools
    file \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create drive user
RUN useradd -m -s /bin/bash drive

# Set working directory
WORKDIR /home/drive

# Copy requirements first for better caching
COPY requirements.txt .
COPY package.json .

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

# Install Node.js dependencies
RUN npm install -g yarn \
    && npm install

# Copy application code
COPY . .

# Create storage directories
RUN mkdir -p /home/drive/storage/uploads \
    && mkdir -p /home/drive/storage/thumbnails \
    && mkdir -p /home/drive/storage/previews

# Set ownership
RUN chown -R drive:drive /home/drive

# Switch to drive user
USER drive

# Build frontend assets
RUN npm run production

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/method/ping')" || exit 1

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "drive.app:application"]
