FROM node:latest
MAINTAINER Corrado Masciullo <masciugo@gmail.com>

RUN npm install -g json-server

COPY Dtab12.json db.json

CMD json-server -p $PORT db.json # heroku container use $PORT instead of EXPOSE
