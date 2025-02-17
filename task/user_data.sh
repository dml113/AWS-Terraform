#!/bin/bash
yum install ruby -y
yum install wget -y
wget https://aws-codedeploy-us-east-2.s3.amazonaws.com/latest/install
chmod +x install
./install auto