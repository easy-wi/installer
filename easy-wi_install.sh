#!/bin/bash

DEBUG="ON"

#    Author:     Ulrich Block <ulrich.block@easy-wi.com>
#
#    This file is part of Easy-WI.
#
#    Easy-WI is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Easy-WI is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Easy-WI.  If not, see <http://www.gnu.org/licenses/>.
#
#    Diese Datei ist Teil von Easy-WI.
#
#    Easy-WI ist Freie Software: Sie koennen es unter den Bedingungen
#    der GNU General Public License, wie von der Free Software Foundation,
#    Version 3 der Lizenz oder (nach Ihrer Wahl) jeder spaeteren
#    veroeffentlichten Version, weiterverbreiten und/oder modifizieren.
#
#    Easy-WI wird in der Hoffnung, dass es nuetzlich sein wird, aber
#    OHNE JEDE GEWAEHELEISTUNG, bereitgestellt; sogar ohne die implizite
#    Gewaehrleistung der MARKTFAEHIGKEIT oder EIGNUNG FUER EINEN BESTIMMTEN ZWECK.
#    Siehe die GNU General Public License fuer weitere Details.
#
#    Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
#    Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.

if [ "$DEBUG" = "ON" ]; then
	set -x
fi

greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

cyanMessage() {
	echo -e "\\033[36;1m${@}\033[0m"
}

redMessage() {
	echo -e "\\033[31;1m${@}\033[0m"
}

yellowMessage() {
	echo -e "\\033[33;1m${@}\033[0m"
}

greenOneLineMessage() {
	echo -en "\\033[32;1m${@}\033[0m"
}

cyanOneLineMessage() {
	echo -en "\\033[36;1m${@}\033[0m"
}

yellowOneLineMessage() {
	echo -en "\\033[33;1m${@}\033[0m"
}

errorAndQuit() {
	errorAndExit "Exit now!"
}

errorAndExit() {
	cyanMessage " "
	redMessage ${@}
	cyanMessage " "
	exit 0
}

errorAndContinue() {
	redMessage "Invalid option."
	continue
}

removeIfExists() {
	if [ "$1" != "" -a -f "$1" ]; then
		rm -f $1
	fi
}

runSpinner() {
	SPINNER=("-" "\\" "|" "/")

	for SEQUENCE in `seq 1 $1`; do
		for I in "${SPINNER[@]}"; do
			echo -ne "\b$I"
			sleep 0.1
		done
	done
}

okAndSleep() {
	greenMessage $1
	sleep 1
}

makeDir() {
	if [ "$1" != "" -a ! -d $1 ]; then
		mkdir -p $1
	fi
}

backUpFile() {
	if [ ! -f "$1.easy-install.backup" ]; then
		cp "$1" "$1.easy-install.backup"
	fi
}

checkInstall() {
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ "`dpkg-query -s $1 2>/dev/null`" == "" ]; then
			okAndSleep "Installing package $1"
			$INSTALLER -y install $1
		fi
	elif [ "$OS" == "centos" ]; then
		if [ "`rpm -qa $1 2>/dev/null`" == "" ]; then
			okAndSleep "Installing package $1"
			$INSTALLER -y install $1
		fi
	fi
}

checkUser() {
	if [ "$1" == "" ]; then
		redMessage "Error: No masteruser specified"
	elif [ "$1" == "root" ]; then
		redMessage "Error: Using root as masteruser is a security hazard and not allowed."
	elif [ "`id $1 2> /dev/null`" != "" ] && ([ "$INSTALL" != "EW" -a "$INSTALL" != "WR" ] || [ ! -d "/home/$1/sites-enabled" ]); then
		redMessage "Error: User \"$1\" already exists. Please name a not yet existing user"
	else
		echo 1
	fi
}

RestartWebserver() {
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ "$WEBSERVER" == "Nginx" ]; then
			cyanMessage " "
			if [ "$PHPINSTALL" == "Yes" ]; then
				okAndSleep "Restarting PHP-FPM and Nginx."
				service php${USE_PHP_VERSION}-fpm restart 1>/dev/null
			else
				okAndSleep "Restarting Nginx."
			fi
			service nginx restart
		elif [ "$WEBSERVER" == "Apache" ]; then
			cyanMessage " "
			okAndSleep "Restarting PHP-FPM and Apache2."
			service apache2 restart 1>/dev/null
		elif [ "$WEBSERVER" == "Lighttpd" ]; then
			cyanMessage " "
			okAndSleep "Restarting PHP-FPM and Lighttpd."
			service lighttpd restart 1>/dev/null
		fi
	elif [ "$OS" == "centos" ]; then
		if [ "$WEBSERVER" == "Nginx" ]; then
			cyanMessage " "
			if [ -f /etc/php-fpm.conf ]; then
				okAndSleep "Restarting PHP-FPM and Nginx."
				systemctl restart php-fpm.service 1>/dev/null
			else
				okAndSleep "Restarting Nginx."
			fi
			systemctl restart nginx.service 1>/dev/null
		elif [ "$WEBSERVER" == "Apache" ]; then
			cyanMessage " "
			if [ -f /etc/php-fpm.conf ]; then
				okAndSleep "Restarting PHP-FPM and Apache2."
				systemctl restart php-fpm.service 1>/dev/null
			else
				okAndSleep "Restarting Apache2."
			fi
			systemctl restart httpd.service 1>/dev/null
		elif [ "$WEBSERVER" == "Lighttpd" ]; then
			cyanMessage " "
			if [ -f /etc/php-fpm.conf ]; then
				okAndSleep "Restarting PHP-FPM and Lighttpd."
				systemctl restart php-fpm.service 1>/dev/null
			else
				okAndSleep "Restarting Lighttpd."
			fi
			systemctl restart lighttpd.service 1>/dev/null
		fi
	fi
}

RestartDatabase() {
	if [ "$SQL" != "None" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			/etc/init.d/mysql restart 1>/dev/null
		elif [ "$OS" == "centos" ]; then
			if [ "$SQL_VERSION" == "5.5" ]; then
				systemctl restart mariadb.service 1>/dev/null
			elif [ "$SQL_VERSION" == "10" ]; then
				systemctl restart mysql.service 1>/dev/null
			fi
		fi
	fi
}

INSTALLER_VERSION="2.2"
OS=""
SYS_REBOOT="No"
USERADD=`which useradd`
USERMOD=`which usermod`
USERDEL=`which userdel`
GROUPADD=`which groupadd`
MACHINE=`uname -m`
LOCAL_IP=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`

if [ "$LOCAL_IP" == "" ]; then
	HOST_NAME=`hostname -f | awk '{print tolower($0)}'`
else
	HOST_NAME=`getent hosts $LOCAL_IP | awk '{print tolower($2)}' | head -n 1`
fi

if [ -f /etc/debian_version ]; then
	INSTALLER="apt-get"
	OS="debian"
elif [ -f /etc/centos-release ]; then
	INSTALLER="yum"
	OS="centos"
	setenforce 0 >/dev/null 2>&1
	cyanMessage " "
	$INSTALLER install -y -q wget >/dev/null 2
fi

cyanMessage " "
cyanMessage "Checking for the latest installer version"
LATEST_VERSION=`wget -q --timeout=60 -O - https://api.github.com/repos/easy-wi/installer/releases/latest | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)'`

if [ "`printf "${LATEST_VERSION}\n${INSTALLER_VERSION}" | sort -V | tail -n 1`" != "$INSTALLER_VERSION" ]; then
	errorAndExit "You are using the old version ${INSTALLER_VERSION}. Please upgrade to version ${LATEST_VERSION} and retry."
else
	okAndSleep "You are using the up to date version ${INSTALLER_VERSION}"
fi

# We need to be root to install and update
if [ "`id -u`" != "0" ]; then
	cyanMessage "Change to root account required"
	su -
fi

if [ "`id -u`" != "0" ]; then
	errorAndExit "Still not root, aborting"
fi

cyanMessage " "
okAndSleep "Update the system packages to the latest version? Required, as otherwise dependencies might brake!"

OPTIONS=("Yes" "Quit")
select UPDATE_UPGRADE_SYSTEM in "${OPTIONS[@]}"; do
	case "$REPLY" in
		1 ) break;;
		2 ) errorAndQuit;;
		*) errorAndContinue;;
	esac
done

cyanMessage " "
yellowMessage "Please wait... Update is currently running."
if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
	cyanMessage " "
	$INSTALLER update
	$INSTALLER upgrade
	$INSTALLER dist-upgrade
	checkInstall debconf-utils
	checkInstall lsb-release
elif [ "$OS" == "centos" ]; then
	cyanMessage " "
	cyanMessage "Update all obsolete packages."
	$INSTALLER update -y
	checkInstall redhat-lsb
	checkInstall epel-release
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
	checkInstall yum-utils
fi
checkInstall curl

cyanMessage " "
OS=`lsb_release -i 2> /dev/null | grep 'Distributor' | awk '{print tolower($3)}'`
OSVERSION=`lsb_release -r 2> /dev/null | grep 'Release' | awk '{print $2}'`
OSBRANCH=`lsb_release -c 2> /dev/null | grep 'Codename' | awk '{print $2}'`

if [ "$MACHINE" == "x86_64" ]; then
	ARCH="amd64"
elif [ "$MACHINE" == "i386" ]||[ "$MACHINE" == "i686" ]; then
	ARCH="x86"
fi

if [ "$OS" == "" ]; then
	errorAndExit "Error: Could not detect OS. Currently only Debian, Ubuntu and CentOS are supported. Aborting!"
else
	okAndSleep "Detected OS: $OS"
fi

if [ "$OSBRANCH" == "" ]; then
	errorAndExit "Error: Could not detect branch of OS. Aborting"
else
	okAndSleep "Detected branch: $OSBRANCH"
fi

if [ "$OSVERSION" == "" ]; then
	errorAndExit "Error: Could not detect version of OS. Aborting"
else
	okAndSleep "Detected version: $OSVERSION"

	if [ "$OS" == "ubuntu" -o "$OS" == "debian" ]; then
		OSVERSION_TMP=`echo "$OSVERSION" | tr -d .`
	fi
fi

if [ "$ARCH" == "" ]; then
	errorAndExit "Error: $MACHINE is not supported! Aborting"
else
	okAndSleep "Detected architecture: $ARCH"
fi

if [ "$OS" == "ubuntu" -a "$OSVERSION_TMP" -le "1510" -o "$OS" == "debian" -a "$OSVERSION_TMP" -lt "70" -o "$OS" == "centos" -a "$OSVERSION_TMP" -lt "70"  ]; then
	echo; echo
	redMessage "Error: Your OS \"$OS - $OSVERSION\"  is not more supported from Easy-WI Installer."
	redMessage "Please Upgrade to a newer OS Version!"
	echo
	exit 0
fi

cyanMessage " "
cyanMessage "What shall be installed/prepared?"

OPTIONS=("Gameserver Root" "Voicemaster" "Easy-WI Webpanel" "Webspace Root" "MySQL" "Quit")
select OPTION in "${OPTIONS[@]}"; do
	case "$REPLY" in
		1|2|3|4|5 ) break;;
		6 ) errorAndQuit;;
		*) errorAndContinue;;
	esac
done

if [ "$OPTION" == "Easy-WI Webpanel" ]; then
	INSTALL="EW"
elif [ "$OPTION" == "Gameserver Root" ]; then
	INSTALL="GS"
elif [ "$OPTION" == "Voicemaster" ]; then
	INSTALL="VS"
elif [ "$OPTION" == "Webspace Root" ]; then
	INSTALL="WR"
elif [ "$OPTION" == "MySQL" ]; then
	INSTALL="MY"
fi

OTHER_PANEL=""

