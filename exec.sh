#!/bin/bash
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install curl bash -y
curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm
npm install npm@latest -g
npx create-react-app dummy
cd dummy
npm start
