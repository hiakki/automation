#!/bin/bash

# Installing kops
kops_version=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/kubernetes/kops/releases/download/$kops_version/kops-linux-amd64
chmod +x ./kops-linux-amd64
sudo mv ./kops-linux-amd64 /usr/local/bin/kops

# Installing kubectl
kubectl_version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
wget https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
