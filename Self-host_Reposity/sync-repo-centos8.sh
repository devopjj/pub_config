#!/bin/bash
# CentOS 8: sync-repo-centos8.sh
# reposync for CentOS 8 yum repository
# author: devopjj@gmail.com

# 下載 rpms
echo 開始同步 CentOS 8 rpm

VER='8'
ARCH='x86_64'
REPOS=(BaseOS AppStream extras8)
for REPO in ${REPOS[@]}
do
    reposync --repo=${REPO} --download-metadata --newest-only -p /opt/mirrors/centos/8/  
done
echo CentOS 8 rpm 同步結束

