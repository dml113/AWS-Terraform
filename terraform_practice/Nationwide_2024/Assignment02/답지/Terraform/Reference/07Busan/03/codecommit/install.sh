#/usr/bin/bash
sudo yum install docker -y
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
sudo su - ec2-user