#!/bin/bash
apt update -y
apt upgrade -y
apt install vsftpd -y
mv -v /etc/vsftpd.conf /etc/vsftpd.conf.bk
cat >> /etc/vsftpd.conf << FTP
listen=YES
listen_ipv6=NO
connect_from_port_20=YES
 
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
 
pam_service_name=vsftpd
 
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=45000
 
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
FTP

echo hiakki > /etc/vsftpd.userlist
systemctl restart vsftpd

useradd -m hiakki
echo "hiakki:password" | sudo chpasswd

systemctl status vsftpd
