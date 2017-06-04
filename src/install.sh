#!/usr/bin/env zsh

if [ ! -d ~/ansible-babun-bootstrap ]
then
  git clone https://github.com/nobitagamer/ansible-babun-bootstrap.git ~/ansible-babun-bootstrap
  cd ~/ansible-babun-bootstrap
  git checkout master
else
  cd ~/ansible-babun-bootstrap
  git checkout master
  git pull
fi

source ~/ansible-babun-bootstrap/src/ansible-babun-bootstrap.sh