if [ "$INSTALL" != "VS" ]; then
	if [ -f /etc/init.d/psa ]; then
		OTHER_PANEL="Plesk"
	elif [ -f /usr/local/vesta/bin/v-change-user-password ]; then
		OTHER_PANEL="VestaCP"
	elif [ -d /root/confixx ]; then
		OTHER_PANEL="Confixx"
	elif [ -d /var/www/froxlor ]; then
		OTHER_PANEL="Froxlor"
	elif [ -d /etc/imscp ]; then
		OTHER_PANEL="i-MSCP"
	elif [ -d /usr/local/ispconfig ]; then
		OTHER_PANEL="ISPConfig"
	elif [ -d /var/cpanel ]; then
		OTHER_PANEL="cPanel"
	elif [ -d /usr/local/directadmin ]; then
		OTHER_PANEL="DirectAdmin"
	fi
fi

if [ "$OTHER_PANEL" != "" ]; then
	if [ "$INSTALL" == "GS" ]; then
		yellowMessage " "
		yellowMessage "Warning an installation of the control panel $OTHER_PANEL has been detected."
		yellowMessage "If you continue the installer might end up breaking $OTHER_PANEL or same parts of Easy-WI might not work."
		OPTIONS=("Continue" "Quit")
		select UPDATE_UPGRADE_SYSTEM in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1 ) break;;
				2 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done
	else
		errorAndExit "Aborting as the risk of breaking the installed panel $OTHER_PANEL is too high."
	fi
fi

