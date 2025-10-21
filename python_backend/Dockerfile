FROM python:3.14-slim

WORKDIR /app

COPY . /app
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "api_handler:app", "--host", "0.0.0.0", "--port", "8000"]
