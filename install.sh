#!/usr/bin/env zsh

if [ ! -d ~/ansible-babun-bootstrap ]
then
  git clone https://github.com/kedwards/ansible-babun-bootstrap.git ~/ansible-babun-bootstrap
else
  cd ~/ansible-babun-bootstrap
  git pull
fi

cd ~/ansible-babun-bootstrap
source ansible-babun-bootstrap.sh