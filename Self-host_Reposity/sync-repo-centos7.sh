#!/bin/bash
# CentOS 8: sync-repo-centos7.sh
# reposync for CentOS 7 yum repository
# author: devopjj@gmail.com

# 下載 rpms
echo 開始同步 CentOS 7 rpm

VER='7'
ARCH='x86_64'
REPOS=(base updates extras7)
for REPO in ${REPOS[@]}
do
    reposync --repo=${REPO} --download-metadata --newest-only -p /opt/mirrors/centos/7/  
done

# [epel]這個套件庫比較大(27G，視需求自行啟用)，用rsync來完成。
#$ rsync -av --ignore-existing rsync://fedora.cs.nctu.edu.tw/fedora-epel/7/x86_64/ /opt/mirrors/centos/7/epel7/x86_64/

# 更新 metadata 元數據
#createrepo --update --workers=4 /opt/mirrors/centos/7/base7/
#createrepo --update --workers=4 /opt/mirrors/centos/7/updates7/
#createrepo --update --workers=4 /opt/mirrors/centos/7/extras7/
echo CentOS 7 rpm 同步結束