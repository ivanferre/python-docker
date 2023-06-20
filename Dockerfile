# syntax=docker/dockerfile:1

# Image base is Python3
FROM python:3.8-slim-buster

# create working directory
WORKDIR /app

# @ First parameter: the file to copy into the image
# @ Second parameter: where to place it in the image
COPY requirements.txt requirements.txt

# install the requirements into the image
RUN pip3 install -r requirements.txt

# Copy the source code into the image
COPY . .

# how to execute when docker run is called.
#  you need to make the application externally visible
# (i.e. from outside the container) by specifying --host=0.0.0.0.
CMD [ "python3", "-m", "flask", "run", "--host=0.0.0.0" ]
