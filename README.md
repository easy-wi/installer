# Easy-WI Installer

Quality Code: [![Codacy Badge](https://app.codacy.com/project/badge/Grade/8d71b350f73e4df8b5836f7fb6fe121f)](https://www.codacy.com/gh/easy-wi/installer/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=easy-wi/installer&amp;utm_campaign=Badge_Grade)

Easy-Wi Installer

Supported OS:
  - Slackware 14.2 (WIP)
  - Debian 8, 9, 10 and 11
  - Ubuntu 16, 17, 18, 19, 20, 21 and 22
  - CentOS 7 and 8

___
# Currently CentOS 8 & 9 is not Supported we are working on it !
> Due to WebServer ID issue
## Stable Installer up to Debian 10/11, Ubuntu 20/21/22 and CentOS 7 [NOT UPDATED TO JDK-17]
  
```sh
wget -O installer.tar.gz https://github.com/easy-wi/installer/archive/3.2.tar.gz
tar zxf installer.tar.gz && mv ./installer-*/easy-wi_install.sh ./
rm -r installer.tar.gz installer-*/

#start the installer with (sudo required):
sudo bash ./easy-wi_install.sh

```
___

## Unstable Installer (Developer Version) [UPDATED TO JDK-17]
  
```sh 
wget --no-check-certificate https://raw.githubusercontent.com/easy-wi/installer/master/easy-wi_install.sh

#start the installer with (sudo required):
sudo bash ./easy-wi_install.sh

```
___

## Support Channel
Discord: [Easy-WI Discord Channel](https://discord.gg/quJvvfF)

Github: [Easy-WI Github Channel](https://github.com/easy-wi/installer/issues)
