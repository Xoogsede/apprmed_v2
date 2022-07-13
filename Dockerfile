FROM python:3
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
COPY requirements.txt /code/
RUN pip install -r requirements.txt
COPY . /code/
CMD python app.py
RUN apt-get install pkg-config libtool -y 
RUN apt-get update && apt-get install make
RUN apt-get install libzbar-dev -y
RUN apt-get install ffmpeg libsm6 libxext6  -y
RUN apt-get install libgl1
RUN apt-get install libxrender1
RUN apt-get install libfontconfig1
RUN apt-get install libice6