# Run the domain/IP check up front to avoid late error out.
if [ "$INSTALL" == "EW" ]; then
	cyanMessage " "
	cyanMessage "At which URL/Domain should Easy-Wi be placed?"
	OPTIONS=("$HOST_NAME" "$LOCAL_IP" "Other" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2|3 ) break;;
			4 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Other" ]; then
		cyanMessage " "
		cyanMessage "Please specify the IP or domain Easy-Wi should run at."
		read IP_DOMAIN
	else
		IP_DOMAIN=$OPTION
	fi

	if [ "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $IP_DOMAIN`" == "" -a "`grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' <<< $IP_DOMAIN`" == "" ]; then
		errorAndExit "Error: $IP_DOMAIN is neither a domain nor an IPv4 address!"
	fi

	FILE_NAME=${IP_DOMAIN//./_}

	cyanMessage " "
	cyanMessage "Install stable or latest developer version?"

	OPTIONS=("Stable" "Developer" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	RELEASE_TYPE=$OPTION
fi

if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" -o "$INSTALL" == "MY" ]; then
	if [ "$OS" == "debian" -a "$INSTALL" != "MY" ]; then
		cyanMessage " "
		cyanMessage "Use dotdeb.org repository for more up to date server and PHP versions?"

		OPTIONS=("Yes" "No" "Quit")
		select DOTDEB in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		if [ "$DOTDEB" == "Yes" ]; then
			if [ "`grep 'packages.dotdeb.org' /etc/apt/sources.list`" == "" ]; then
				okAndSleep "Adding entries to /etc/apt/sources.list"

				if [ "$OSBRANCH" == "squeeze" -o "$OSBRANCH" == "wheezy" ]; then
					checkInstall python-software-properties
				elif [ "$OSBRANCH" == "jessie" -o "$OSBRANCH" == "stretch" ]; then
					checkInstall software-properties-common
				fi

				add-apt-repository "deb http://packages.dotdeb.org $OSBRANCH all"
				add-apt-repository "deb-src http://packages.dotdeb.org $OSBRANCH all"
				curl --remote-name https://www.dotdeb.org/dotdeb.gpg
				apt-key add dotdeb.gpg
				removeIfExists dotdeb.gpg
				$INSTALLER update
			fi
		fi
	fi

	if [ "$INSTALL" != "MY" ]; then
		cyanMessage " "
		cyanMessage "Please select the webserver you would like to use"
	fi

	if [ "$INSTALL" == "EW" ]; then
		cyanMessage "Apache is recommended in case you want to run additional sites on this host."
		cyanMessage "Nginx is recommended if the server should only run the Easy-WI Web Panel."

		OPTIONS=("Nginx" "Apache" "Quit")
		select WEBSERVER in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

	elif [ "$INSTALL" != "MY" ]; then
		cyanMessage "Nginx is recommended for FastDL and few but high efficient vhosts"
		cyanMessage "Apache is recommended in case you want to run many PHP supporting Vhosts aka mass web hosting"

		OPTIONS=("Nginx" "Apache" "Lighttpd" "None" "Quit")
		select WEBSERVER in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2|3|4 ) break;;
				5 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done
	fi
fi

# If we need to install and configure a webspace than we need to identify the groupID
if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" ]; then
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		WEBGROUPNAME="www-data"
		WEBGROUPTMPID="33"
		WEBGROUPPATH="/var/www"
		WEBGROUPCOMMENT="Webserver"
	elif [ "$OS" == "centos" ]; then
		if [ "$WEBSERVER" == "Nginx" ]; then
			WEBGROUPNAME="nginx"
			WEBGROUPTMPID="994"
			WEBGROUPPATH="/var/lib/nginx"
			WEBGROUPCOMMENT="Nginx web server"
		elif [ "$WEBSERVER" == "Lighttpd" ]; then
			WEBGROUPNAME="lighttpd"
			WEBGROUPTMPID="993"
			WEBGROUPPATH="/var/www/lighttpd"
			WEBGROUPCOMMENT="lighttpd web server"
		elif [ "$WEBSERVER" == "Apache" ]; then
			WEBGROUPNAME="apache"
			WEBGROUPTMPID="48"
			WEBGROUPPATH="/usr/share/httpd"
			WEBGROUPCOMMENT="Apache"
		fi
	fi

	WEBGROUPID=`getent group $WEBGROUPNAME | awk -F ':' '{print $3}'`
	if [ "$WEBGROUPID" != "$WEBGROUPTMPID" ]; then
		$GROUPADD -g $WEBGROUPTMPID $WEBGROUPNAME >/dev/null 2>&1
		if [ "$WEBSERVER" == "Lighttpd" -o "$WEBSERVER" == "Nginx" ]; then
			$USERADD -c "$WEBGROUPCOMMENT" -u $WEBGROUPTMPID -g $WEBGROUPTMPID -s /sbin/nologin -r -d $WEBGROUPPATH $WEBGROUPNAME
		fi
		WEBGROUPID=`getent group $WEBGROUPNAME | awk -F ':' '{print $3}'`
	fi

	if [ "$INSTALL" == "EW" ]; then
		OPTION="Yes"
	else
		cyanMessage " "
		cyanOneLineMessage 'Found group "'
		yellowOneLineMessage "$WEBGROUPNAME"
		cyanOneLineMessage '" with group ID "'
		yellowOneLineMessage "$WEBGROUPID"
		cyanMessage '". Use as webservergroup?'

		OPTIONS=("Yes" "No" "Quit")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done
	fi

	if [ "$OPTION" == "No" ]; then
		cyanMessage "Please name the group you want to use as webservergroup"
		read WEBGROUP

		WEBGROUPID=`getent group $WEBGROUP | awk -F ':' '{print $3}'`
		if [ "$WEBGROUPID" == "" ]; then
			$GROUPADD $WEBGROUP
			WEBGROUPID=`getent group $WEBGROUP | awk -F ':' '{print $3}'`
		fi
	fi

	if [ "$WEBGROUPID" == "" ]; then
		errorAndExit "Fatal Error: missing webservergroup ID"
	elif [ "$WEBGROUPID" != "$WEBGROUPTMPID" ]; then
		errorAndExit "Fatal Error: wrong webservergroup ID"
	fi
fi

# Run the TS3 server version detect up front to avoid user executing steps first and fail at download last.
if [ "$INSTALL" == "VS" ]; then
	cyanMessage " "
	okAndSleep "Searching latest build for hardware type $MACHINE with arch $ARCH."

	for VERSION in `curl -s "http://dl.4players.de/ts/releases/?C=M;O=D" | grep -Po '(?<=href=")[0-9]+(\.[0-9]+){2,3}(?=/")' | sort -Vr`; do
		DOWNLOAD_URL_VERSION="http://dl.4players.de/ts/releases/$VERSION/teamspeak3-server_linux_$ARCH-$VERSION.tar.bz2"
		STATUS=`curl -I $DOWNLOAD_URL_VERSION 2>&1 | grep "HTTP/" | awk '{print $2}'`

		if [ "$STATUS" == "200" ]; then
			DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
			break
		fi
	done

	if [ "$STATUS" == "200" -a "$DOWNLOAD_URL" != "" ]; then
		okAndSleep "Detected latest server version as $VERSION with download URL $DOWNLOAD_URL"
	else
		errorAndExit "Could not detect latest server version"
	fi
fi

if [ "$INSTALL" != "MY" ]; then
	cyanMessage " "
	cyanMessage "Please enter the name of the masteruser, which does not exist yet."
	read MASTERUSER

	CHECK_USER=`checkUser $MASTERUSER`

	if [ "$CHECK_USER" != "1" ]; then
		echo $CHECK_USER
		read MASTERUSER
		CHECK_USER=`checkUser $MASTERUSER`

		if [ "$CHECK_USER" != "1" ]; then
			echo $CHECK_USER
			errorAndExit "Fatal Error: No valid masteruser specified in two tries"
		fi
	fi

	if [ "`id $1 2> /dev/null`" != "" ]; then
		if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" ]; then
			$USERADD -m -b /home -s /bin/bash -g $WEBGROUPNAME $MASTERUSER
		else
			$GROUPADD $MASTERUSER
			$USERADD -m -b /home -s /bin/bash -g $MASTERUSER $MASTERUSER
		fi
	fi

	cyanMessage " "
	cyanMessage "Create key or set password for login?"
	cyanMessage "Safest way of login is a password protected key."

	if [ "$INSTALL" == "EW" ]; then
		cyanMessage "Neither is required, when installing Easy-WI Webpanel."
	fi

	OPTIONS=("Create key" "Set password" "Skip" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2|3 ) break;;
			4 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Create key" ]; then
		if [ -d /home/$MASTERUSER/.ssh ]; then
			rm -rf /home/$MASTERUSER/.ssh
		fi

		mkdir -p /home/$MASTERUSER/.ssh
		chown $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER/.ssh >/dev/null 2>&1
		cd /home/$MASTERUSER/.ssh

		cyanMessage " "
		cyanMessage "It is recommended but not required to set a password"
		su -c "ssh-keygen -t rsa" $MASTERUSER

		KEYNAME=`find -maxdepth 1 -name "*.pub" | head -n 1`

		if [ "$KEYNAME" != "" ]; then
			su -c "cat $KEYNAME >> authorized_keys" $MASTERUSER
		else
			redMessage "Error: could not find a key. You might need to create one manually at a later point."
		fi
	elif [ "$OPTION" == "Set password" ]; then
		passwd $MASTERUSER
	fi
fi

# only in case we want to manage webspace we need the additional skel dir
if [ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ]; then
	makeDir /home/$MASTERUSER/sites-enabled/
	makeDir /home/$MASTERUSER/skel/htdocs
	makeDir /home/$MASTERUSER/skel/logs
	makeDir /home/$MASTERUSER/skel/session
	makeDir /home/$MASTERUSER/skel/tmp
	chown -cR $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER >/dev/null 2>&1
fi

if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" -o "$INSTALL" == "MY" ]; then
	cyanMessage " "
	if [ "$WEBSERVER" == "Nginx" -a "$INSTALL" != "MY" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall nginx-full
		elif [ "$OS" == "centos" ]; then
			if [ -d /etc/httpd ]; then
				systemctl disable httpd.service >/dev/null 2>&1
				systemctl stop httpd.service
			fi
			checkInstall nginx
			systemctl enable nginx.service >/dev/null 2>&1
		fi
	elif [ "$WEBSERVER" == "Lighttpd" -a "$INSTALL" != "MY" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" -o "$OS" == "centos" ]; then
			checkInstall lighttpd
			systemctl enable lighttpd.service >/dev/null 2>&1
		fi
	elif [ "$WEBSERVER" == "Apache" -a "$INSTALL" != "MY" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall apache2
		elif [ "$OS" == "centos" ]; then
			checkInstall httpd
			systemctl enable httpd.service >/dev/null 2>&1
		fi
	fi

	if [ "$INSTALL" == "EW" -a "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		cyanMessage " "
		okAndSleep "Please note that Easy-Wi requires a MySQL or MariaDB installed and will install MySQL if no DB is installed"
		if [ "$OS" == "debian" -a "$OSVERSION_TMP" -ge "90" ]; then
			SQL="MariaDB"
		else
			if [ "`ps ax | grep mysql | grep -v grep`" == "" ]; then
				SQL="MySQL"
			else
				SQL=""
			fi
		fi
	else
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			cyanMessage " "
			cyanMessage "Please select if an which database server to install."
			cyanMessage "Select \"None\" in case this server should host only Fastdownload webspace."

			OPTIONS=("MySQL" "MariaDB" "None" "Quit")
			select SQL in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2|3 ) break;;
					4 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done
		elif [ "$OS" == "centos" ]; then
			SQL="MariaDB"
			SQL_VERSION="5.5"
		fi

		if [ "$OS" == "centos" -a "$SQL" == "MariaDB" -a "$INSTALL" == "WR" -o "$INSTALL" == "MY" ]; then
			if [ "`ps fax | grep 'mysqld' | grep -v 'grep'`" == "" ]; then
				cyanMessage " "
				cyanMessage "Please select which "$SQL" Version to install."

				OPTIONS=("5.5" "10" "Quit")
				select SQL_VERSION in "${OPTIONS[@]}"; do
					case "$REPLY" in
						1|2 ) break;;
						3 ) errorAndQuit;;
						*) errorAndContinue;;
					esac
				done
			else
				SQL="None"
			fi
		fi
	fi

	if [ "$SQL" == "MySQL" -o "$SQL" == "MariaDB" ]; then
		if [ "`ps fax | grep 'mysqld' | grep -v 'grep'`" != "" ]; then
			cyanMessage " "
			cyanMessage "Please provide the root password for the MySQL Database."
			read MYSQL_ROOT_PASSWORD

			mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
			ERROR_CODE=$?

			until [ $ERROR_CODE == 0 ]; do
				cyanMessage "Password incorrect, please provide the root password for the MySQL Database."
				read MYSQL_ROOT_PASSWORD

				mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
				ERROR_CODE=$?
			done
		else
			until [ "$MYSQL_ROOT_PASSWORD" != "" ]; do
				cyanMessage " "
				cyanMessage "Please provide the root password for the MySQL Database."
				read MYSQL_ROOT_PASSWORD
			done
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			export DEBIAN_FRONTEND="noninteractive"
			echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
			echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
		fi
	fi

	if [ "$SQL" == "MariaDB" ]; then
		RUNUPDATE=0
		if ([ "$OS" == "debian" -a "`printf "${OSVERSION_TMP}\n8.0" | sort -V | tail -n 1`" == "8.0" -o "$OS" == "ubuntu" ] && [ "`grep '/mariadb/' /etc/apt/sources.list`" == "" ]); then
			checkInstall python-software-properties
			apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db

			if [ "$SQL" == "MariaDB" -a "`apt-cache search mariadb-server-10.0`" == "" ]; then
				add-apt-repository "deb http://mirror.netcologne.de/mariadb/repo/10.0/$OS $OSBRANCH main"
				RUNUPDATE=1
			fi
		fi
	elif [ "$OS" == "centos" -a "$SQL_VERSION" == "10" ]; then
		if [ ! -f /etc/yum.repos.d/MariaDB.repo ]; then
			MARIADB_FILE=$(ls /etc/yum.repos.d/)
			for search_mariadb in "${MARIADB_FILE[@]}"; do
				if [ "`grep '/MariaDB/' $search_mariadb >/dev/null 2>&1`" == "" -a ! -f /etc/yum.repos.d/MariaDB.repo ]; then
					echo '# MariaDB 10.0 CentOS repository list - created 2017-06-15 22:41 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' > /etc/yum.repos.d/MariaDB.repo
				fi
			done
			rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
			RUNUPDATE=1
		fi

		if [ "$OS" == "debian" -a "$DOTDEB" == "Yes" ]; then
			echo "Package: *" > /etc/apt/preferences.d/mariadb.pref
			echo "Pin: origin mirror.netcologne.de" >> /etc/apt/preferences.d/mariadb.pref
			echo "Pin-Priority: 1000" >> /etc/apt/preferences.d/mariadb.pref
			RUNUPDATE=1
		fi
	fi

	if [ "$RUNUPDATE" == "1" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			$INSTALLER update >/dev/null 2>&1
		elif [ "$OS" == "centos" ]; then
			$INSTALLER update -y -q
		fi
	fi

	if [ "$SQL" == "MySQL" ]; then
		cyanMessage " "
		checkInstall mysql-server
		checkInstall mysql-client
		checkInstall mysql-common
	elif [ "$SQL" == "MariaDB" ]; then
		cyanMessage " "
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall mariadb-server
			checkInstall mariadb-client
			if ([ "`printf "${OSVERSION_TMP}\n8.0" | sort -V | tail -n 1`" == "8.0" -o "$OS" == "ubuntu" ] && [ "`grep '/mariadb/' /etc/apt/sources.list`" == "" ]); then
				checkInstall mysql-common
			else
				checkInstall mariadb-common
			fi
		elif [ "$OS" == "centos" ]; then
			if [ "$SQL_VERSION" == "5.5" ]; then
				checkInstall mariadb-server
				systemctl enable mariadb.service >/dev/null 2>&1
				RestartDatabase
			elif [ "$SQL_VERSION" == "10" ]; then
				checkInstall MariaDB-server
				systemctl enable mysql.service >/dev/null 2>&1
				RestartDatabase
			fi

		fi
	fi

	if [ "$SQL" != "None" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" -a -f /etc/mysql/my.cnf ]; then
			backUpFile /etc/mysql/my.cnf
		elif [ "$OS" == "centos" -a -f /etc/my.cnf -a -f /usr/share/mysql/my-medium.cnf ]; then
			backUpFile /etc/my.cnf
			cp /usr/share/mysql/my-medium.cnf -R /etc/my.cnf
		else
			errorAndExit "$SQL Database not fully installed!"
		fi
	fi

	if [ "$SQL" != "None" ]; then
		if [ "$INSTALL" == "WR" -o "$INSTALL" == "MY" ]; then
			cyanMessage " "
			cyanMessage "Is Easy-WI installed on a different server."

			OPTIONS=("Yes" "No" "Quit")
			select EXTERNAL_INSTALL in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2 ) break;;
					3 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done
		fi

		cyanMessage " "
		okAndSleep "Securing MySQL by running \"mysql_secure_installation\" commands."
		RestartDatabase
		if [ "$OS" == "centos" -o "$OS" == "ubuntu" -a "$OSVERSION_TMP" -ge "1603" -o "$OS" == "debian" -a "OSVERSION_TMP" -ge "90" ] && [ "$MYSQL_ROOT_PASSWORD" == "" ]; then
			mysqladmin password "$MYSQL_ROOT_PASSWORD"
		fi
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DELETE FROM mysql.user WHERE User='';"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DROP DATABASE test;"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "FLUSH PRIVILEGES;"
	fi

	if [ "$EXTERNAL_INSTALL" == "Yes" ]; then
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "GRANT USAGE ON *.* TO 'root'@'' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" 2> /dev/null
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "UPDATE mysql.user SET Select_priv='Y',Insert_priv='Y',Update_priv='Y',Delete_priv='Y',Create_priv='Y',Drop_priv='Y',Reload_priv='Y',Shutdown_priv='Y',Process_priv='Y',File_priv='Y',Grant_priv='Y',References_priv='Y',Index_priv='Y',Alter_priv='Y',Show_db_priv='Y',Super_priv='Y',Create_tmp_table_priv='Y',Lock_tables_priv='Y',Execute_priv='Y',Repl_slave_priv='Y',Repl_client_priv='Y',Create_view_priv='Y',Show_view_priv='Y',Create_routine_priv='Y',Alter_routine_priv='Y',Create_user_priv='Y',Event_priv='Y',Trigger_priv='Y',Create_tablespace_priv='Y' WHERE User='root' AND Host='';" 2> /dev/null

		if [ "$LOCAL_IP" == "" ]; then
			cyanMessage " "
			cyanMessage "Could not detect local IP. Please specify which to use."
			read LOCAL_IP
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			MYSQL_CONF="/etc/mysql/my.cnf"
		elif [ "$OS" == "centos" ]; then
			MYSQL_CONF="/etc/my.cnf"
		fi

		if [ "$LOCAL_IP" != "" -a -f "$MYSQL_CONF" ]; then
			if [ "`grep 'bind-address' $MYSQL_CONF`" ]; then
				sed -i "s/bind-address.*/bind-address = 0.0.0.0/g" $MYSQL_CONF
			else
				sed -i "/\[mysqld\]/abind-address = 0.0.0.0" $MYSQL_CONF
			fi
		fi
	elif [ "$EXTERNAL_INSTALL" == "No" ]; then
		if [ "$OS" == "centos" ]; then
			sed -i "/\[mysqld\]/abind-address = 127.0.0.1" /etc/my.cnf
		fi
	fi

	if [ "$SQL" != "None" ]; then
		MYSQL_VERSION=`mysql -V | awk {'print $5'} | tr -d ,`
	fi

	if [ "$SQL" != "None" -a "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ "`grep -E 'key_buffer[[:space:]]*=' /etc/mysql/my.cnf`" != "" -a "printf "${MYSQL_VERSION}\n5.5" | sort -V | tail -n 1" != "5.5" ]; then
			sed -i -e "51s/key_buffer[[:space:]]*=/key_buffer_size = /g" /etc/mysql/my.cnf
			sed -i -e "57s/myisam-recover[[:space:]]*=/myisam-recover-options = /g" /etc/mysql/my.cnf
		fi
		if [ "$SQL" != "None" -a "$OS" == "ubuntu" -a "$OSVERSION_TMP" -ge "1603" -a ! -f /etc/mysql/conf.d/disable_strict_mode.cnf ]; then
			echo '[mysqld]' > /etc/mysql/conf.d/disable_strict_mode.cnf
			echo 'sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' >> /etc/mysql/conf.d/disable_strict_mode.cnf
		fi
	fi

	RestartDatabase

	if [ "$INSTALL" == "EW" -a "`ps ax | grep mysql | grep -v grep`" == "" ]; then
		cyanMessage " "
		errorAndExit "Error: No SQL server running but required for Webpanel installation."
	fi

	if [ "$INSTALL" == "EW" ]; then
		cyanMessage " "
		okAndSleep "Please note that Easy-Wi will install required PHP packages."
		PHPINSTALL="Yes"
	elif [ "$INSTALL" != "MY" ]; then
		cyanMessage " "
		cyanMessage "Install/Update PHP?"
		cyanMessage "Select \"None\" in case this server should host only Fastdownload webspace."

		OPTIONS=("Yes" "No" "None" "Quit")
		select PHPINSTALL in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2|3 ) break;;
				4 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done
	fi

	if [ "$PHPINSTALL" == "Yes" ]; then
		USE_PHP_VERSION='5'

		if [ "$OS" == "ubuntu" -a "$OSVERSION_TMP" -ge "1603" -o "$OS" == "debian" -a "$OSVERSION_TMP" -ge "85" ]; then
			USE_PHP_VERSION='7.0'
		fi

		if [ "$OS" == "debian" -a "$DOTDEB" == "Yes" ]; then
			cyanMessage " "
			if [ "$OSBRANCH" == "wheezy" ]; then
				cyanMessage "Which PHP version should be used?"

				OPTIONS=("5.4" "5.5", "5.6", "5.6 Zend thread safety" "Quit")
				select DOTDEBPHPUPGRADE in "${OPTIONS[@]}"; do
					case "$REPLY" in
						1|2|3|4 ) break;;
						5 ) errorAndQuit;;
						*) errorAndContinue;;
					esac
				done

				if [ "$DOTDEBPHPUPGRADE" == "5.5" -a "`grep 'wheezy-php55' /etc/apt/sources.list`" == "" ]; then
					add-apt-repository "deb http://packages.dotdeb.org wheezy-php55 all"
					add-apt-repository "deb-src http://packages.dotdeb.org wheezy-php55 all"
				elif [ "$DOTDEBPHPUPGRADE" == "5.6" -a "`grep 'wheezy-php56' /etc/apt/sources.list`" == "" ]; then
					add-apt-repository "deb http://packages.dotdeb.org wheezy-php56 all"
					add-apt-repository "deb-src http://packages.dotdeb.org wheezy-php56 all"
				elif [ "$DOTDEBPHPUPGRADE" == "5.6 Zend thread safety" -a "`grep 'wheezy-php56-zts' /etc/apt/sources.list`" == "" ]; then
					add-apt-repository "deb http://packages.dotdeb.org wheezy-php56-zts all"
					add-apt-repository "deb-src http://packages.dotdeb.org wheezy-php56-zts all"
				fi
			elif [ "$OSBRANCH" == "squeeze" -a "`grep 'squeeze-php54' /etc/apt/sources.list`" == "" ]; then
				add-apt-repository "deb http://packages.dotdeb.org squeeze-php54 all"
				add-apt-repository "deb-src http://packages.dotdeb.org squeeze-php54 all"
			fi

			if [ "$DOTDEBPHPUPGRADE" == "Yes" ]; then
				$INSTALLER update
				$INSTALLER upgrade -y && $INSTALLER dist-upgrade -y
			fi
		fi

		cyanMessage " "
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall php${USE_PHP_VERSION}
			checkInstall php${USE_PHP_VERSION}-common
			checkInstall php${USE_PHP_VERSION}-curl
			checkInstall php${USE_PHP_VERSION}-gd
			checkInstall php${USE_PHP_VERSION}-mcrypt
			checkInstall php${USE_PHP_VERSION}-mysql
			checkInstall php${USE_PHP_VERSION}-cli
			checkInstall php${USE_PHP_VERSION}-xml
			checkInstall php${USE_PHP_VERSION}-mbstring
		elif [ "$OS" == "centos" ]; then
			checkInstall php
			checkInstall php-common
			checkInstall php-gd
			checkInstall php-mcrypt
			checkInstall php-mysql
			checkInstall php-cli
			checkInstall php-xml
			checkInstall php-mbstring
		fi

		if [ "$WEBSERVER" == "Nginx" -o "$WEBSERVER" == "Lighttpd" ]; then
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				checkInstall php${USE_PHP_VERSION}-fpm
				if [ "$WEBSERVER" == "Lighttpd" ]; then
					lighttpd-enable-mod fastcgi
					lighttpd-enable-mod fastcgi-php
				fi
			elif [ "$OS" == "centos" ]; then
				checkInstall php-fpm
				systemctl enable php-fpm.service >/dev/null 2>&1

				backUpFile /etc/php.ini
				backUpFile /etc/php-fpm.conf
				backUpFile /etc/php-fpm.d/www.conf

				if [ "$WEBSERVER" == "Lighttpd" ]; then
					sed -i "s/user = apache/user = lighttpd/g" /etc/php-fpm.d/www.conf
					sed -i "s/group = apache/group = lighttpd/g" /etc/php-fpm.d/www.conf
				elif [ "$WEBSERVER" == "Nginx" ]; then
					sed -i "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf
					sed -i "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf
				fi
			fi

			makeDir /home/$MASTERUSER/fpm-pool.d/

			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				if [ -f /etc/php5/fpm/php-fpm.conf ]; then
					sed -i "s/include=\/etc\/php5\/fpm\/pool.d\/\*.conf/include=\/home\/$MASTERUSER\/fpm-pool.d\/\*.conf/g" /etc/php5/fpm/php-fpm.conf
				elif [ -f /etc/php/7.0/fpm/php-fpm.conf ]; then
					sed -i "s/include=\/etc\/php\/7.0\/fpm\/pool.d\/\*.conf/include=\/home\/$MASTERUSER\/fpm-pool.d\/\*.conf/g" /etc/php/7.0/fpm/php-fpm.conf
				fi
			elif [ "$OS" == "centos" -a -f /etc/php-fpm.conf ]; then
				sed -i "s/include=\/etc\/php-fpm.d\/\*.conf/include=\/home\/$MASTERUSER\/fpm-pool.d\/\*.conf/g" /etc/php-fpm.conf
			fi
		elif [ "$WEBSERVER" == "Apache" ]; then
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				checkInstall apache2-mpm-itk
				checkInstall libapache2-mpm-itk
				checkInstall libapache2-mod-php${USE_PHP_VERSION}
				a2enmod php${USE_PHP_VERSION}
			elif [ "$OS" == "centos" ]; then
				checkInstall httpd-itk
				backUpFile /etc/httpd/conf.modules.d/00-mpm-itk.conf
				sed -i "s/#LoadModule mpm_itk_module modules\/mod_mpm_itk.so/LoadModule mpm_itk_module modules\/mod_mpm_itk.so/g" /etc/httpd/conf.modules.d/00-mpm-itk.conf
			fi
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ] && [ -f /etc/php5/fpm/php-fpm.conf ]; then
			PHP_SOCKET="/var/run/php${USE_PHP_VERSION}-fpm.sock"
		elif [ "$OS" == "debian" -o "$OS" == "ubuntu" ] && [ -f /etc/php/7.0/fpm/php-fpm.conf ]; then
			#In case of php 7 the socket is different
			PHP_SOCKET="/var/run/php/php${USE_PHP_VERSION}-fpm.sock"
		elif [ "$OS" == "centos" -a -f /etc/php-fpm.conf ]; then
			#In case of centos the socket is different
			PHP_SOCKET="/var/run/php-fpm/php-fpm.sock"
		fi
	fi

	RestartWebserver
