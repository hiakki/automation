if [ $(cat /etc/apt/sources.list | grep -c kubernetes) -lt 1 ]
then
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add 
echo deb http://apt.kubernetes.io/ kubernetes-xenial main  >> /etc/apt/sources.list	
fi 

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

apt update -y
apt upgrade -y
apt install apt-transport-https ca-certificates curl software-properties-common docker-ce=18.06.2~ce~3-0~ubuntu -y

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

apt install -y kubelet kubeadm kubectl kubernetes-cni
