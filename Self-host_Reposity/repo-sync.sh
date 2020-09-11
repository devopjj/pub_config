# 下載 rpms
echo 开始同步centos7
# [base]
# CentOS7 command
reposync -c /etc/yum/yum.conf -n -d --download-metadata --norepopath -rbase --download_path=/opt/mirrors/centos/7/base7/

# [updates]
# CentOS7 command
reposync -c /etc/yum/yum.conf -n -d --download-metadata --norepopath -r updates --download_path=/opt/mirrors/centos/7/updates7/

# [extras]
# CentOS7 command
reposync -c /etc/yum/yum.conf -n -d --download-metadata --norepopath -r extras --download_path=/opt/mirrors/centos/7/extras7/

# [epel]
# CentOS7 command
# rsync -av --ignore-existing rsync://fedora.cs.nctu.edu.tw/fedora-epel/7/x86_64/ /opt/mirrors/centos/7/epel/x86_64/
# 更新 metadata 元數據
createrepo --update --workers=4 /opt/mirrors/centos/7/base7/
createrepo --update --workers=4 /opt/mirrors/centos/7/updates7/
createrepo --update --workers=4 /opt/mirrors/centos/7/extras7/
echo centos7同步结束