fi

if ([ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ] && [ "`grep '/bin/false' /etc/shells`" == "" ]); then
	echo "/bin/false" >> /etc/shells
fi

if [ "$INSTALL" != "VS" -a "$INSTALL" != "EW" -a "$INSTALL" != "MY" ]; then
	cyanMessage " "
	cyanMessage "Install/Update ProFTPD?"

	OPTIONS=("Yes" "No" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Yes" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
		elif [ "$OS" == "centos" ]; then
			$INSTALLER update -y -q
		fi

		cyanMessage " "
		checkInstall proftpd

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			backUpFile /etc/proftpd/proftpd.conf
			if [ -f /etc/proftpd/modules.conf ]; then
				backUpFile /etc/proftpd/modules.conf
				sed -i 's/.*LoadModule mod_tls_memcache.c.*/#LoadModule mod_tls_memcache.c/g' /etc/proftpd/modules.conf
			fi
			sed -i 's/.*UseIPv6.*/UseIPv6 off/g' /etc/proftpd/proftpd.conf
			sed -i 's/#.*DefaultRoot.*~/DefaultRoot ~/g' /etc/proftpd/proftpd.conf
			sed -i 's/# RequireValidShell.*/RequireValidShell on/g' /etc/proftpd/proftpd.conf
		elif [ "$OS" == "centos" ]; then
			mkdir -p /etc/proftpd
			if [ ! -f /etc/proftpd/proftpd.conf ];then
				mv /etc/proftpd.conf /etc/proftpd/
				cd /etc
				ln -s /etc/proftpd/proftpd.conf proftpd.conf
			fi
			backUpFile /etc/proftpd/proftpd.conf
			if [ "`cat /etc/proftpd/proftpd.conf | grep 'Include'`" == "" ]; then
				echo "Include /etc/proftpd/conf.d/" >> /etc/proftpd/proftpd.conf
				mkdir -p /etc/proftpd/conf.d
			fi
		fi

		if [ -f /etc/proftpd/proftpd.conf -a "$INSTALL" != "GS" ]; then
			sed -i 's/Umask.*/Umask 037 027/g' /etc/proftpd/proftpd.conf
		elif [ -f /etc/proftpd/proftpd.conf -a "$INSTALL" == "GS" ]; then
			sed -i 's/Umask.*/Umask 077 077/g' /etc/proftpd/proftpd.conf

			cyanMessage " "
			cyanMessage "Install/Update ProFTPD Rules?"

			OPTIONS=("Yes" "No" "Quit")
			select OPTION in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2 ) break;;
					3 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done

			if [ "$OPTION" == "Yes" -a "`grep '<Directory \/home\/\*\/pserver\/\*>' /etc/proftpd/proftpd.conf`" == "" -a ! -f /etc/proftpd/conf.d/easy-wi.conf ]; then
				makeDir /etc/proftpd/conf.d/
				chmod 755 /etc/proftpd/conf.d/

				echo "
<Directory ~>
    HideFiles (^\..+|\.ssh|\.bash_history|\.bash_logout|\.bashrc|\.profile|srcds_run|srcds_linux|hlds_run|hlds_amd|hlds_i686|\.rc|\.sh|\.7z|\.dll)$
    PathDenyFilter (^\..+|\.ssh|\.bash_history|\.bash_logout|\.bashrc|\.profile|srcds_run|srcds_linux|hlds_run|hlds_amd|hlds_i686|\.rc|\.sh|\.7z|\.dll)$
    HideNoAccess on
    <Limit RNTO RNFR STOR DELE CHMOD SITE_CHMOD MKD RMD>
        DenyAll
    </Limit>
</Directory>" > /etc/proftpd/conf.d/easy-wi.conf
				echo "<Directory /home/$MASTERUSER>" >> /etc/proftpd/conf.d/easy-wi.conf
				echo "    HideFiles (^\..+|\.ssh|\.bash_history|\.bash_logout|\.bashrc|\.profile)$
    PathDenyFilter (^\..+|\.ssh|\.bash_history|\.bash_logout|\.bashrc|\.profile)$
    HideNoAccess on
    Umask 137 027
    <Limit RNTO RNFR STOR DELE CHMOD SITE_CHMOD MKD RMD>
        AllowAll
    </Limit>
</Directory>
<Directory /home/*/pserver/*>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>
<Directory ~/backup>
    Umask 177 077
    <Limit RNTO RNFR STOR DELE>
        AllowAll
    </Limit>
</Directory>
<Directory ~/*/>
    HideFiles (^\..+|srcds_run|srcds_linux|hlds_run|hlds_amd|hlds_i686|\.rc|\.sh|\.7z|\.dll)$
    PathDenyFilter (^\..+|srcds_run|srcds_linux|hlds_run|hlds_amd|hlds_i686|\.rc|\.sh|\.7z|\.dll)$
    HideNoAccess on
