#!/bin/bash
#

export TMPDIR=${HOME}/tmp
export EMAIL="johnsonnolen@gmail.com"
export GERRITUSERNAME="njohnson"
export NAME="Nolen Johnson"
export USERNAME="nolenjohnson"

#### Get Sudo
echo "Make sure your nginx sites-available/, nginx sites-enabled/, and local bin/ are in ${HOME}, and stripped of certbot managed lines before continuing"
echo "If you're ready, enter your sudo password..."
sudo test

### Change to our home directory
cd ${HOME}

### Update all packages
sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove

### Install my personal packages
sudo apt -y install ccache git openssh-server

### Configure our local enviroment
ccache -M 200 GB
git config --global user.name "$NAME"
git config --global user.email "$EMAIL"
git config --global review.review.lineageos.org.username "$GERRITUSERNAME"
echo "review.lineageos.org|$GERRITUSERNAME|" > ${HOME}/.gerritrc
ssh-keygen -b 2048 -t rsa -f ${HOME}/.ssh/id_rsa -q -N ""
echo export USE_CCACHE=1 >> ${HOME}/.bashrc
echo export LC_ALL=C >> ${HOME}/.bashrc
sudo mkdir /var/log/android-builds
sudo chown -R nolenjohnson:nolenjohnson /var/log/android-builds
sudo chmod -R 755 /var/log/android-builds
echo export LOGDIR=/var/log/android-builds >> ${HOME}/.bashrc
echo export PERSON=""$NAME <$EMAIL>"" >> ${HOME}/.bashrc
echo export LINEAGE_EXTRAVERSION="ODS-Production" >> ${HOME}/.bashrc
echo export EXPERIMENTAL_USE_JAVA8=true >> ${HOME}/.bashrc
echo alias gcp="git cherry-pick" >> ${HOME}/.bashrc
echo alias grc="git rebase --continue" >> ${HOME}/.bashrc
echo alias gca="git commit --amend" >> ${HOME}/.bashrc
echo export OUT_DIR_COMMON_BASE=/mnt/Data/out >> ${HOME}/.bashrc
echo export WITH_GMS=true >> ${HOME}/.bashrc
echo export CCACHE_EXEC=$(which ccache) >> ${HOME}/.bashrc


### Install Android buld requirements
## Use JDK8 as it provides the widest compatibllity
sudo apt -y install openjdk-8-jdk automake lzop bison gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 g++-multilib python3-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven python-mako python3-mako python2 python3 syslinux-utils google-android-build-tools-installer python-is-python2 python3-testresources

## Set up my local bin
mkdir $TMPDIR && cd $TMPDIR
mkdir ${HOME}/bin && echo "export PATH=${HOME}/bin:$PATH" >> ${HOME}/.bashrc
mv bin.zip ${TMPDIR}/
unzip ${TMPDIR}/bin.zip

## Get Google platform-tools
cd $TMPDIR
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip && unzip platform-tools-latest-linux.zip
cp platform-tools/adb ~/bin/adb && cp platform-tools/fastboot ~/bin/fastboot
rm -R platform-tools-latest-linux.zip platform-tools

