#!/usr/bin/env bash
set -e

ENV="demo"
PUBLIC_IP=$(curl -s ifconfig.me)
GIT_USER=$(git config user.name)
SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)

cd ../go
docker build --tag dashboard:1.0.0 .
docker tag dashboard:1.0.0 sridharrajv/sportsbuff:dashboard
docker push sridharrajv/sportsbuff:dashboard
#docker tag (image id) quay.io/alfresco/insight-engine:slave
#docker push quay.io/alfresco/insight-engine:slave
docker build --tag app-server:1.0.0 .
docker tag app-server:1.0.0 sridharrajv/sportsbuff:app-server
docker push sridharrajv/sportsbuff:app-server

cd ../terraform
terraform init

terraform apply \
  -var="ssh_ip_whitelist=[\"$PUBLIC_IP/32\"]" \
  -var="tags={env=\"$ENV\",author=\"$GIT_USER\"}" \
  -var="sshpubkey=\"$SSH_PUB_KEY\""