#!/bin/sh

sudo apt-get update
sudo apt-get install -y puppet

# for Apache
sudo apt-get install -y libapr1 libaprutil1 libaprutil1-dbd-mysql php5-mysql