FROM python:3.11-slim

RUN apt-get update && apt-get install -y python3-tk tk libx11-6 libxext6 libxrender1 libxtst6 libxi6 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

ENV API_HOST=0.0.0.0
ENV API_PORT=8080
ENV PYTHONUNBUFFERED=1

CMD ["python", "main.py"]
