# Easy-WI Installer

Quality Code: [![Codacy Badge](https://api.codacy.com/project/badge/Grade/577d1ee61d234585968cc5acbfb2a726)](https://www.codacy.com/app/Lacrimosa99/Easy-WI_Installer?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=easy-wi/installer&amp;utm_campaign=Badge_Grade)

Easy-Wi Installer

Supported OS:
  - Debian (stable Installer up to Debian 8, newer include in unstable Installer)
  - Ubuntu (stable Installer up to Ubuntu 16.10, newer include in unstable Installer)
  - CentOS (only include in unstable Installer)
  
## Unstable Installer (Developer Version)
  
```sh 
wget https://raw.githubusercontent.com/easy-wi/installer/master/easy-wi_install.sh
bash ./easy-wi_install.sh
```

## Stable Installer
  
```sh
LATEST_VERSION=`wget -q --timeout=60 -O - https://api.github.com/repos/easy-wi/installer/releases/latest | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)'`
wget -O installer.tar.gz https://github.com/easy-wi/installer/archive/$LATEST_VERSION.tar.gz
tar zxf installer.tar.gz && mv ./installer-*/easy-wi_install.sh ./
rm -r installer.tar.gz installer-*/
bash easy-wi_install.sh
```
