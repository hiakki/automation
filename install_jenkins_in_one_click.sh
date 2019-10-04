#!/bin/bash
yum install java-1.8.0-openjdk-devel -y
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum update -y
yum install jenkins -y
systemctl start jenkins
systemctl enable jenkins
clear
echo "Password to Unlock Jenkins is -> $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