### Setup webserver
sudo apt install -y nginx php-fpm certbot libnginx-mod-http-geoip libnginx-mod-http-xslt-filter libnginx-mod-http-image-filter libnginx-mod-http-image-filter python3-certbot-nginx 
sudo mv ${HOME}/sites-available/* /etc/nginx/sites-available/
sudo mv ${HOME}/sites-enabled/* /etc/nginx/sites-enabled/

## Change permissions on /var/www
# TODO: Do this right
sudo usermod -a -G www-data ${USERNAME}
sudo chown nolenjohnson:nolenjohnson -R /var/www
sudo chmod -R 755 /var/www

## Set up Downloads site
mkdir -p /var/www/ods.ninja/html/BuildServer/Android/lineage
cd /var/www/ods.ninja/html/BuildServer/Android/lineage
for device in PL2 addons bacon berkeley beast bonito ether flo foster fugu gts4lvwifi h918 hlte hltechn hltekor hltetmo jactivelte jflteatt jfltespr jfltevzw jfltexx jfvelte klte klteactivexx kltechn kltechnduo klteduos kltedv kltekdi kltekor m8 marlin mata molly nash oneplus3 river sailfish sargo shamu shieldtablet tools victara yellowstone
do
  mkdir /var/www/ods.ninja/html/BuildServer/Android/$device
done

cd ${TMPDIR} && wget https://release.larsjung.de/h5ai/h5ai-0.29.2.zip && unzip h5ai-0.29.2.zip
mv _h5ai /var/www/ods.ninja/html/BuildServer/


## Set up Updater (Local)
mkdir -p /var/www/ods.ninja/html
git clone https://github.com/npjohnson/updater.git -b master /var/www/ods.ninja/html/updater
pip3 install -r /var/www/ods.ninja/html/updater/requirements.txt
sudo touch /var/www/ods.ninja/html/BuildServer/Android/lineage/builds.json
sudo bash -c 'echo "" > /var/www/ods.ninja/html/BuildServer/Android/lineage/builds.json

# Set up the service
sudo touch /etc/systemd/system/updater.service
sudo bash -c 'echo [Unit] > /etc/systemd/system/updater.service'
sudo bash -c 'echo Description=Updater service  >> /etc/systemd/system/updater.service'
sudo bash -c 'echo After=network.target >> /etc/systemd/system/updater.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater.service'
sudo bash -c 'echo [Service] >> /etc/systemd/system/updater.service'
sudo bash -c 'echo Type=simple >> /etc/systemd/system/updater.service'
sudo bash -c 'echo User=root >> /etc/systemd/system/updater.service'
sudo bash -c 'echo Environment="FLASK_APP=app.py" >> /etc/systemd/system/updater.service'
sudo bash -c 'echo WorkingDirectory=/var/www/ods.ninja/html/updater >> /etc/systemd/system/updater.service'
sudo bash -c 'echo ExecStart=/usr/local/bin/flask run >> /etc/systemd/system/updater.service'
sudo bash -c 'echo Restart=on-failure >> /etc/systemd/system/updater.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater.service'
sudo bash -c 'echo [Install]  >> /etc/systemd/system/updater.service'
sudo bash -c 'echo WantedBy=multi-user.target >> /etc/systemd/system/updater.service'

# Enable the service on boot
sudo systemctl enable updater.service

# Set up the build indexing service
sudo bash -c 'echo [Unit] >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo Description=Updater builds.json generation >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo [Service] >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo Type=oneshot >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo User=root >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo ExecStart=/bin/sh -c '/usr/bin/python /var/www/ods.ninja/html/updater/gen_mirror_json.py /var/www/ods.ninja/html/BuildServer/Android/lineage > /var/www/ods.ninja/html/BuildServer/Android/lineage/builds.json' >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo [Install] >> /etc/systemd/system/updater-builds.service'
sudo bash -c 'echo WantedBy=multi-user.target >> /etc/systemd/system/updater-builds.service'

### Setup Updater (Production)
mkdir -p /var/www/oddsolutions.us/html
git clone https://github.com/npjohnson/updater.git -b master-prod /var/www/oddsolutions.us/html/updater
sudo touch /var/www/ods.ninja/html/BuildServer/Android/lineage/builds_prod.json
sudo bash -c 'echo "" > /var/www/ods.ninja/html/BuildServer/Android/lineage/builds_prod.json'

## Set up the service
sudo touch /etc/systemd/system/updater-prod.service
sudo bash -c 'echo [Unit] > /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo Description=Updater service  >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo After=network.target >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo [Service] >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo Type=simple >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo User=root >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo Environment="FLASK_APP=app.py" >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo Environment="FLASK_RUN_PORT=5002" >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo WorkingDirectory=/var/www/ods.ninja/html/updater >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo ExecStart=/usr/local/bin/flask run >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo Restart=on-failure >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo [Install]  >> /etc/systemd/system/updater-prod.service'
sudo bash -c 'echo WantedBy=multi-user.target >> /etc/systemd/system/updater-prod.service'

## Enable the service on boot
sudo systemctl enable updater-prod.service

## Set up the build publishing service
sudo bash -c 'echo [Unit] > /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo Description=Prod updater builds.json generation >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo [Service] >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo Type=oneshot >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo User=root >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo ExecStart=/bin/sh -c '/usr/bin/python3 /var/www/oddsolutions.us/html/updater/publish_builds.py' >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo "" >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo [Install] >> /etc/systemd/system/updater-prod-builds.service'
sudo bash -c 'echo WantedBy=multi-user.target >> /etc/systemd/system/updater-prod-builds.service'

### Set up WebSSH
git clone https://github.com/demon000/webssh /var/www/ods.ninja/html/webssh
sudo apt -y install npm
cp /var/www/ods.ninja/html/webssh/config/example.json /var/www/ods.ninja/html/webssh/config/default.json
npm install && npm run link

sudo bash -c 'echo [Service] >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo WorkingDirectory=/var/www/ods.ninja/html/webssh >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo ExecStart=/usr/bin/npm start >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo Restart=always >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo StandardOutput=syslog >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo StandardError=syslog >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo SyslogIdentifier=propanel >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo User=root >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo Group=root >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo Environment=NODE_ENV=production >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo "" >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo [Install] >> /etc/systemd/system/webssh.service'
sudo bash -c 'echo WantedBy=multi-user.target >> /etc/systemd/system/webssh.service'

# Enable to service on boot
sudo systemctl enable webssh.service

# Re-initialize the envirorment
source "${HOME}/.bashrc"

echo "Don't forget to:
echo " Add your new SSH key to:"
echo "  - Gerrit(s): AOSP, DU, LineageOS, OmniROM, TWRP"
echo "  - Revision Tracker(s): GitHub, GitLab, Aaron's GitLab"
echo " Add your GitHub Application password to /var/www/oddsolutions.us/html/updater/publish_builds.py"
echo " Run `sudo certbot` and generate certificates INDIVIDUALLY for all sites, and enable forced HTTPS redirect in the process"
echo " Add your LineageOS HTTP password to ~/.gerritrc"