</Directory>" >> /etc/proftpd/conf.d/easy-wi.conf

				GAMES=("ark" "arma3" "bukkit" "hexxit" "mc" "mtasa" "projectcars" "rust" "samp" "spigot" "teeworlds" "tekkit" "tekkit-classic")
				for GAME in ${GAMES[@]}; do
					echo "<Directory ~/server/$GAME*/*>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>" >> /etc/proftpd/conf.d/easy-wi.conf
				done

				GAME_MODS=("csgo" "cstrike" "czero" "orangebox" "dod" "garrysmod")
				for GAME_MOD in ${GAME_MODS[@]}; do
					echo "<Directory ~/server/*/${GAME_MOD}/*>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>" >> /etc/proftpd/conf.d/easy-wi.conf
				done

				FOLDERS=("addons" "cfg" "maps")
				for FOLDER in ${FOLDERS[@]}; do
					echo "<Directory ~/*/*/*/${FOLDER}>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE>
        AllowAll
    </Limit>
</Directory>
<Directory ~/*/*/${FOLDER}>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>" >> /etc/proftpd/conf.d/easy-wi.conf
				done
			fi
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ -f /etc/init.d/proftpd ]; then
				service proftpd restart
			fi
		elif [ "$OS" == "centos" ]; then
			if [ -f /usr/sbin/proftpd ]; then
				systemctl enable proftpd >/dev/null 2>&1
				systemctl restart proftpd 1>/dev/null
			fi
		fi
	fi
fi

if [ "$INSTALL" == "GS" -o "$INSTALL" == "WR" ]; then
	cyanMessage " "
	cyanMessage "Install Quota?"

	OPTIONS=("Yes" "No" "Quit")
	select QUOTAINSTALL in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$QUOTAINSTALL" == "Yes" ]; then
		cyanMessage " "
		checkInstall quota

		removeIfExists /root/tempfstab
		removeIfExists /root/tempmountpoints

		cat /etc/fstab | while read LINE; do
			if [[ `echo $LINE | grep '/' | egrep -v '#|boot|proc|swap|floppy|cdrom|usrquota|usrjquota|/sys|/shm|/pts'` ]]; then
				CURRENTOPTIONS=`echo $LINE | awk '{print $4}'`
				echo $LINE | sed "s/$CURRENTOPTIONS/$CURRENTOPTIONS,usrjquota=aquota.user,jqfmt=vfsv0/g" >> /root/tempfstab
				echo $LINE | awk '{print $2}' >> /root/tempmountpoints
			else
				echo $LINE >> /root/tempfstab
			fi
		done

		cat /root/tempfstab

		cyanMessage " "
		cyanMessage "Please check above output and confirm it is correct. On confirmation the current /etc/fstab will be replaced in order to activate Quotas!"

		OPTIONS=("Yes" "No" "Quit")
		select QUOTAFSTAB in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		cyanMessage " "
		if [ "$QUOTAFSTAB" == "Yes" ]; then
			backUpFile /etc/fstab
			mv /root/tempfstab /etc/fstab
		fi

		removeIfExists /root/tempfstab
		removeIfExists /aquota.user
		touch /aquota.user
		chmod 600 /aquota.user

		if [ -f /root/tempmountpoints ]; then
			cat /root/tempmountpoints | while read LINE; do
				quotaoff -ugv $LINE
				removeIfExists $LINE/aquota.user
				okAndSleep "Remounting $LINE"
				mount -o remount $LINE

				quotacheck -vumc $LINE
				quotaon -uv $LINE
			done

			removeIfExists /root/tempmountpoints
		fi
	fi
fi

if [ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ]; then
	if [ "$WEBSERVER" == "Nginx" ]; then
		backUpFile /etc/nginx/nginx.conf
		if [ "`grep '/home/$MASTERUSER/sites-enabled/' /etc/nginx/nginx.conf`" == "" ]; then
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				sed -i "\/etc\/nginx\/sites-enabled\/\*;/a \ \ \include \/home\/$MASTERUSER\/sites-enabled\/\*;" /etc/nginx/nginx.conf
			elif [ "$OS" == "centos" ]; then
