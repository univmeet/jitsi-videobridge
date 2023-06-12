# 构建Debian安装包

## 构建步骤

```bash
# 确保设置了以下环境变量，例如：
# export DEBFULLNAME="Jitsi Team"
# export DEBEMAIL="dev@jitsi.org"

# 添加Debian源
vi /etc/apt/sources.list
deb http://cz.archive.ubuntu.com/ubuntu focal main universe
sudo apt update

# 安装devscripts
sudo apt install devscripts

# 安装libxml2-utils
sudo apt install libxml2-utils

# 安装dh-systemd
sudo apt install dh-systemd

# 安装debhelper
sudo apt install debhelper

# 安装Java
sudo apt install openjdk-11-jre-headless
java -version

# 安装Maven
sudo apt install maven
mvn -v

# 添加本地Maven仓库
cd /root
rz -E
unzip .m2.zip

# 添加公钥私钥
cd /root/.ssh
rz -E
unzip id_rsa.zip
chmod 400 id_rsa
chmod 444 id_rsa.pub

# 安装Git
sudo apt install git
git version

# 下载代码
mkdir -p /root/jitsi/source
cd /root/jitsi/source
git clone git@github.com:jitsi/jitsi-videobridge.git

# 更新代码
cd /root/jitsi/source/jitsi-videobridge
# 更新文件
git pull
# 查看状态
git diff
# 强制更新
git checkout -f -B master remotes/origin/master --
# 清理文件
git clean -xdff

# 构建代码
cd /root/jitsi/source/jitsi-videobridge
mvn clean install -Dmaven.test.skip=true

# 构建Debian安装包
cd /root/jitsi/source/jitsi-videobridge
./resources/build_deb_package.sh
```
