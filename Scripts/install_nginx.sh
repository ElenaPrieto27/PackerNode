#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y nginx

sudo systemctl enable nginx
sudo systemctl start nginx