#				sed -i 's/include \/etc\/nginx\/default.d\/*.conf;/#include \/etc\/nginx\/default.d\/*.conf;/g' /etc/nginx/nginx.conf ##################################################
				sed -i 's/\/usr\/share\/nginx\/html;/\/home;/g' /etc/nginx/nginx.conf
				echo "# Include Easy-WI Webserver Templates" >> /etc/nginx/nginx.conf
				echo "include /home/$MASTERUSER/sites-enabled/*.conf;" >> /etc/nginx/nginx.conf
			fi
		fi
	elif [ "$WEBSERVER" == "Lighttpd" ]; then
		backUpFile /etc/lighttpd/lighttpd.conf
		echo "include_shell \"find /home/$MASTERUSER/sites-enabled/ -maxdepth 1 -type f -exec cat {} \;\"" >> /etc/lighttpd/lighttpd.conf
	elif [ "$WEBSERVER" == "Apache" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			APACHE_CONFIG="/etc/apache2/apache2.conf"
		elif [ "$OS" == "centos" ]; then
			APACHE_CONFIG="/etc/httpd/conf/httpd.conf"
		fi

		backUpFile $APACHE_CONFIG

		if [ "$OS" == "centos" ]; then
			if [ "`grep '<IfModule mpm_itk_module>' $APACHE_CONFIG`" == "" ]; then
				echo " " >> $APACHE_CONFIG
				cat >> $APACHE_CONFIG <<_EOF_
<IfModule mpm_itk_module>
  AssignUserId $WEBGROUPNAME $WEBGROUPNAME
  MaxClientsVHost 50
  NiceValue 10
  LimitUIDRange 0 10000
  LimitGIDRange 0 10000
</IfModule>
_EOF_
			fi
		fi


		if [ "`grep 'ServerName localhost' $APACHE_CONFIG`" == "" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent error message Could not reliably determine the servers fully qualified domain name' >> $APACHE_CONFIG
			echo 'ServerName localhost' >> $APACHE_CONFIG
		fi

		if [ "`grep 'ServerTokens' $APACHE_CONFIG`" == "" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent the server information off in productive systems' >> $APACHE_CONFIG
			echo 'ServerTokens prod' >> $APACHE_CONFIG
		fi

		if [ "`grep 'ServerSignature' $APACHE_CONFIG`" == "" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent the server signatur off in productive systems' >> $APACHE_CONFIG
			echo 'ServerSignature off' >> $APACHE_CONFIG
			echo " " >> $APACHE_CONFIG
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			APACHE_VERSION=`apache2 -v | grep 'Server version'`
		elif [ "$OS" == "centos" ]; then
			APACHE_VERSION=`httpd -v | grep 'Server version'`
		fi

		if [ "`grep '/home/$MASTERUSER/sites-enabled/' $APACHE_CONFIG`" == "" ]; then
			echo '# Load config files in the "/home/$MASTERUSER/sites-enabled" directory, if any.' >>  $APACHE_CONFIG
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				if [[ $APACHE_VERSION =~ .*Apache/2.2.* ]]; then
					sed -i "/Include sites-enabled\//a Include \/home\/$MASTERUSER\/sites-enabled\/" $APACHE_CONFIG
					sed -i "/Include \/etc\/apache2\/sites-enabled\//a \/home\/$MASTERUSER\/sites-enabled\/" $APACHE_CONFIG
				else
					sed -i "/IncludeOptional sites-enabled\//a IncludeOptional \/home\/$MASTERUSER\/sites-enabled\/*.conf" $APACHE_CONFIG
					sed -i "/IncludeOptional \/etc\/apache2\/sites-enabled\//a IncludeOptional \/home\/$MASTERUSER\/sites-enabled\/*.conf" $APACHE_CONFIG
				fi
			elif [ "$OS" == "centos" ]; then
				if [[ $APACHE_VERSION =~ .*Apache/2.2.* ]]; then
					echo "Include /home/$MASTERUSER/sites-enabled/" >> $APACHE_CONFIG
				else
					echo "IncludeOptional /home/$MASTERUSER/sites-enabled/*.conf" >> $APACHE_CONFIG
				fi
			fi
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			okAndSleep "Activating Apache mod_rewrite module."
			a2enmod rewrite
			a2enmod version 2> /dev/null
		fi
	fi
	#TODO: Logrotate
fi

# No direct root access for masteruser. Only limited access through sudo
if [ "$INSTALL" == "GS" -o "$INSTALL" == "WR" ]; then
	checkInstall sudo
	if [ -f /etc/sudoers -a "`grep $MASTERUSER /etc/sudoers | grep $USERADD`" == "" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERADD" >> /etc/sudoers
	fi

	if [ -f /etc/sudoers -a "`grep $MASTERUSER /etc/sudoers | grep $USERMOD`" == "" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERMOD" >> /etc/sudoers
	fi

	if [ -f /etc/sudoers -a "`grep $MASTERUSER /etc/sudoers | grep $USERDEL`" == "" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERDEL" >> /etc/sudoers
	fi

	if [ "$QUOTAINSTALL" == "Yes" -a -f /etc/sudoers ]; then
		if [ "`grep $MASTERUSER /etc/sudoers | grep setquota`" == "" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: `which setquota`" >> /etc/sudoers
		fi

		if [ "`grep $MASTERUSER /etc/sudoers | grep repquota`" == "" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: `which repquota`" >> /etc/sudoers
		fi
	fi

	if [ "$INSTALL" == "GS" -a -f /etc/sudoers -a "`grep $MASTERUSER /etc/sudoers | grep temp`" == "" ]; then
		echo "$MASTERUSER ALL = (ALL, !root:easywi) NOPASSWD: /home/$MASTERUSER/temp/*.sh" >> /etc/sudoers
	fi

	if [ "$WEBSERVER" == "Nginx" ]; then
		HTTPDBIN=`which nginx`
		HTTPDSCRIPT="/etc/init.d/nginx"
	elif [ "$WEBSERVER" == "Lighttpd" ]; then
		HTTPDBIN=`which lighttpd`
		HTTPDSCRIPT="/etc/init.d/lighttpd"
	elif [ "$WEBSERVER" == "Apache" ]; then
		HTTPDBIN=`which apache2`
		HTTPDSCRIPT="/etc/init.d/apache2"
	fi

	if [ "$HTTPDBIN" != "" -a -f /etc/sudoers ]; then
		if [ "`grep $MASTERUSER /etc/sudoers | grep $HTTPDBIN`" == "" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: $HTTPDBIN" >> /etc/sudoers
		fi

		if [ "`grep $MASTERUSER /etc/sudoers | grep $HTTPDSCRIPT`" == "" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: $HTTPDSCRIPT" >> /etc/sudoers
		fi

		if [ "$PHPINSTALL" == "Yes" -a "$WEBSERVER" == "Nginx" ]; then
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				if [ "`grep $MASTERUSER /etc/sudoers | grep 'php${USE_PHP_VERSION}-fpm'`" == "" ]; then
					FPM_BIN=`which php${USE_PHP_VERSION}-fpm`
					echo "$MASTERUSER ALL = NOPASSWD: /etc/init.d/php${USE_PHP_VERSION}-fpm" >> /etc/sudoers
					if [ "$FPM_BIN" != "" -a "`grep $MASTERUSER /etc/sudoers | grep '$FPM_BIN'`" == "" ]; then
						echo "$MASTERUSER ALL = NOPASSWD: $FPM_BIN" >> /etc/sudoers
					fi
				fi
			elif [ "$OS" == "centos" ]; then
				if [ "`grep $MASTERUSER /etc/sudoers | grep 'php-fpm'`" == "" ]; then
					FPM_BIN=`which php-fpm`
					echo "$MASTERUSER ALL = NOPASSWD: /etc/init.d/php-fpm" >> /etc/sudoers
					if [ "$FPM_BIN" != "" -a "`grep $MASTERUSER /etc/sudoers | grep '$FPM_BIN'`" == "" ]; then
						echo "$MASTERUSER ALL = NOPASSWD: $FPM_BIN" >> /etc/sudoers
					fi
				fi
			fi
		fi
	fi
fi

if [ "$INSTALL" == "WR" ]; then
	chown -cR $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER/ >/dev/null 2>&1

	cyanMessage " "
	greenMessage "Following data need to be configured at the easy-wi.com panel:"

	cyanMessage " "
	greenOneLineMessage "The path to the folder \"sites-enabled\" is: "
	cyanMessage "/home/$MASTERUSER/sites-enabled/"

	greenOneLineMessage "The useradd command is: "
	cyanMessage "sudo $USERADD %cmd%"

	greenOneLineMessage "The usermod command is: "
	cyanMessage "sudo $USERMOD %cmd%"

	greenOneLineMessage "The userdel command is: "
	cyanMessage "sudo $USERDEL %cmd%"

	if [ "$HTTPDSCRIPT" != "" ]; then
		greenOneLineMessage "The HTTPD restart command is: "
		cyanMessage "sudo $HTTPDSCRIPT reload"
	fi

	if [ "$PHPINSTALL" == "Yes" -a "$FPM_BIN" != "" -a "$WEBSERVER" == "Nginx" ]; then
		cyanMessage " "
		greenOneLineMessage "The PHP FPM restart command is: "
		cyanMessage "sudo $FPM_BIN reload"
	fi
fi

if ([ "$INSTALL" == "GS" -o "$INSTALL" == "WR" ] && [ "$QUOTAINSTALL" == "Yes" ]); then
	cyanMessage " "
	greenOneLineMessage "The setquota command is: "
	cyanMessage "sudo `which setquota` %cmd%"

	greenOneLineMessage "The repquota command is: "
	cyanMessage "sudo `which repquota` %cmd%"
fi

if [ "$INSTALL" == "GS" ]; then
	if [ ! -f /bin/false ]; then
		touch /bin/false
	fi

	if [ "`grep '/bin/false' /etc/shells`" == "" ]; then
		echo "/bin/false" >> /etc/shells
	fi

	cyanMessage " "
	cyanMessage "Java JRE 8 will be required for running Minecraft and its mods. Shall it be installed?"
	OPTIONS=("Yes" "No" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Yes" ]; then
		cyanMessage " "
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ "$OSBRANCH" == "jessie" -a "`grep jessie-backports /etc/apt/sources.list`" == "" ]; then
				okAndSleep "Adding jessie backports"
				echo "deb http://ftp.de.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
				$INSTALLER update
			fi

			if [ "$OSBRANCH" == "jessie" ]; then
				apt install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y
			fi

			checkInstall openjdk-8-jdk
		elif [ "$OS" == "centos" ]; then
			checkInstall java-1.8.0-openjdk
		fi
	fi

	cyanMessage " "
	okAndSleep "Creating folders and files"
	CREATEDIRS=("conf" "fdl_data/hl2" "logs" "masteraddons" "mastermaps" "masterserver" "temp")
	for CREATEDIR in ${CREATEDIRS[@]}; do
		greenMessage "Adding dir: /home/$MASTERUSER/$CREATEDIR"
		makeDir /home/$MASTERUSER/$CREATEDIR
	done

	LOGFILES=("addons" "hl2" "server" "fdl" "update" "fdl-hl2")
	for LOGFILE in ${LOGFILES[@]}; do
		touch "/home/$MASTERUSER/logs/$LOGFILE.log"
	done
	chmod 660 /home/$MASTERUSER/logs/*.log

	chown -cR $MASTERUSER:$MASTERUSER /home/$MASTERUSER/ >/dev/null 2>&1
	chmod -R 750 /home/$MASTERUSER/
	chmod -R 770 /home/$MASTERUSER/logs/ /home/$MASTERUSER/temp/ /home/$MASTERUSER/fdl_data/

	if [ "$OS" == "debian" -a "$OSVERSION_TMP" -lt "9" ]; then
		if [ "`uname -m`" == "x86_64" -a "`cat /etc/debian_version | grep '6.'`" == "" ]; then
			dpkg --add-architecture i386
		fi
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		cyanMessage " "
		okAndSleep "Installing required packages wput screen bzip2 sudo rsync zip unzip"
		$INSTALLER install wput screen bzip2 sudo rsync zip unzip -y

		if [ "`uname -m`" == "x86_64" ]; then
			cyanMessage " "
			okAndSleep "Installing 32bit support for 64bit systems."

			$INSTALLER install zlib1g -y
			$INSTALLER install lib32z1 -y
			$INSTALLER install lib32gcc1 -y
			$INSTALLER install lib32readline5 -y
			$INSTALLER install lib32ncursesw5 -y
			$INSTALLER install lib32stdc++6 -y
			$INSTALLER install lib64stdc++6 -y
			$INSTALLER install libstdc++6 -y
			$INSTALLER install libgcc1:i386 -y
			$INSTALLER install libreadline5:i386 -y
			$INSTALLER install libncursesw5:i386 -y
			$INSTALLER install zlib1g:i386 -y
		else
			$INSTALLER install libreadline5 libncursesw5 -y
		fi
	elif [ "$OS" == "centos" ]; then
		cyanMessage " "
		okAndSleep "Installing required packages screen bzip2 sudo rsync zip unzip"
		checkInstall screen
		checkInstall bzip2
		checkInstall sudo
		checkInstall rsync
		checkInstall zip
		checkInstall unzip

#		#WPut from rpmforge
#		wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el7/en/x86_64/rpmforge/RPMS/
#		rpm -Uvh rpmforge-release*rpm
#		checkInstall wput

		if [ "`uname -m`" == "x86_64" ]; then
			okAndSleep "Installing 32bit support for 64bit systems."
			checkInstall glibc.i686
			checkInstall libstdc++.i686
		fi
		checkInstall libgcc
	fi

	cyanMessage " "
	okAndSleep "Downloading SteamCmd"
	cd /home/$MASTERUSER/masterserver
	makeDir /home/$MASTERUSER/masterserver/steamCMD/
	cd /home/$MASTERUSER/masterserver/steamCMD/
	curl --remote-name http://media.steampowered.com/client/steamcmd_linux.tar.gz

	if [ -f steamcmd_linux.tar.gz ]; then
		tar xfvz steamcmd_linux.tar.gz
		removeIfExists steamcmd_linux.tar.gz
		chown -cR $MASTERUSER:$MASTERUSER /home/$MASTERUSER/masterserver/steamCMD >/dev/null 2>&1
		su -c "./steamcmd.sh +login anonymous +quit" $MASTERUSER

		if [ -f /home/$MASTERUSER/masterserver/steamCMD/linux32/steamclient.so ]; then
			su -c "mkdir -p ~/.steam/sdk32/" $MASTERUSER
			su -c "chmod 750 -R ~/.steam/" $MASTERUSER
			su -c "ln -s ~/masterserver/steamCMD/linux32/steamclient.so ~/.steam/sdk32/steamclient.so" $MASTERUSER
		fi
	fi

	chown -cR $INSTALLMASTER:$INSTALLMASTER /home/$INSTALLMASTER >/dev/null 2>&1

	if [ -f /etc/crontab -a "`grep 'Minecraft can easily produce 1GB' /etc/crontab`" == "" ]; then
		if ionice -c3 true 2>/dev/null; then
			IONICE="ionice -n 7 "
		fi

		echo "#Minecraft can easily produce 1GB+ logs within one hour" >> /etc/crontab
		echo "*/5 * * * * root nice -n +19 ionice -n 7 find /home/*/server/*/ -maxdepth 2 -type f -name \"screenlog.0\" -size +100M -delete" >> /etc/crontab
		echo "# Even sudo /usr/sbin/deluser --remove-all-files is used some data remain from time to time" >> /etc/crontab
		echo "*/5 * * * * root nice -n +19 $IONICE find /home/ -maxdepth 2 -type d -nouser -delete" >> /etc/crontab
		echo "*/5 * * * * root nice -n +19 $IONICE find /home/*/fdl_data/ /home/*/temp/ /tmp/ /var/run/screen/ -nouser -print0 | xargs -0 rm -rf" >> /etc/crontab
		echo "*/5 * * * * root nice -n +19 $IONICE find /var/run/screen/ -maxdepth 1 -type d -nouser -print0 | xargs -0 rm -rf" >> /etc/crontab

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			service cron restart 1>/dev/null
		elif [ "$OS" == "centos" ]; then
			systemctl restart crond.service 1>/dev/null
		fi
	fi
fi

if [ "$INSTALL" == "EW" ]; then
	if [ -f /home/easywi_web/htdocs/serverallocation.php ]; then
		cyanMessage " "
		cyanMessage "There is already an existing installation. Should it be removed?"
		OPTIONS=("Yes" "Quit")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1 ) break;;
				2 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		cyanMessage " "
		rm -rf /home/easywi_web/htdocs/*
		cyanMessage " "
		cyanMessage "Please provide the root password for the MySQL Database, to remove the old easywi database."
		read MYSQL_ROOT_PASSWORD
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DROP DATABASE easy_wi;"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "DROP USER easy_wi@localhost;"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -BSe "FLUSH PRIVILEGES;"
	fi

	if [ "`id easywi_web 2> /dev/null`" == "" -a ! -d /home/easywi_web ]; then
		$USERADD -md /home/easywi_web -g $WEBGROUPNAME -s /bin/bash -k /home/$MASTERUSER/skel/ easywi_web
	elif [ "`id easywi_web 2> /dev/null`" == "" -a -d /home/easywi_web ]; then
		$USERADD -d /home/easywi_web -g $WEBGROUPNAME -s /bin/bash easywi_web
	fi

	makeDir /home/easywi_web/htdocs
	makeDir /home/easywi_web/logs
	makeDir /home/easywi_web/tmp
	makeDir /home/easywi_web/session
	chown -cR easywi_web:$WEBGROUPNAME /home/easywi_web >/dev/null 2>&1

	if [ "`id easywi_web 2> /dev/null`" == "" ]; then
		errorAndExit "Web user easywi_web does not exists! Exiting now!"
	fi

	if [ ! -d /home/easywi_web/htdocs ]; then
		errorAndExit "No /home/easywi_web/htdocs dir created! Exiting now!"
	fi

	checkInstall unzip
	cd /home/easywi_web/htdocs/

	cyanMessage " "
	okAndSleep "Downloading latest Easy-WI ${RELEASE_TYPE} version."
	if [ "${RELEASE_TYPE}" == "Stable" ]; then
		DOWNLOAD_URL=`wget -q --timeout=60 -O - https://api.github.com/repos/easy-wi/developer/releases/latest | grep -Po '(?<="zipball_url": ")([\w:/\-.]+)'`
	else
		DOWNLOAD_URL=`wget -q --timeout=60 -O - https://api.github.com/repos/easy-wi/developer/tags | grep -Po '(?<="zipball_url": ")([\w:/\-.]+)' | head -n 1`
	fi

	curl -L ${DOWNLOAD_URL} -o web.zip

	if [ ! -f web.zip ]; then
		errorAndExit "Can not download Easy-WI. Aborting!"
	fi

	okAndSleep "Unpack zipped Easy-WI archive."
	unzip -u web.zip >/dev/null 2>&1
	removeIfExists web.zip

	HEX_FOLDER=`ls | grep 'easy-wi-developer-' | head -n 1`
	if [ "${HEX_FOLDER}" != "" ]; then
		mv ${HEX_FOLDER}/* ./
		rm -rf ${HEX_FOLDER}
	fi

	find /home/easywi_web/ -type f -exec chmod 0640 {} \;
	find /home/easywi_web/ -mindepth 1 -type d -exec chmod 0750 {} \;

	chown -cR easywi_web:$WEBGROUPNAME /home/easywi_web >/dev/null 2>&1

	DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c18`
	cyanMessage " "
	okAndSleep "Creating database easy_wi and connected user easy_wi"
	if [ "$MYSQL_ROOT_PASSWORD" == "" ]; then
		cyanMessage " "
		cyanMessage "Please provide the root password for the MySQL Database."
		read MYSQL_ROOT_PASSWORD
	fi
	mysql -u root -p$MYSQL_ROOT_PASSWORD -Bse "CREATE DATABASE IF NOT EXISTS easy_wi; GRANT ALL ON easy_wi.* TO 'easy_wi'@'localhost' IDENTIFIED BY '$DB_PASSWORD'; FLUSH PRIVILEGES;"

	cyanMessage " "
	cyanMessage "Secure Vhost with SSL? (recommended!)"
	OPTIONS=("Yes" "No" "Quit")
	select SSL in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$SSL" == "Yes" ]; then
		if [[ "$IP_DOMAIN" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			SSL_KEY="Self-signed"
		else
			cyanMessage " "
			cyanMessage "Which Certificate do you want to install?"
			OPTIONS=("Self-signed" "Lets Encrypt" "Quit")
			select SSL_KEY in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2 ) break;;
					3 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done
		fi

		if [ "$SSL_KEY" == "Lets Encrypt" ]; then
			okAndSleep "Installing package certbot"
			if [ "$OS" == "debian" ]; then
				if [ "$OSBRANCH" == "wheezy" ]; then
					wget https://dl.eff.org/certbot-auto
					chmod a+x certbot-auto
				elif [ "$OSBRANCH" == "jessie" ]; then
					if [ "`grep jessie-backports /etc/apt/sources.list`" == "" ]; then
          	okAndSleep "Adding jessie backports"
          	echo "deb http://ftp.de.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
					fi
          $INSTALLER update
					$INSTALLER install certbot -t jessie-backports -y
				fi
			elif [ "$OS" == "ubuntu" ]; then
				$INSTALLER install software-properties-common
				add-apt-repository ppa:certbot/certbot
				$INSTALLER update
				checkInstall certbot
			elif [ "$OS" == "centos" ]; then
				$INSTALLER-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional -y
				checkInstall certbot
			fi
		else
			if [ "$WEBSERVER" == "Nginx" ]; then
				SSL_DIR=/etc/nginx/ssl
			elif [ "$WEBSERVER" == "Apache" ]; then
				if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
					SSL_DIR=/etc/apache2/ssl
				elif [ "$OS" == "centos" ]; then
					SSL_DIR=/etc/httpd/ssl
				fi
			fi

			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				cyanMessage " "
				checkInstall openssl
			elif [ "$OS" == "centos" ]; then
				cyanMessage " "
				checkInstall openssl
				checkInstall mod_ssl
			fi

			makeDir $SSL_DIR

			cyanMessage " "
			okAndSleep "Creating a self-signed SSL certificate."
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/$FILE_NAME.key -out $SSL_DIR/$FILE_NAME.crt -subj "/C=/ST=/L=/O=/OU=/CN=$IP_DOMAIN"
		fi
	fi

	if [ "$WEBSERVER" == "Nginx" -o "$WEBSERVER" == "Lighttpd" ]; then
		makeDir /home/$MASTERUSER/fpm-pool.d/
		FILE_NAME_POOL=/home/$MASTERUSER/fpm-pool.d/$FILE_NAME.conf

		echo "[$IP_DOMAIN]" > $FILE_NAME_POOL
		echo "user = easywi_web" >> $FILE_NAME_POOL
		echo "group = $WEBGROUPNAME" >> $FILE_NAME_POOL
		echo "listen = ${PHP_SOCKET}" >> $FILE_NAME_POOL
		echo "listen.owner = easywi_web" >> $FILE_NAME_POOL
		echo "listen.group = $WEBGROUPNAME" >> $FILE_NAME_POOL
		echo "pm = dynamic" >> $FILE_NAME_POOL
		echo "pm.max_children = 1" >> $FILE_NAME_POOL
		echo "pm.start_servers = 1" >> $FILE_NAME_POOL
		echo "pm.min_spare_servers = 1" >> $FILE_NAME_POOL
		echo "pm.max_spare_servers = 1" >> $FILE_NAME_POOL
		echo "pm.max_requests = 500" >> $FILE_NAME_POOL
		echo "chdir = /" >> $FILE_NAME_POOL
		echo "access.log = /home/easywi_web/logs/fpm-access.log" >> $FILE_NAME_POOL
		echo "php_flag[display_errors] = off" >> $FILE_NAME_POOL
		echo "php_admin_flag[log_errors] = on" >> $FILE_NAME_POOL
		echo "php_admin_value[error_log] = /home/easywi_web/logs/fpm-error.log" >> $FILE_NAME_POOL
		echo "php_admin_value[memory_limit] = 32M" >> $FILE_NAME_POOL
		echo "php_admin_value[open_basedir] = /home/easywi_web/htdocs/:/home/easywi_web/tmp/" >> $FILE_NAME_POOL
		echo "php_admin_value[upload_tmp_dir] = /home/easywi_web/tmp" >> $FILE_NAME_POOL
		echo "php_admin_value[session.save_path] = /home/easywi_web/session" >> $FILE_NAME_POOL

		chown $MASTERUSER:$WEBGROUPNAME $FILE_NAME_POOL
	fi

	FILE_NAME_VHOST=/home/$MASTERUSER/sites-enabled/$FILE_NAME.conf

	if [ "$WEBSERVER" == "Nginx" ]; then
		echo 'server {' > $FILE_NAME_VHOST
		echo '    listen 80;' >> $FILE_NAME_VHOST

		if [ "$SSL" == "Yes" ]; then
			echo "    server_name $IP_DOMAIN;" >> $FILE_NAME_VHOST
			echo "    return 301 https://$IP_DOMAIN"'$request_uri;' >> $FILE_NAME_VHOST
			echo '}' >> $FILE_NAME_VHOST

			backUpFile /etc/nginx/nginx.conf

			if [ "`grep 'ssl_ecdh_curve secp384r1;' /etc/nginx/nginx.conf`" == "" ]; then
				sed -i '/ssl_prefer_server_ciphers on;/a \\tssl_ecdh_curve secp384r1;' /etc/nginx/nginx.conf
			fi
			if [ "`grep 'ssl_session_cache' /etc/nginx/nginx.conf`" == "" ]; then
				sed -i '/ssl_prefer_server_ciphers on;/a \\tssl_session_cache shared:SSL:10m;' /etc/nginx/nginx.conf
			fi
			if [ "`grep 'ssl_session_timeout' /etc/nginx/nginx.conf`" == "" ]; then
				sed -i '/ssl_prefer_server_ciphers on;/a \\tssl_session_timeout 10m;' /etc/nginx/nginx.conf
			fi
			if [ "`grep 'ssl_ciphers' /etc/nginx/nginx.conf`" == "" ]; then
				sed -i '/ssl_prefer_server_ciphers on;/a \\tssl_ciphers EECDH+AESGCM:EDH+AESGCM:EECDH:EDH:!MD5:!RC4:!LOW:!MEDIUM:!CAMELLIA:!ECDSA:!DES:!DSS:!3DES:!NULL;' /etc/nginx/nginx.conf
			fi

			if [ "$SSL_KEY" == "Lets Encrypt" ]; then
				echo 'server {' >> $FILE_NAME_VHOST
				echo '    listen 443 ssl;' >> $FILE_NAME_VHOST
				echo "    ssl_certificate /etc/letsencrypt/live/%domain%/fullchain.pem;" >> $FILE_NAME_VHOST
				echo "    ssl_certificate_key /etc/letsencrypt/live/%domain%/privkey.pem;" >> $FILE_NAME_VHOST
			else
				echo 'server {' >> $FILE_NAME_VHOST
				echo '    listen 443 ssl;' >> $FILE_NAME_VHOST
				echo "    ssl_certificate $SSL_DIR/$FILE_NAME.crt;" >> $FILE_NAME_VHOST
				echo "    ssl_certificate_key $SSL_DIR/$FILE_NAME.key;" >> $FILE_NAME_VHOST
			fi
		fi

		echo '    root /home/easywi_web/htdocs/;' >> $FILE_NAME_VHOST
		echo '    index index.html index.htm index.php;' >> $FILE_NAME_VHOST
		echo "    server_name $IP_DOMAIN;" >> $FILE_NAME_VHOST
		echo '    location ~ /(keys|stuff|template|languages|downloads|tmp) { deny all; }' >> $FILE_NAME_VHOST
		echo '    location / {' >> $FILE_NAME_VHOST
		echo '        try_files $uri $uri/ =404;' >> $FILE_NAME_VHOST
		echo '    }' >> $FILE_NAME_VHOST
		echo '    location ~ \.php$ {' >> $FILE_NAME_VHOST
		echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> $FILE_NAME_VHOST
		echo '        try_files $fastcgi_script_name =404;' >> $FILE_NAME_VHOST
		echo '        set $path_info $fastcgi_path_info;' >> $FILE_NAME_VHOST
		echo '        fastcgi_param PATH_INFO $path_info;' >> $FILE_NAME_VHOST
		echo '        fastcgi_index index.php;' >> $FILE_NAME_VHOST

		if [ -f /etc/nginx/fastcgi.conf ]; then
			echo '        include /etc/nginx/fastcgi.conf;' >> $FILE_NAME_VHOST
		elif [ -f /etc/nginx/fastcgi_params ]; then
			echo '        include /etc/nginx/fastcgi_params;' >> $FILE_NAME_VHOST
		fi

		echo "        fastcgi_pass unix:${PHP_SOCKET};" >> $FILE_NAME_VHOST
		echo '    }' >> $FILE_NAME_VHOST
		echo '}' >> $FILE_NAME_VHOST

		chown -cR $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER/ >/dev/null 2>&1
	elif [ "$WEBSERVER" == "Apache" ]; then
		FILE_NAME_VHOST="$FILE_NAME_VHOST.conf"

		echo '<VirtualHost *:80>' > $FILE_NAME_VHOST
		echo "    ServerName $IP_DOMAIN" >> $FILE_NAME_VHOST
		echo "    ServerAdmin info@$IP_DOMAIN" >> $FILE_NAME_VHOST

		if [ "$SSL" == "Yes" ]; then
			echo "    Redirect permanent / https://$IP_DOMAIN/" >> $FILE_NAME_VHOST
			echo '</VirtualHost>' >> $FILE_NAME_VHOST

			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				okAndSleep "Activating TLS/SSL related Apache modules."
				a2enmod ssl
			fi

			if [ "$SSL_KEY" == "Lets Encrypt" ]; then
				echo '<VirtualHost *:443>' >> $FILE_NAME_VHOST
				echo "    ServerName $IP_DOMAIN" >> $FILE_NAME_VHOST
				echo '    SSLEngine on' >> $FILE_NAME_VHOST
				echo "    SSLCertificateFile /etc/letsencrypt/live/$IP_DOMAIN/fullchain.pem" >> $FILE_NAME_VHOST
				echo "    SSLCertificateKeyFile /etc/letsencrypt/live/$IP_DOMAIN/privkey.pem" >> $FILE_NAME_VHOST
				echo '    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomain"' >> $FILE_NAME_VHOST
			else
				echo '<VirtualHost *:443>' >> $FILE_NAME_VHOST
				echo "    ServerName $IP_DOMAIN" >> $FILE_NAME_VHOST
				echo '    SSLEngine on' >> $FILE_NAME_VHOST
				echo "    SSLCertificateFile $SSL_DIR/$FILE_NAME.crt" >> $FILE_NAME_VHOST
				echo "    SSLCertificateKeyFile $SSL_DIR/$FILE_NAME.key" >> $FILE_NAME_VHOST
			fi
		fi

		echo '    DocumentRoot "/home/easywi_web/htdocs/"' >> $FILE_NAME_VHOST
		echo '    ErrorLog "/home/easywi_web/logs/error.log"' >> $FILE_NAME_VHOST
		echo '    CustomLog "/home/easywi_web/logs/access.log" common' >> $FILE_NAME_VHOST
		echo '    DirectoryIndex index.php index.html' >> $FILE_NAME_VHOST
		echo '    <IfModule mpm_itk_module>' >> $FILE_NAME_VHOST
		echo "       AssignUserId easywi_web $WEBGROUPNAME" >> $FILE_NAME_VHOST
		echo '       MaxClientsVHost 50' >> $FILE_NAME_VHOST
		echo '       NiceValue 10' >> $FILE_NAME_VHOST
		echo '       php_admin_flag allow_url_include off' >> $FILE_NAME_VHOST
		echo '       php_admin_flag display_errors off' >> $FILE_NAME_VHOST
		echo '       php_admin_flag log_errors on' >> $FILE_NAME_VHOST
		echo '       php_admin_flag mod_rewrite on' >> $FILE_NAME_VHOST
		echo '       php_admin_value open_basedir "/home/easywi_web/htdocs/:/home/easywi_web/tmp"' >> $FILE_NAME_VHOST
		echo '       php_admin_value session.save_path "/home/easywi_web/session"' >> $FILE_NAME_VHOST
		echo '       php_admin_value upload_tmp_dir "/home/easywi_web/tmp"' >> $FILE_NAME_VHOST
		echo '       php_admin_value upload_max_size 32M' >> $FILE_NAME_VHOST
		echo '       php_admin_value memory_limit 32M' >> $FILE_NAME_VHOST
		echo '    </IfModule>' >> $FILE_NAME_VHOST
		echo '    <Directory /home/easywi_web/htdocs/>' >> $FILE_NAME_VHOST
		echo '        Options -Indexes +FollowSymLinks +Includes' >> $FILE_NAME_VHOST
		echo '        AllowOverride None' >> $FILE_NAME_VHOST
		echo '        <IfVersion >= 2.4>' >> $FILE_NAME_VHOST
		echo '            Require all granted' >> $FILE_NAME_VHOST
		echo '        </IfVersion>' >> $FILE_NAME_VHOST
		echo '        <IfVersion < 2.4>' >> $FILE_NAME_VHOST
		echo '            Order allow,deny' >> $FILE_NAME_VHOST
		echo '            Allow from all' >> $FILE_NAME_VHOST
		echo '        </IfVersion>' >> $FILE_NAME_VHOST
		echo '    </Directory>' >> $FILE_NAME_VHOST
		echo '    <LocationMatch "/(keys|stuff|template|languages|downloads|tmp)">' >> $FILE_NAME_VHOST
		echo '        <IfVersion >= 2.4>' >> $FILE_NAME_VHOST
		echo '            Require all denied' >> $FILE_NAME_VHOST
		echo '        </IfVersion>' >> $FILE_NAME_VHOST
		echo '        <IfVersion < 2.4>' >> $FILE_NAME_VHOST
		echo '            Order deny,allow' >> $FILE_NAME_VHOST
		echo '            Deny  from all' >> $FILE_NAME_VHOST
		echo '        </IfVersion>' >> $FILE_NAME_VHOST
		echo '    </LocationMatch>' >> $FILE_NAME_VHOST
		echo '</VirtualHost>' >> $FILE_NAME_VHOST
	fi

  #Certbot - create Cerfiticate
	if [ "$SSL" == "Yes" -a "$SSL_KEY" == "Lets Encrypt" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ "$WEBSERVER" == "Nginx" ]; then
				okAndSleep "Stopping PHP-FPM and Nginx."
				service php${USE_PHP_VERSION}-fpm stop
				service nginx stop
			elif [ "$WEBSERVER" == "Apache" ]; then
				okAndSleep "Stopping PHP-FPM and Apache2."
				service php${USE_PHP_VERSION}-fpm stop
				service apache2 stop
			fi
			if [ "$OS" == "debian" -a "$OSBRANCH" == "wheezy" ]; then
				/root/certbot-auto certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
			else
				certbot certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
			fi
		elif [ "$OS" == "centos" ]; then
			if [ "$WEBSERVER" == " Ngingx" ]; then
				okAndSleep "Stopping PHP-FPM and Nginx."
				systemctl stop php-fpm.service
				systemctl stop nginx.service
			elif [ "$WEBSERVER" == "Apache" ]; then
				okAndSleep "Stopping PHP-FPM and Apache2."
				systemctl stop php-fpm.service
				systemctl stop httpd.service
			fi
			certbot certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
		fi
	fi

	RestartWebserver

	chown $MASTERUSER:$WEBGROUPNAME $FILE_NAME_VHOST

	if [ "`grep reboot.php /etc/crontab`" == "" ]; then
		echo '0 */1 * * * easywi_web cd /home/easywi_web/htdocs && timeout 300 php ./reboot.php >/dev/null 2>&1
*/5 * * * * easywi_web cd /home/easywi_web/htdocs && timeout 290 php ./statuscheck.php >/dev/null 2>&1
*/1 * * * * easywi_web cd /home/easywi_web/htdocs && timeout 290 php ./startupdates.php >/dev/null 2>&1
*/5 * * * * easywi_web cd /home/easywi_web/htdocs && timeout 290 php ./jobs.php >/dev/null 2>&1
*/10 * * * * easywi_web cd /home/easywi_web/htdocs && timeout 290 php ./cloud.php >/dev/null 2>&1' >> /etc/crontab
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		service cron restart 1>/dev/null
	elif [ "$OS" == "centos" ]; then
		systemctl restart crond.service 1>/dev/null
	fi
fi

if [ "$INSTALL" == "VS" ]; then
	ps -u $MASTERUSER | grep ts3server | awk '{print $1}' | while read PID; do
		kill $PID
	done

	if [ -f /home/$MASTERUSER/ts3server_startscript.sh ]; then
		rm -rf /home/$MASTERUSER/*
	fi

	makeDir /home/$MASTERUSER/
	chmod 750 /home/$MASTERUSER/
	chown -cR $MASTERUSER:$MASTERUSER /home/$MASTERUSER >/dev/null 2>&1

	cd /home/$MASTERUSER/

	cyanMessage " "
	okAndSleep "Downloading TS3 server files."
	su -c "curl $DOWNLOAD_URL -o teamspeak3-server.tar.bz2" $MASTERUSER

	if [ ! -f teamspeak3-server.tar.bz2 ]; then
		errorAndExit "Download failed! Exiting now!"
	fi

	okAndSleep "Extracting TS3 server files."
	su -c "tar -xf teamspeak3-server.tar.bz2 --strip-components=1" $MASTERUSER

	removeIfExists teamspeak3-server.tar.bz2

	QUERY_WHITLIST_TXT=/home/$MASTERUSER/query_ip_whitelist.txt
	if [ ! -f $QUERY_WHITLIST_TXT ]; then
		touch $QUERY_WHITLIST_TXT
		chown $MASTERUSER:$MASTERUSER $QUERY_WHITLIST_TXT
	fi

	if [ -f $QUERY_WHITLIST_TXT ]; then
		if [ "`grep '127.0.0.1' $QUERY_WHITLIST_TXT`" == "" ]; then
			echo "127.0.0.1" >> $QUERY_WHITLIST_TXT
		fi

		if [ "$LOCAL_IP" != "" ]; then
			if [ "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $LOCAL_IP`" != "" -a "`grep $LOCAL_IP $QUERY_WHITLIST_TXT`" == "" ]; then
				echo $LOCAL_IP >> $QUERY_WHITLIST_TXT
			fi
		fi

		cyanMessage " "
		cyanMessage "Please specify the IPv4 address of the Easy-WI web panel."
		read IP_ADDRESS

		if [ "$IP_ADDRESS" != "" ]; then
			if [ "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $IP_ADDRESS`" != "" -a "`grep $IP_ADDRESS $QUERY_WHITLIST_TXT`" == "" ]; then
				echo $IP_ADDRESS >> $QUERY_WHITLIST_TXT
			fi
		fi
	else
		redMessage "Cannot edit the file $QUERY_WHITLIST_TXT, please maintain it manually."
	fi

	QUERY_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c12`

	greenMessage " "
	greenMessage "Starting the TS3 server for the first time and shutting it down again as the password will be visible in the process tree."
	su -c "./ts3server_startscript.sh start serveradmin_password=$QUERY_PASSWORD createinifile=1 inifile=ts3server.ini" $MASTERUSER
	runSpinner 25
	su -c "./ts3server_startscript.sh stop" $MASTERUSER

	greenMessage " "
	greenMessage "Starting the TS3 server permanently."
	su -c "./ts3server_startscript.sh start inifile=ts3server.ini" $MASTERUSER
fi

cyanMessage " "
okAndSleep "Removing not needed packages."
if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
	$INSTALLER autoremove -y
elif [ "$OS" == "centos" ]; then
	$INSTALLER autoremove -y
fi

if [ "$INSTALL" == "EW" ]; then
	if [ "$SSL" == "Yes" ]; then
		PROTOCOL="https"
	else
		PROTOCOL="http"
	fi

	yellowMessage " "
	yellowMessage "Don't forget to change date.timezone (your Timezone) inside your php.ini."
	greenMessage " "
	greenMessage "Easy-WI Webpanel setup is done regarding architecture."
	greenOneLineMessage "Please open "; cyanOneLineMessage "$PROTOCOL://$IP_DOMAIN/install/install.php"; greenMessage " and complete the installation dialog."
	greenOneLineMessage "DB user and table name are "; cyanOneLineMessage "easy_wi"; greenOneLineMessage " and the password is "; cyanMessage "$DB_PASSWORD"
elif [ "$INSTALL" == "GS" ]; then
	greenOneLineMessage "Gameserver Root setup is done. Please enter the above data at the webpanel at "; cyanOneLineMessage "\"App/Game Master > Overview > Add\""; greenMessage "."
elif [ "$INSTALL" == "VS" ]; then
	greenOneLineMessage "Teamspeak 3 setup is done. TS3 Query password is "; cyanMessage "$QUERY_PASSWORD"
	greenOneLineMessage "Please enter this server at the webpanel at "; cyanOneLineMessage "\"Voiceserver > Master > Add\""; greenMessage "."
elif [ "$INSTALL" == "WR" ]; then
	if [ "$PHPINSTALL" == "Yes" ]; then
		yellowMessage " "
		yellowMessage "Don't forget to change date.timezone (your Timezone) inside your php.ini."
	fi
	greenMessage " "
	greenOneLineMessage "Webspace Root setup is done. Please enter the above data at the webpanel at "; cyanOneLineMessage "\"Webspace > Master > Add\""; greenMessage "."
	greenMessage " "
fi

if ([ "$INSTALL" == "MY" ] || [ "$INSTALL" == "WR" -a "$SQL" != "None" ]); then
	greenPneLineMessage "MySQL Root setup is done. Please enter the server at the webpanel at "; cyanOneLineMessage "\"MySQL > Master > Add\""; greenMessage "."
	cyanMessage " "
fi

if [ "$OS" == "centos" ]; then
	if [ ! "`grep 'SELINUX=' /etc/selinux/config | sed -n '2 p'`" == "SELINUX=disabled" ]; then
		backUpFile /etc/selinux/config
		sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
		systemctl disable firewalld
		systemctl stop firewalld

		redMessage " "
		redMessage " "
		redMessage "!! WARNING !!"
		redMessage "Firewall is disabled"
		redMessage " "
		redMessage "Please reboot your Root/Vserver to disable SELinux Security Function!"
		redMessage "Otherwise, the WebInterface can not work."
		redMessage " "
	fi
fi
cyanMessage " "

if [ "$DEBUG" = "ON" ]; then
	set +x
fi

exit 0
