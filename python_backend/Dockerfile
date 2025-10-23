FROM python:3.14

WORKDIR /app

COPY python_backend/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY python_backend/ .

EXPOSE 8000

CMD ["uvicorn", "filter_backend:app", "--host", "0.0.0.0", "--port", "8000"]
