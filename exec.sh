#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get install nodejs npm -y
npm install npm@latest -g
npx create-react-app dummy
cd dummy
npm start
