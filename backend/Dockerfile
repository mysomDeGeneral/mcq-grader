# Use a more complete base image that already has build tools
FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx 

WORKDIR /app

COPY requirements.txt .

# Install Python dependencies
RUN pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]