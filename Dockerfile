
FROM python:3.11-slim
WORKDIR /app
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY app /app
EXPOSE 8080
ENV COLOR=#0ea5e9 REGION=blue VERSION=v1.0.0
CMD ["python", "app.py"]
