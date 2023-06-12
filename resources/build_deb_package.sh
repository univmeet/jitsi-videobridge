#!/bin/bash

# 打印执行过程
set -x

# 执行出错时停止
set -e

# 确保设置了以下环境变量，例如：
# export DEBFULLNAME="Jitsi Team"
# export DEBEMAIL="dev@jitsi.org"
#
# 需要安装的安装包：devscripts（dch命令）、libxml2-utils（xmllint命令）、dh-systemd、debhelper。
#
# 有一个可选参数可用于向版本中添加额外的字符串。
# 这个字符串可用于标记自定义版本，例如：传递参数hf时，生成的debian版本为2.1-123-gabcabcab-hf-1，而不只是2.1-123-gabcabcab-1。
#
# 执行脚本：
# cd /xxx/jitsi-videobridge
# ./resources/build_deb_package.sh ver_extra_label
# $0：./resources/build_deb_package.sh
# $1：ver_extra_label
VER_EXTRA_LABEL=$1

echo "==================================================================="
echo "   构建Debian安装包   "
echo "==================================================================="

# 获取build_deb_package.sh脚本目录：jitsi-videobridge/resources
SCRIPT_FOLDER=$(dirname "$0")
# 进入build_deb_package.sh脚本目录的上级目录：jitsi-videobridge
cd "$SCRIPT_FOLDER/.."

# 从pom.xml文件中获取版本：project/version，例如：MVNVER=2.3-SNAPSHOT
MVNVER=$(xmllint --xpath "/*[local-name()='project']/*[local-name()='version']/text()" pom.xml)
# 去掉MVNVER中的-SNAPSHOT字符串，例如：TAG_NAME=v2.3
TAG_NAME="v${MVNVER/-SNAPSHOT/}"

echo "当前标签名称：$TAG_NAME"

# git rev-parse "$TAG_NAME"：获取当前标签的hash值
# >/dev/null：把标准输出重定向到空设备
# 2>&1：把标准错误输出重定向到标准输出
if ! git rev-parse "$TAG_NAME" >/dev/null 2>&1
then
  # 标签不存在时，创建并push标签
  git tag -a "$TAG_NAME" -m "Jenkins自动创建的标签"
  git push origin "$TAG_NAME"
else
  echo "标签：$TAG_NAME 已经存在"
fi

# 完整的版本信息，例如：v2.3-4-g33ef732e
VERSION_FULL=$(git describe --match "v[0-9\.]*" --long)
echo "完整版本：${VERSION_FULL}"

# 版本变量，例如：v2.3-4-g33ef732e
export VERSION=${VERSION_FULL:1}
if [ -n "${VER_EXTRA_LABEL}" ]
then
  # 添加可选的额外版本参数
  VERSION+="-${VER_EXTRA_LABEL}"
fi
echo "安装包版本：${VERSION}"

# 获取版本末尾的字符串，例如：REV=33ef732e
REV=$(git log --pretty=format:'%h' -n 1)
dch -v "$VERSION-1" "从Git中构建：$REV"
dch -D unstable -r ""

# 在pom文件中设置版本，这样才能把版本传递给生成的jar文件
mvn versions:set -DnewVersion="${VERSION}"

# 在开始构建debian安装包之前，需要确保下载了所有依赖包
mvn package

# 构建debian安装包，执行：debian/rules和debian/install
dpkg-buildpackage -tc -us -uc -A

# 清理当前修改，因为dch修改了changelog
git checkout debian/changelog
git checkout pom.xml

echo "$(pwd ..) 的构建结果文件："
echo "-----"
# 在jitsi-videobridge的同级目录中
ls -l ../{*.changes,*.deb,*.buildinfo}
echo "-----"

# 尝试部署
cd ..
([ ! -x deploy.sh ] || ./deploy.sh "jvb" $VERSION )
