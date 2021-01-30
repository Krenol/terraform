#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get install nodejs -y
npm install npm@latest -g
npm install -g create-react-app
create-react-app dummy
cd dummy
npm start
