# Easy-WI Installer

Quality Code: [![Codacy Badge](https://app.codacy.com/project/badge/Grade/8d71b350f73e4df8b5836f7fb6fe121f)](https://www.codacy.com/gh/easy-wi/installer/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=easy-wi/installer&amp;utm_campaign=Badge_Grade)

Easy-Wi Installer

Supported OS:
  - Slackware 14.2 (WIP)
  - Debian 8, 9 and 10
  - Ubuntu 16.10, 18.04, 18,10 and 20.04
  - CentOS 7 and 8

___

## Stable Installer up to Debian 8, 9 and 10, Ubuntu 16.10, 18.04, 18.10 and 20.04 and CentOS 7 and 8
  
```sh
wget -O installer.tar.gz https://github.com/easy-wi/installer/archive/3.2.tar.gz
tar zxf installer.tar.gz && mv ./installer-*/easy-wi_install.sh ./
rm -r installer.tar.gz installer-*/

#start the installer with (sudo required):
sudo bash ./easy-wi_install.sh

```
___

## Unstable Installer (Developer Version) [Newer Java Installer Included]
  
```sh 
wget --no-check-certificate https://raw.githubusercontent.com/easy-wi/installer/master/easy-wi_install.sh

#start the installer with (sudo required):
sudo bash ./easy-wi_install.sh

```
___

## Support Channel
Discord: [Easy-WI Discord Channel](https://discord.gg/quJvvfF)

Github: [Easy-WI Github Channel](https://github.com/easy-wi/installer/issues)
