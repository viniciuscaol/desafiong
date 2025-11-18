FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
# Cria o diretório onde montaremos o volume (ponto de montagem)
RUN mkdir /dados
EXPOSE 5000
CMD ["python", "app.py"]