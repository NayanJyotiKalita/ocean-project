#! /bin/bash
sudo yum update -y
sudo yum install -y docker git
sudo systemctl enable docker
sudo systemctl start docker