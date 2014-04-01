#!/bin/sh

echo 'inference' | sudo -S apt-get update
echo 'inference' | sudo -S apt-get install -y puppet

# for Apache
echo 'inference' | sudo -S apt-get install -y libapr1 libaprutil1 libaprutil1-dbd-mysql php5-mysql