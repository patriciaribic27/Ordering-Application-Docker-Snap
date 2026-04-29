# Bazni image: Python 3.11 na slim Debian Linuxu
FROM python:3.11-slim

# Radni direktorij unutar kontejnera
WORKDIR /app

# Prvo kopiraj samo requirements.txt (Docker cache)
COPY requirements.txt .

# Instaliraj Python ovisnosti
RUN pip install --no-cache-dir -r requirements.txt

# Kopiraj ostatak projekta
COPY . .

# Najavi port
EXPOSE 8080

# Defaultne environment varijable
ENV API_HOST=0.0.0.0
ENV API_PORT=8080
ENV PYTHONUNBUFFERED=1

# Pokreni server kada kontejner startuje
CMD ["python", "-m", "services.api_server"]
