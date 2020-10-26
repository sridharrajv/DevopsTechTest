#!/usr/bin/env bash

yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io
systemctl enable httpd
systemctl start docker

su - ec2-user
echo "${sshpubkey}" >>~/.ssh/authorized_keys
docker run -d --rm -p 8080:8080 --name dashboard sridharrajv/sportsbuff:dashboard -e  MQHOST="activemq" MQPORT="3306" MQUSERNAME: "admin" MQPASSWORD: "admin"
docker run -d --rm -p 8080:8080 --name app-server sridharrajv/sportsbuff:app-server