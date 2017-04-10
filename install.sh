#!/usr/bin/env zsh

if [ ! -d ~/ansible-babun-bootstrap ]
then
  git clone https://github.com/kedwards/ansible-babun-bootstrap.git ~/ansible-babun-bootstrap
  git checkout mrm
else
  cd ~/ansible-babun-bootstrap
  git checkout mrm
  git pull
fi

cd ~/ansible-babun-bootstrap
source ansible-babun-bootstrap.sh
