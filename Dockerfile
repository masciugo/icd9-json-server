FROM node:latest
MAINTAINER Corrado Masciullo <masciugo@gmail.com>

RUN npm install -g json-server

COPY data.json db.json

CMD json-server -p $PORT db.json # heroku container use $PORT instead of EXPOSE
