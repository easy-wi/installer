# Easy-WI Installer

Quality Code: [![Codacy Badge](https://api.codacy.com/project/badge/Grade/577d1ee61d234585968cc5acbfb2a726)](https://www.codacy.com/app/Lacrimosa99/Easy-WI_Installer?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=easy-wi/installer&amp;utm_campaign=Badge_Grade)

Easy-Wi Installer

Supported OS:
  - Slackware 14.2 (WIP)
  - Debian 8, 9 and 10
  - Ubuntu 16.10, 18.04, 18,10 and 20.04
  - CentOS 7 and 8

___

## Stable Installer up to Debian 8, 9 and 10, Ubuntu 16.10, 18.04, 18.10 and 20.04 and CentOS 7 and 8
  
```sh
LATEST_VERSION=`wget -O installer.tar.gz https://github.com/easy-wi/installer/archive/3.0.tar.gz
tar zxf installer.tar.gz && mv ./installer-*/easy-wi_install.sh ./
rm -r installer.tar.gz installer-*/

#if you runnig as user (not root):
sudo bash ./easy-wi_install.sh

#if you runnig as root:
bash ./easy-wi_install.sh
```
___

## Unstable Installer (Developer Version)
  
```sh 
wget --no-check-certificate https://raw.githubusercontent.com/easy-wi/installer/master/easy-wi_install.sh

#if you runnig as user (not root):
sudo bash ./easy-wi_install.sh

#if you runnig as root:
bash ./easy-wi_install.sh
```
___

## Support Channel
Discord: [Easy-WI Discord Channel](https://discord.gg/quJvvfF)

Github: [Easy-WI Github Channel](https://github.com/easy-wi/installer/issues)
