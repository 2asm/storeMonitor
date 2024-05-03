FROM python:latest

WORKDIR /usr/src/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_ROOT_USER_ACTION=ignore
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0


RUN pip install --upgrade pip
COPY . /usr/src/app
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD [ "flask", "run"]
