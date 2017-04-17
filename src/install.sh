#!/usr/bin/env zsh

if [ ! -d ~/ansible-babun-bootstrap ]
then
  git clone https://github.com/kedwards/ansible-babun-bootstrap.git ~/ansible-babun-bootstrap
  cd ~/ansible-babun-bootstrap
  git checkout mrm
else
  cd ~/ansible-babun-bootstrap
  git checkout mrm
  git pull
fi

source ~/ansible-babun-bootstrap/src/ansible-babun-bootstrap.sh