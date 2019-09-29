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

echo 'Enter Hostname of Master Node:'
read master_hostname

echo 'Enter IP of Master Node:'
read master_ip

echo 'Enter Hostname for this Slave/Minion Node:'
read minion_hostname

if [ $(cat /etc/hosts | grep -c $master_hostname) -lt 1 ]
then
echo $master_ip $master_hostname >> /etc/hosts
fi

if [ $(echo $HOSTNAME) != $minion_hostname ]
then
echo $minion_hostname >> /etc/hostname
reboot
fi

if [ $(cat /etc/kubernetes/kubelet.conf | grep -c $master_ip) -lt 1 ]
then
echo 'Enter Token of Master Node:'
read token

kubeadm join --token $token $master_hostname:6443
fi
