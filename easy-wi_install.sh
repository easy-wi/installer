#!/bin/bash

# DEBUG MODE
DEBUG="OFF"

#    Author:     Ulrich Block <support@easy-wi.com>,
#                Alexander Doerwald <support@easy-wi.com>
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

if [ "$DEBUG" == "ON" ]; then
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
	exit 1
}

errorAndContinue() {
	redMessage "Invalid option."
}

removeIfExists() {
	if [ -n "$1" -a -f "$1" ]; then
		rm -f $1
	fi
}

runSpinner() {
	SPINNER=("-" "\\" "|" "/")

	for SEQUENCE in $(seq 1 $1); do
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
	if [ -n "$1" -a ! -d $1 ]; then
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
		if [ -z "`dpkg-query -s $1 2>/dev/null`" ]; then
			cyanMessage " "
			okAndSleep "Installing package $1"
			$INSTALLER -y install $1
		fi
	elif [ "$OS" == "centos" ]; then
		if [ -z "`rpm -qa $1`" ]; then
			cyanMessage " "
			okAndSleep "Installing package $1"
			$INSTALLER -y install $1
		fi
	fi

	if [ "$?" -ne 0 ]; then
		errorAndExit "\nPlease check Output!\nInstallation abort!\n"
	fi
}

checkUnInstall() {
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ -z "`dpkg-query -s $1 2>/dev/null`" ]; then
			cyanMessage " "
			okAndSleep "Uninstalling package $1"
			$INSTALLER -y remove $1
		fi
	elif [ "$OS" == "centos" ]; then
		if [ -z "`rpm -qa $1`" ]; then
			cyanMessage " "
			okAndSleep "Uninstalling package $1"
			$INSTALLER -y remove $1
		fi
	fi
}

importKey() {
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		apt-key adv --recv-keys --keyserver $1 $2
	elif [ "$OS" == "centos" ]; then
		rpm --import $1
	fi
}

checkUser() {
	if [ -z "$1" ]; then
		redMessage "Error: No masteruser specified"
	elif [ "$1" == "root" ]; then
		redMessage "Error: Using root as masteruser is a security hazard and not allowed."
	elif [ -n "`id $1 2> /dev/null`" ] && ([ "$INSTALL" != "EW" -a "$INSTALL" != "WR" ] || [ ! -d "/home/$1/sites-enabled" ]); then
		redMessage "Error: User \"$1\" already exists. Please name a not yet existing user"
	else
		echo 1
	fi
}

RestartWebserver() {
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ "$WEBSERVER" == "Apache" ]; then
			cyanMessage " "
			okAndSleep "Restarting Apache2."
			service apache2 restart 1>/dev/null
		elif [ "$WEBSERVER" == "Lighttpd" ]; then
			cyanMessage " "
			okAndSleep "Restarting Lighttpd."
			service lighttpd restart 1>/dev/null
		fi
	elif [ "$OS" == "centos" ]; then
		if [ "$WEBSERVER" == "Apache" ]; then
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
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ -f /etc/init.d/mysql ]; then
			/etc/init.d/mysql restart 1>/dev/null
		else
			systemctl restart mysql 1>/dev/null
		fi
	elif [ "$OS" == "centos" ]; then
		systemctl restart mariadb.service 1>/dev/null

		if [ "$?" -ne "0" ]; then
			systemctl restart mysql.service 1>/dev/null
		fi
	fi
}

doReboot() {
	if [ -n "$2" ]; then
		redMessage " "
		redMessage $2
	fi
	cyanMessage " "
	cyanMessage "Do you want to restart now?"
	OPTIONS=("Yes" "No" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2|3 ) break;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Yes" ]; then
		cyanMessage " "
		redMessage $1
		removeIfExists /tmp/easy-wi_reboot
		shutdown -r now
		errorAndQuit
	else
		touch /tmp/easy-wi_reboot
		clearPassword
		errorAndQuit
	fi
}

clearPassword() {
	# clear password variable
	unset MYSQL_ROOT_PASSWORD MYSQL_USER_PASSWORD DB_PASSWORD QUERY_PASSWORD WEBGROUPNAME2 FIREWALL MASTERUSER MYSQL_USER HTTPDSCRIPT
}

cyanMessage " "
yellowMessage "Please wait... Update is currently running."
cyanMessage " "
if [ -f /etc/debian_version ]; then
	INSTALLER="apt-get"
	OS="debian"
	$INSTALLER -y update
	if [ -z "`which wget`" ]; then
		checkInstall wget
	fi
	if [ -z "`which dialog`" ]; then
		checkInstall dialog
	fi
	if [ -z "`which logger`" ]; then
		apt-get --reinstall install bsdutils
	fi
	if [ -z "`which apt-utils`" ]; then
		checkInstall apt-utils
	fi
elif [ -f /etc/centos-release ]; then
	INSTALLER="yum"
	OS="centos"
	setenforce 0 >/dev/null 2>&1
	systemctl stop postfix
	systemctl disable postfix
	$INSTALLER clean all
	$INSTALLER -y update
	if [ -z "`rpm -qa wget`" ]; then
		checkInstall wget
	fi
	if [ -z "`rpm -qa which`" ]; then
		checkInstall which
	fi
fi

INSTALLER_VERSION="2.6"
PKILL=$(which pkill)
USERADD=$(which useradd)
USERMOD=$(which usermod)
USERDEL=$(which userdel)
GROUPADD=$(which groupadd)
MACHINE=$(uname -m)
HOST_NAME=`hostname -f | awk '{print tolower($0)}'`

if [ -n "$HOST_NAME" -a "$HOST_NAME" != "localhost" ]; then
	LOCAL_IP="$HOST_NAME"
elif [ -z "$HOST_NAME" -o "$HOST_NAME" == "0" -o "$HOST_NAME" == "localhost" ]; then
	LOCAL_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
fi

if [ -z "$LOCAL_IP" -o "$LOCAL_IP" == "0" -o "$LOCAL_IP" == "localhost" ]; then
	LOCAL_IP=`hostname -I | awk '{print $1}'`
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

if [ "$UPDATE_UPGRADE_SYSTEM" == "Yes" ]; then
	cyanMessage " "
	yellowMessage "Please wait... Update is currently running."
	cyanMessage " "
	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		cyanMessage " "
		$INSTALLER -y upgrade
		checkInstall debconf-utils
		checkInstall lsb-release
	elif [ "$OS" == "centos" ]; then
		cyanMessage " "
		cyanMessage "Update all obsolete packages."
		$INSTALLER -y update
		checkInstall redhat-lsb
		checkInstall epel-release
		importKey /etc/pki/rpm-gpg/RPM-GPG-KEY*
		checkInstall yum-utils
	fi
fi
checkInstall curl

yellowMessage ""
yellowMessage "Note: locales added en_US.UTF-8 if needed!"
yellowMessage ""
if [ "$OS" == "centos" ]; then
	if [ "`cat /etc/locale.conf | grep LANG=`" != "LANG=en_US.UTF-8" -a -n "`localectl list-locales | grep en_US.UTF-8`" ]; then
		localectl set-locale LANG=en_US.UTF-8
	elif [ "`cat /etc/locale.conf | grep LANG=`" != "LANG=en_US.utf8" -a -n "`localectl list-locales | grep en_US.utf8`" ]; then
		localectl set-locale LANG=en_US.utf8
	fi
else
	checkInstall locales
	if [ "`grep en_US.UTF-8 /etc/locale.gen`" != "en_US.UTF-8 UTF-8" ]; then
		sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
		dpkg-reconfigure --frontend noninteractive locales
	fi
fi

#CentOS - SELinux
if [ "$OS" == "centos" ]; then
	if [ ! -f /tmp/easy-wi_reboot ]; then
		if ([ ! -d /home/easywi_web -a -z "`find /home -type d -name 'masterserver'`" -a -z "`find /home -type f -name 'ts3server'`" ]); then
			yellowMessage ""
			yellowMessage "Note: Please update your fresh operating system and restart it!"
			yellowMessage ""
		fi
		if [ -f /etc/selinux/config ]; then
			if [ "`grep 'SELINUX=' /etc/selinux/config | sed -n '2 p'`" != "SELINUX=disabled" ]; then
				backUpFile /etc/selinux/config
				sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
				redMessage " "
				redMessage "Please reboot your Root/Vserver to disabled SELinux Security Function!"
				redMessage "Otherwise, the WebInterface can not work."
				redMessage " "
				doReboot "System is rebooting now for finish SELinux Security Function!"
			fi
		fi
	else
		doReboot "System is rebooting now for finish SELinux Security Function!" "Please reboot your Root/Vserver to disabled SELinux Security Function"
	fi
fi

cyanMessage " "
OS=$(lsb_release -i 2> /dev/null | grep 'Distributor' | awk '{print tolower($3)}')
OSVERSION_TMP=$(lsb_release -r 2> /dev/null | grep 'Release' | awk '{print $2}')
OSBRANCH=$(lsb_release -c 2> /dev/null | grep 'Codename' | awk '{print $2}')

if [ "$MACHINE" == "x86_64" ]; then
	ARCH="amd64"
elif [ "$MACHINE" == "i386" ]||[ "$MACHINE" == "i686" ]; then
	ARCH="x86"
fi

if [ -z "$OS" ]; then
	errorAndExit "Error: Could not detect OS. Currently only Debian, Ubuntu and CentOS are supported. Aborting!"
else
	okAndSleep "Detected OS: $OS"
fi

if [ -z "$OSBRANCH" ]; then
	errorAndExit "Error: Could not detect branch of OS. Aborting"
else
	okAndSleep "Detected branch: $OSBRANCH"
fi

if [ -z "$OSVERSION_TMP" ]; then
	errorAndExit "Error: Could not detect version of OS. Aborting"
else
	okAndSleep "Detected version: $OSVERSION_TMP"

	if [ "$OS" == "ubuntu" ]; then
		OSVERSION=$(echo "$OSVERSION_TMP" | tr -d .)
	elif [ "$OS" == "centos" ]; then
		OSVERSION=$(echo "$OSVERSION_TMP" | tr -d . | cut -c 1-2)
	elif [ "$OS" == "debian" ]; then
		if [ "$OSVERSION_TMP" == "10" ]; then
			OSVERSION=$(echo "$OSVERSION_TMP"0)
		else
			OSVERSION=$(echo "$OSVERSION_TMP" | tr -d . | cut -c 1-2)
		fi
	fi
fi

if [ -z "$ARCH" ]; then
	errorAndExit "Error: $MACHINE is not supported! Aborting"
else
	okAndSleep "Detected architecture: $ARCH"
fi

if [ "$OS" == "ubuntu" -a "$OSVERSION" -lt "1604" -o "$OS" == "debian" -a "$OSVERSION" -lt "80" -o "$OS" == "centos" -a "$OSVERSION" -lt "60" ]; then
	echo; echo
	redMessage "Error: Your OS \"$OS - $OSVERSION_TMP\" is not more supported from Easy-WI Installer."
	redMessage "Please Upgrade to a newer OS Version!"
	redMessage " "

	if [ "$OS" == "centos" ]; then
		redMessage "Reinstall CentOS to Version 7 or newer!"
		redMessage "A Upgrade from your OS is not available."
		redMessage " "
		errorAndQuit
	fi

	if [ "$OS" == "ubuntu" ]; then
		OSBRANCH_NEW="xenial (Ubuntu 16.04 LTS)"
	else
		OSBRANCH_NEW="jessie (Debian 8)"
	fi

	cyanMessage "Upgrade to $OS $OSBRANCH_NEW?"
	OPTIONS=("Yes" "No" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
			*) errorAndContinue;;
		esac
	done

	if [ "$OPTION" == "Yes" ]; then
		if [ "$OS" == "ubuntu" ]; then
			checkInstall update-manager-core
			do-release-upgrade
		elif [ "$OS" == "debian" ]; then
			sed -i "s/$OSBRANCH/jessie/g" /etc/apt/sources.list
			$INSTALLER -y update
			$INSTALLER -y upgrade
			$INSTALLER -y dist-upgrade -u
			$INSTALLER -y autoremove
		fi
		doReboot "System is rebooting now for finish Upgrade!"
	else
		if [ "$OS" == "ubuntu" ]; then
			redMessage "Command: do-release-upgrade"
			redMessage " "
			errorAndQuit
		elif [ "$OS" == "debian" ]; then
			redMessage "Command: apt-get update; apt-get upgrade; apt-get dist-upgrade; apt-get autoremove"
			redMessage " "
			errorAndQuit
		fi
	fi
fi

yellowMessage " "
yellowOneLineMessage "If you want to install everything on this system, then please install the "; cyanOneLineMessage "Easy-WI Webpanel "; yellowMessage "first!"
cyanMessage " "
cyanMessage "What shall be installed/prepared?"

OPTIONS=("Easy-WI Webpanel" "Gameserver Root" "Voicemaster" "Webspace Root" "MySQL" "Quit")
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

if [ -n "$OTHER_PANEL" ]; then
	if [ "$INSTALL" == "GS" ]; then
		yellowMessage " "
		yellowMessage "Warning an installation of the control panel $OTHER_PANEL has been detected."
		yellowMessage "If you continue the installer might end up breaking $OTHER_PANEL or same parts of Easy-WI might not work."
		OPTIONS=("Continue" "Quit")
		select OTHER_PANEL_CONTINUE in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1 ) break;;
				2 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		if [ "$OTHER_PANEL_CONTINUE" == "Continue" ]; then
			redMessage " "
			redMessage "At your own risk!"
			redMessage "Easy-WI does not support anyone in using other panels."
		fi
	else
		redMessage " "
		errorAndExit "Aborting as the risk of breaking the installed panel $OTHER_PANEL is too high."
	fi
fi

# Run the domain/IP check up front to avoid late error out.
if [ "$INSTALL" == "EW" ]; then
	cyanMessage " "
	cyanMessage "At which URL/Domain should Easy-Wi be placed?"
	OPTIONS=("$LOCAL_IP" "Other" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
		case "$REPLY" in
			1|2 ) break;;
			3 ) errorAndQuit;;
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

	if [ -z "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $IP_DOMAIN`" -a -z "`grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$' <<< $IP_DOMAIN`" ]; then
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

if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" ]; then
	if [ "$OS" == "ubuntu" -o "$OS" == "debian" ]; then
		checkInstall cron
	elif [ "$OS" == "centos" ]; then
		checkInstall crontabs
	fi

	if [ "$OS" == "debian" -a "$OSVERSION" -lt "100" ]; then
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
			if [ -z "`grep 'packages.dotdeb.org' /etc/apt/sources.list`" ]; then
				cyanMessage " "
				okAndSleep "Adding entries to /etc/apt/sources.list"

				if [ "$OSBRANCH" == "jessie" -o "$OSBRANCH" == "stretch" ]; then
					checkInstall software-properties-common
				fi

				add-apt-repository "deb http://packages.dotdeb.org $OSBRANCH all"
				curl --remote-name https://www.dotdeb.org/dotdeb.gpg
				apt-key add dotdeb.gpg
				removeIfExists dotdeb.gpg
				$INSTALLER -y update
			fi
		fi
	fi

	if [ "$INSTALL" == "EW" ]; then
		WEBSERVER="Apache"
	elif [ "$INSTALL" == "WR" ]; then
		if [ ! -d /home/easywi_web/htdocs/ ]; then
			cyanMessage " "
			cyanMessage "Please select the webserver you would like to use"
			cyanMessage "Lighttpd is recommended for FastDL"
			cyanMessage "Apache is recommended in case you want to run many PHP supporting Vhosts aka mass web hosting"

			OPTIONS=("Apache" "Lighttpd" "None" "Quit")
			select WEBSERVER in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2|3 ) break;;
					4 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done
		else
			WEBSERVER="None"
		fi
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
		if [ "$WEBSERVER" == "Lighttpd" ]; then
			WEBGROUPNAME="lighttpd"
			WEBGROUPTMPID="993"
			WEBGROUPPATH="/var/www/lighttpd"
			WEBGROUPCOMMENT="lighttpd web server"
		elif [ "$WEBSERVER" == "Apache" ]; then
			WEBGROUPNAME="apache"
			WEBGROUPTMPID="48"
			WEBGROUPPATH="/usr/share/httpd"
			WEBGROUPCOMMENT="Apache"
		elif [ "$WEBSERVER" == "None" ]; then
			if [ -f /etc/lighttpd/lighttpd.conf ]; then
				WEBGROUPNAME="lighttpd"
				WEBGROUPTMPID="993"
				WEBGROUPPATH="/var/www/lighttpd"
				WEBGROUPCOMMENT="lighttpd web server"
			elif [ -f /etc/httpd/conf/httpd.conf ]; then
				WEBGROUPNAME="apache"
				WEBGROUPTMPID="48"
				WEBGROUPPATH="/usr/share/httpd"
				WEBGROUPCOMMENT="Apache"
				if [ "$OS" == "centos" -a "$INSTALL" == "WR" ]; then
					WEBSERVER="Apache"
				fi
			else
				errorAndExit "No Webserver Installation found. Aborting!"
			fi
		fi
	fi

	WEBGROUPID=`getent group $WEBGROUPNAME | awk -F ':' '{print $3}'`
	if [ "$WEBGROUPID" != "$WEBGROUPTMPID" ]; then
		$GROUPADD -g $WEBGROUPTMPID $WEBGROUPNAME >/dev/null 2>&1
		if [ "$WEBSERVER" == "Lighttpd" ]; then
			$USERADD -c "$WEBGROUPCOMMENT" -u $WEBGROUPTMPID -g $WEBGROUPTMPID -s /sbin/nologin -r -d $WEBGROUPPATH $WEBGROUPNAME
		fi
		WEBGROUPID=`getent group $WEBGROUPNAME | awk -F ':' '{print $3}'`
	fi

	if [ "$INSTALL" == "EW" -o -d /home/easywi_web/htdocs/ ]; then
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
		if [ -z "$WEBGROUPID" ]; then
			$GROUPADD $WEBGROUP
			WEBGROUPID=`getent group $WEBGROUP | awk -F ':' '{print $3}'`
		fi
	fi

	if [ -z "$WEBGROUPID" ]; then
		errorAndExit "Fatal Error: missing webservergroup ID"
	elif [ "$WEBGROUPID" != "$WEBGROUPTMPID" ]; then
		errorAndExit "Fatal Error: wrong webservergroup ID"
	fi
fi

# Run the TS3 server version detect up front to avoid user executing steps first and fail at download last.
if [ "$INSTALL" == "VS" ]; then
	cyanMessage " "
	okAndSleep "Searching latest build for hardware type $MACHINE with arch $ARCH."

	for VERSION in `curl -s "https://files.teamspeak-services.com/releases/server/?C=M;O=D" | grep -Po '(?<=href=")[0-9]+(\.[0-9]+){2,3}(?=")' | sort -Vr`; do
		DOWNLOAD_URL_VERSION="https://files.teamspeak-services.com/releases/server/$VERSION/teamspeak3-server_linux_$ARCH-$VERSION.tar.bz2"
		STATUS=`curl -I $DOWNLOAD_URL_VERSION 2>&1 | grep "HTTP/" | awk '{print $2}'`

		if [ "$STATUS" == "200" ]; then
			DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
			break
		fi
	done

	if [ "$STATUS" == "200" -a -n "$DOWNLOAD_URL" ]; then
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

	if [ -n "`id $1 2> /dev/null`" ]; then
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

		makeDir /home/$MASTERUSER/.ssh
		chown $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER/.ssh >/dev/null 2>&1
		cd /home/$MASTERUSER/.ssh

		cyanMessage " "
		cyanMessage "It is recommended but not required to set a password"
		su -c "ssh-keygen -t rsa" $MASTERUSER

		KEYNAME=`find -maxdepth 1 -name "*.pub" | head -n 1`

		if [ -n "$KEYNAME" ]; then
			su -c "cat $KEYNAME >> authorized_keys" $MASTERUSER
			if [ "$INSTALL" != "EW" -o "$INSTALL" != "MY" ]; then
				if [ -d /home/easywi_web/htdocs/keys/ ]; then
					cp /home/$MASTERUSER/.ssh/id_rsa.pub /home/easywi_web/htdocs/keys/$MASTERUSER.pub
					cp /home/$MASTERUSER/.ssh/id_rsa /home/easywi_web/htdocs/keys/$MASTERUSER
					WEBGROUPNAME2=`ls -ls /home/easywi_web/htdocs/keys/ | grep "easywi_web" | awk '{print $5}' | head -n1`
					chown -cR easywi_web:$WEBGROUPNAME2 /home/easywi_web/htdocs/keys/ 2>&1 >/dev/null
				fi
			fi
		else
			redMessage "Error: could not find a key. You might need to create one manually at a later point."
		fi
	elif [ "$OPTION" == "Set password" ]; then
		cyanMessage " "
		cyanMessage "Please provide the user password for $MASTERUSER."
		passwd $MASTERUSER
	fi
fi

if [ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ]; then
	makeDir /home/$MASTERUSER/sites-enabled/
  makeDir /home/$MASTERUSER/skel
	makeDir /home/$MASTERUSER/skel/htdocs
	makeDir /home/$MASTERUSER/skel/logs
	makeDir /home/$MASTERUSER/skel/sessions
	makeDir /home/$MASTERUSER/skel/tmp
	chown -cR $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER >/dev/null 2>&1

	cyanMessage " "
	if [ "$WEBSERVER" == "Lighttpd" ]; then
		checkInstall lighttpd
		if [ "$OS" == "centos" ]; then
			systemctl enable lighttpd.service >/dev/null 2>&1
		fi
	elif [ "$WEBSERVER" == "Apache" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall apache2
		elif [ "$OS" == "centos" ]; then
			checkInstall httpd
			systemctl enable httpd.service >/dev/null 2>&1
		fi
	fi
fi

if [ "$INSTALL" == "EW" -o "$INSTALL" == "MY" ]; then
	if [ "$INSTALL" == "EW" ]; then
		cyanMessage " "
		okAndSleep "Please note that Easy-Wi requires a MySQL or MariaDB installed and will install MySQL if no DB is installed"
	fi

	if [ "$OS" == "debian" -a "$OSVERSION" -lt "100" -o "$OS" == "ubuntu" ]; then
		if [ -z "`ps fax | grep 'mysqld' | grep -v 'grep'`" ]; then
			cyanMessage " "
			cyanMessage "Please select if an which database server to install."

			OPTIONS=("MySQL" "MariaDB" "None" "Quit")
			select SQL in "${OPTIONS[@]}"; do
				case "$REPLY" in
					1|2|3 ) break;;
					4 ) errorAndQuit;;
					*) errorAndContinue;;
				esac
			done
		fi
	elif [ "$OS" == "centos" ]; then
		if [ -z "`ps fax | grep 'mysqld' | grep -v 'grep'`" ]; then
			SQL="MariaDB"
			SQL_VERSION="10"
		fi
	else
		SQL="MariaDB"
	fi

	if [ -n "`ps fax | grep 'mysqld' | grep -v 'grep'`" ]; then
		if [ -f /root/database_root_login.txt ]; then
			MYSQL_ROOT_PASSWORD=$(grep "Password:" /root/database_root_login.txt | awk '{print $2}')
		else
			cyanMessage " "
			cyanOneLineMessage "Please provide the "; greenOneLineMessage "root "; cyanMessage "password for the MySQL Database."
			read MYSQL_ROOT_PASSWORD
		fi

		mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
		ERROR_CODE=$?

		until [ $ERROR_CODE == 0 ]; do
			cyanOneLineMessage "Password incorrect, please provide the "; greenOneLineMessage "root "; cyanMessage "password for the MySQL Database."
			read MYSQL_ROOT_PASSWORD

			mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
			ERROR_CODE=$?
		done
	else
		MYSQL_ROOT_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c18`
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		export DEBIAN_FRONTEND="noninteractive"
		echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
		echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
	fi

	if [ "$SQL" == "MariaDB" ]; then
		MARIADB_VERSION="10.4"
		RUNUPDATE="0"
		if ([ "$OS" == "debian" -o "$OS" == "ubuntu" ] && [ -z "`grep '/mariadb/' /etc/apt/sources.list`" ]); then
			checkInstall software-properties-common

			if [ "$OS" == "debian" -a "$OSVERSION" -ge "90" ]; then
				checkInstall dirmngr
			fi

			if [ "$OS" == "debian" -a "$OSVERSION" -ge "90" ]; then
				importKey keyserver.ubuntu.com 0xF1656F24C74CD1D8
			elif [ "$OS" == "debian" -a "$OSVERSION" -lt "90" ]; then
				importKey keyserver.ubuntu.com 0xcbcb082a1bb943db
			elif [ "$OS" == "ubuntu" -a "$OSVERSION" -ge "1410" ]; then
				importKey hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
			elif [ "$OS" == "ubuntu" -a "$OSVERSION" -lt "1410" ]; then
				importKey hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
			fi

			if [ -n "apt-cache search mariadb-server-$MARIADB_VERSION" ]; then
				add-apt-repository "deb http://mirror.23media.de/mariadb/repo/$MARIADB_VERSION/$OS $OSBRANCH main"
				RUNUPDATE=1
			fi

			if [ "$OS" == "debian" -a "$DOTDEB" == "Yes" ]; then
				echo "Package: *" > /etc/apt/preferences.d/mariadb.pref
				echo "Pin: origin mirror.23media.de" >> /etc/apt/preferences.d/mariadb.pref
				echo "Pin-Priority: 1000" >> /etc/apt/preferences.d/mariadb.pref
				RUNUPDATE=1
			fi
		elif ([ "$OS" == "centos" -a "$SQL_VERSION" == "10" ] && [ ! -f /etc/yum.repos.d/MariaDB.repo ]); then
			MARIADB_TMP_VERSION="`echo $OSVERSION | cut -c 1`"
			MARIADB_FILE=$(ls /etc/yum.repos.d/)
			for search_mariadb in "${MARIADB_FILE[@]}"; do
				if [ -z "`grep '/MariaDB/' $search_mariadb >/dev/null 2>&1`" -a ! -f /etc/yum.repos.d/MariaDB.repo ]; then
					echo "# MariaDB $MARIADB_VERSION CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/"$MARIADB_VERSION"/centos"$MARIADB_TMP_VERSION"-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/MariaDB.repo
				fi
			done
			importKey https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
			RUNUPDATE=1
		fi

		if [ "$RUNUPDATE" == "1" ]; then
			yellowMessage " "
			yellowMessage "Please wait... Update is currently running."
			yellowMessage " "
			$INSTALLER -y update
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
			if ([ "`printf "${OSVERSION}\n80" | sort -V | tail -n 1`" == "80" -o "$OS" == "ubuntu" ] && [ -z "`grep '/mariadb/' /etc/apt/sources.list`" ]); then
				checkInstall mysql-common
			else
				checkInstall mariadb-common
			fi
		elif [ "$OS" == "centos" -a "$OSVERSION" -lt "80" ]; then
			checkInstall mariadb-server
			systemctl enable mariadb.service >/dev/null 2>&1
		elif [ "$OS" == "centos" -a "$OSVERSION" -ge "80" ]; then
			dnf install -y boost-program-options
			dnf install -y MariaDB-server MariaDB-client --disablerepo=AppStream
		fi
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" -a -f /etc/mysql/my.cnf ]; then
		if [ ! -f /etc/mysql/my.cnf.easy-install.backup ]; then
			backUpFile /etc/mysql/my.cnf
		fi
	elif [ "$OS" == "centos" -a -f /etc/my.cnf ]; then
		if [ ! -f /etc/my.cnf.easy-install.backup ]; then
			backUpFile /etc/my.cnf
			if [ -f /usr/share/mysql/my-medium.cnf ]; then
				cp /usr/share/mysql/my-medium.cnf -R /etc/my.cnf
			fi
		fi
	else
		errorAndExit "$SQL Database not fully installed!"
	fi
	RestartDatabase

	cyanMessage " "
	okAndSleep "Securing MySQL by running \"mysql_secure_installation\" commands."
	if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
		if [ "$OS" == "centos" -a "$INSTALL" == "EW" ]; then
			mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
			mysqladmin shutdown -p"$MYSQL_ROOT_PASSWORD"
			RestartDatabase
		fi

		mysql --user=root --password="$MYSQL_ROOT_PASSWORD" <<_EOF_
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
	else
		cyanMessage " "
		errorAndExit "Error: Password for MySQL Server not found!"
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		MYSQL_CONF="/etc/mysql/my.cnf"
	elif [ "$OS" == "centos" ]; then
		MYSQL_CONF="/etc/my.cnf"
	fi

	if [ "$INSTALL" == "MY" ]; then
		cyanMessage " "
		cyanMessage "Allow access to the Database from outside?"

		OPTIONS=("Yes" "No" "Quit")
		select EXTERNAL_INSTALL in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done
	elif [ "$INSTALL" == "EW" ]; then
		EXTERNAL_INSTALL="No"
	fi

	if [ "$EXTERNAL_INSTALL" == "Yes" ]; then
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT USAGE ON *.* TO 'root'@'' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" 2> /dev/null
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "UPDATE mysql.user SET Select_priv='Y',Insert_priv='Y',Update_priv='Y',Delete_priv='Y',Create_priv='Y',Drop_priv='Y',Reload_priv='Y',Shutdown_priv='Y',Process_priv='Y',File_priv='Y',Grant_priv='Y',References_priv='Y',Index_priv='Y',Alter_priv='Y',Show_db_priv='Y',Super_priv='Y',Create_tmp_table_priv='Y',Lock_tables_priv='Y',Execute_priv='Y',Repl_slave_priv='Y',Repl_client_priv='Y',Create_view_priv='Y',Show_view_priv='Y',Create_routine_priv='Y',Alter_routine_priv='Y',Create_user_priv='Y',Event_priv='Y',Trigger_priv='Y',Create_tablespace_priv='Y' WHERE User='root' AND Host='';" 2> /dev/null

		if [ -z "$LOCAL_IP" ]; then
			cyanMessage " "
			cyanMessage "Could not detect local IP. Please specify which to use."
			read LOCAL_IP
		fi

		if [ -n "$LOCAL_IP" -a -f "$MYSQL_CONF" ]; then
			if [ "`grep 'bind-address' $MYSQL_CONF | awk '{print $3}'`" != "0.0.0.0" ]; then
				sed -i "s/bind-address.*/bind-address = 0.0.0.0/g" $MYSQL_CONF
			elif [ -z "`grep 'bind-address' $MYSQL_CONF`" ]; then
				sed -i "/\[mysqld\]/abind-address = 0.0.0.0" $MYSQL_CONF
			fi
		fi
	elif [ "$EXTERNAL_INSTALL" == "No" ]; then
		if [ -z "`grep 'bind-address' $MYSQL_CONF`" ]; then
			sed -i "/\[mysqld\]/abind-address = 127.0.0.1" $MYSQL_CONF
		elif [ -z "`grep 'bind-address = 0.0.0.0' $MYSQL_CONF`" -a ! "$MYSQL_CONF".easy-install.backup ]; then
			sed -i "s/bind-address.*/bind-address = 127.0.0.1/g" $MYSQL_CONF
		fi
	fi

	MYSQL_VERSION=`mysql -V | awk {'print $5'} | tr -d ,`

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ -n "`grep -E 'key_buffer[[:space:]]*=' /etc/mysql/my.cnf`" -a "printf "${MYSQL_VERSION}\n5.5" | sort -V | tail -n 1" != "5.5" ]; then
			sed -i -e "51s/key_buffer[[:space:]]*=/key_buffer_size = /g" $MYSQL_CONF
			sed -i -e "57s/myisam-recover[[:space:]]*=/myisam-recover-options = /g" $MYSQL_CONF
		fi
		if [ "$OS" == "ubuntu" -a "$OSVERSION" -ge "1603" -a ! -f /etc/mysql/conf.d/disable_strict_mode.cnf ]; then
			echo '[mysqld]' > /etc/mysql/conf.d/disable_strict_mode.cnf
			echo 'sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' >> /etc/mysql/conf.d/disable_strict_mode.cnf
		fi
	fi

	RestartDatabase

	if [ -z "`ps ax | grep mysql | grep -v grep`" ]; then
		cyanMessage " "
		errorAndExit "Error: No SQL server running but required for Webpanel installation."
	fi
fi

if [ "$INSTALL" == "EW" ]; then
	cyanMessage " "
	okAndSleep "Please note that Easy-Wi will install required PHP packages."
	PHPINSTALL="Yes"
elif [ "$INSTALL" == "WR" ]; then
	if [ -z "`rpm -qa php 2>/dev/null`" -a -z "`dpkg -l 2>/dev/null | egrep -o "php-common"`" ]; then
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
else
	PHPINSTALL="None"
fi

if [ "$PHPINSTALL" == "Yes" ]; then
	if [ "$OS" == "debian" -a "$OSVERSION" -ge "100" ]; then
		USE_PHP_VERSION='7.3'
	elif [ "$OS" == "debian" -a "$OSVERSION" -ge "85" -o "$OS" == "ubuntu" -a "$OSVERSION" -lt "1610" ]; then
		USE_PHP_VERSION='7.0'
	elif [ "$OS" == "ubuntu" -a "$OSVERSION" -ge "1610" -a "$OSVERSION" -lt "1803" ]; then
		USE_PHP_VERSION='7.1'
	elif [ "$OS" == "ubuntu" -a "$OSVERSION" -ge "1803" ]; then
		USE_PHP_VERSION='7.2'
	elif [ "$OS" == "centos" -a "$OSVERSION" -lt "80" ]; then
		checkInstall http://rpms.remirepo.net/enterprise/remi-release-7.rpm
		yum-config-manager --enable remi-php71
		RUNUPDATE="1"
	elif [ "$OS" == "centos" -a "$OSVERSION" -ge "80" ]; then
		checkInstall http://rpms.remirepo.net/enterprise/remi-release-8.rpm
		yum-config-manager --enable remi-php72
		RUNUPDATE="1"
	else
		USE_PHP_VERSION='5'
	fi

	if [ "$RUNUPDATE" == "1" ]; then
		yellowMessage " "
		yellowMessage "Please wait... Update is currently running."
		yellowMessage " "
		$INSTALLER -y update
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		if [ "$WEBSERVER" == "Apache" ]; then
			checkInstall php${USE_PHP_VERSION}
		fi
		checkInstall php${USE_PHP_VERSION}-common
		checkInstall php${USE_PHP_VERSION}-curl
		checkInstall php${USE_PHP_VERSION}-gd
		if [ "$OS" == "ubuntu" -a "$OSVERSION" -lt "1803" -o "$OS" == "debian" -a "$OSVERSION" -lt "100" ]; then
			checkInstall php${USE_PHP_VERSION}-mcrypt
		elif [ "$OS" == "ubuntu" -a "$OSVERSION" -ge "1804" ]; then
			checkInstall libsodium-dev
		fi
		checkInstall php${USE_PHP_VERSION}-mysql
		checkInstall php${USE_PHP_VERSION}-cli
		if [ "$OS" == "debian" -a "$OSVERSION" -ge "85" -o "$OS" == "ubuntu" ]; then
			checkInstall php${USE_PHP_VERSION}-xml
			checkInstall php${USE_PHP_VERSION}-mbstring
			checkInstall php${USE_PHP_VERSION}-zip
		fi
	elif [ "$OS" == "centos" ]; then
		checkInstall php
		checkInstall php-common
		checkInstall php-gd
		checkInstall libsodium-devel
		checkInstall php-mysqlnd
		checkInstall php-cli
		checkInstall php-xml
		checkInstall php-mbstring
		checkInstall php-zip
	fi

	if [ "$WEBSERVER" == "Lighttpd" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall php${USE_PHP_VERSION}-fpm
			lighttpd-enable-mod fastcgi
			lighttpd-enable-mod fastcgi-php
		elif [ "$OS" == "centos" ]; then
			checkInstall php-fpm
			systemctl enable php-fpm.service >/dev/null 2>&1

			backUpFile /etc/php.ini
			backUpFile /etc/php-fpm.conf
			backUpFile /etc/php-fpm.d/www.conf

			sed -i "s/user = apache/user = lighttpd/g" /etc/php-fpm.d/www.conf
			sed -i "s/group = apache/group = lighttpd/g" /etc/php-fpm.d/www.conf
		fi
	elif [ "$WEBSERVER" == "Apache" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			checkInstall libapache2-mpm-itk
			checkInstall libapache2-mod-php${USE_PHP_VERSION}
			a2enmod php${USE_PHP_VERSION}
		elif [ "$OS" == "centos" ]; then
			checkInstall httpd-itk
			backUpFile /etc/httpd/conf.modules.d/00-mpm-itk.conf
			sed -i "s/#LoadModule mpm_itk_module modules\/mod_mpm_itk.so/LoadModule mpm_itk_module modules\/mod_mpm_itk.so/g" /etc/httpd/conf.modules.d/00-mpm-itk.conf
		fi
	fi

	if [ -f /etc/php/"${USE_PHP_VERSION}"/fpm/php-fpm.conf ]; then
		makeDir /home/$MASTERUSER/fpm-pool.d/

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			sed -i "s/include=\/etc\/php\/${USE_PHP_VERSION}\/fpm\/pool.d\/\*.conf/include=\/home\/$MASTERUSER\/fpm-pool.d\/\*.conf/g" /etc/php/"${USE_PHP_VERSION}"/fpm/php-fpm.conf
		fi
	fi

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ] && [ -f /etc/php/${USE_PHP_VERSION}/fpm/php-fpm.conf ]; then
		#In case of php 7 the socket is different
		PHP_SOCKET="/var/run/php/php${USE_PHP_VERSION}-fpm.sock"
	elif [ "$OS" == "centos" -a -f /etc/php-fpm.conf ]; then
		#In case of centos the socket is different
		PHP_SOCKET="/var/run/php-fpm/php-fpm.sock"
	fi

	RestartWebserver
fi

if ([ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ] && [ -z "`grep '/bin/false' /etc/shells`" ]); then
	echo "/bin/false" >> /etc/shells
fi

if [ "$INSTALL" == "GS" -o "$INSTALL" == "WR" ]; then
	if [ -z "`rpm -qa proftpd 2>/dev/null`" -a -z "`dpkg -l 2>/dev/null | egrep -o "proftpd"`" ]; then
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
	else
		OPTION="No"
	fi

	if [ "$OPTION" == "Yes" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
		elif [ "$OS" == "centos" ]; then
			$INSTALLER -y -q update
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
			makeDir /etc/proftpd
			if [ ! -f /etc/proftpd/proftpd.conf ];then
				mv /etc/proftpd.conf /etc/proftpd/
				cd /etc
				ln -s /etc/proftpd/proftpd.conf proftpd.conf
			fi
			backUpFile /etc/proftpd/proftpd.conf
			if [ -z "`grep 'Include' /etc/proftpd/proftpd.conf`" ]; then
				echo "Include /etc/proftpd/conf.d/" >> /etc/proftpd/proftpd.conf
				makeDir /etc/proftpd/conf.d
			fi
		fi

		if [ -f /etc/proftpd/proftpd.conf -a "$INSTALL" != "GS" ]; then
			sed -i 's/Umask.*/Umask 037 027/g' /etc/proftpd/proftpd.conf
		elif [ -f /etc/proftpd/proftpd.conf -a "$INSTALL" == "GS" ]; then
			sed -i 's/Umask.*/Umask 077 077/g' /etc/proftpd/proftpd.conf
		fi

		cyanMessage " "
		cyanMessage "Install/Update Easy-WI ProFTPD Rules?"

		OPTIONS=("Yes" "No" "Quit")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		if [ "$OPTION" == "Yes" ]; then
			if [ "$INSTALL" == "GS" -a "`grep '<Directory \/home\/\*\/pserver\/\*>' /etc/proftpd/proftpd.conf`" -a ! -f /etc/proftpd/conf.d/easy-wi-game.conf ]; then
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
</Directory>" > /etc/proftpd/conf.d/easy-wi-game.conf
				echo "<Directory /home/$MASTERUSER>" >> /etc/proftpd/conf.d/easy-wi-game.conf
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
</Directory>" >> /etc/proftpd/conf.d/easy-wi-game.conf

				GAMES=("ark" "arma3" "bukkit" "hexxit" "mc" "mtasa" "projectcars" "rust" "samp" "spigot" "teeworlds" "tekkit" "tekkit-classic")
				for GAME in ${GAMES[@]}; do
					echo "<Directory ~/server/$GAME*/*>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>" >> /etc/proftpd/conf.d/easy-wi-game.conf
				done

				GAME_MODS=("csgo" "cstrike" "czero" "orangebox" "dod" "garrysmod")
				for GAME_MOD in ${GAME_MODS[@]}; do
					echo "<Directory ~/server/*/${GAME_MOD}/*>
    Umask 077 077
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>" >> /etc/proftpd/conf.d/easy-wi-game.conf
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
</Directory>" >> /etc/proftpd/conf.d/easy-wi-game.conf
				done
			fi

			if [ "$INSTALL" != "GS" ]; then
      	if [ ! -f /etc/proftpd/conf.d/easy-wi-web.conf ]; then
					echo "
<Directory /home/web-*/htdocs/*>
    Umask 022 022
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>
" >> /etc/proftpd/conf.d/easy-wi-web.conf
      	elif [ -z "`grep '<Directory \/home\/\web-\*\/htdocs\/\*>' /etc/proftpd/conf.d/easy-wi-web.conf`" ]; then
					echo "
<Directory /home/web-*/htdocs/*>
    Umask 022 022
    <Limit RNFR RNTO STOR DELE MKD RMD>
        AllowAll
    </Limit>
</Directory>
" >> /etc/proftpd/conf.d/easy-wi-web.conf
				fi
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
	else
		PROFTP_INSTALL="NO"
	fi
fi

if [ "$INSTALL" == "GS" -o "$INSTALL" == "WR" ]; then
	if [ "$OS" != "centos" ]; then
		if [ ! -f /home/aquota.user ]; then
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
		else
			QUOTAINSTALL="No"
		fi

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

			cyanMessage " "
			okAndSleep "Quota Table Output"
			cyanMessage " "
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
fi

if [ "$INSTALL" == "WR" -o "$INSTALL" == "EW" ]; then
	if [ "$WEBSERVER" == "Lighttpd" ]; then
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
			if [ -z "`grep '<IfModule mpm_itk_module>' $APACHE_CONFIG`" ]; then
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


		if [ -z "`grep 'ServerName localhost' $APACHE_CONFIG`" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent error message Could not reliably determine the servers fully qualified domain name' >> $APACHE_CONFIG
			echo 'ServerName localhost' >> $APACHE_CONFIG
		fi

		if [ -z "`grep 'ServerTokens' $APACHE_CONFIG`" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent the server information off in productive systems' >> $APACHE_CONFIG
			echo 'ServerTokens prod' >> $APACHE_CONFIG
		fi

		if [ -z "`grep 'ServerSignature' $APACHE_CONFIG`" ]; then
			echo " " >> $APACHE_CONFIG
			echo '# Added to prevent the server signatur off in productive systems' >> $APACHE_CONFIG
			echo 'ServerSignature off' >> $APACHE_CONFIG
			echo "" >> $APACHE_CONFIG
		fi

		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			APACHE_VERSION=`apache2 -v | grep 'Server version'`
		elif [ "$OS" == "centos" ]; then
			APACHE_VERSION=`httpd -v | grep 'Server version'`
		fi

		if [ -z "`grep '/home/'$MASTERUSER'/sites-enabled/' $APACHE_CONFIG`" ]; then
			echo '# Load config files in the "/home/'$MASTERUSER'/sites-enabled" directory, if any.' >> $APACHE_CONFIG
			if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
				if [[ "$APACHE_VERSION" =~ .*Apache/2.2.* ]]; then
					echo "Include /home/$MASTERUSER/sites-enabled/" >> $APACHE_CONFIG
				else
					echo "IncludeOptional /home/$MASTERUSER/sites-enabled/*.conf" >> $APACHE_CONFIG
				fi
			elif [ "$OS" == "centos" ]; then
				if [[ $APACHE_VERSION =~ .*Apache/2.2.* ]]; then
					echo "Include /home/$MASTERUSER/sites-enabled/" >> $APACHE_CONFIG
				else
					echo "IncludeOptional /home/$MASTERUSER/sites-enabled/*.conf" >> $APACHE_CONFIG
				fi
			fi
		fi

		if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
			rm /etc/apache2/sites-enabled/000-default.conf
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
	if [ -f /etc/sudoers -a -z "`grep $MASTERUSER /etc/sudoers | grep $PKILL`" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $PKILL" >> /etc/sudoers
	fi
	if [ -f /etc/sudoers -a -z "`grep $MASTERUSER /etc/sudoers | grep $USERADD`" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERADD" >> /etc/sudoers
	fi

	if [ -f /etc/sudoers -a -z "`grep $MASTERUSER /etc/sudoers | grep $USERMOD`" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERMOD" >> /etc/sudoers
	fi

	if [ -f /etc/sudoers -a -z "`grep $MASTERUSER /etc/sudoers | grep $USERDEL`" ]; then
		echo "$MASTERUSER ALL = NOPASSWD: $USERDEL" >> /etc/sudoers
	fi

	if [ "$QUOTAINSTALL" == "Yes" -a -f /etc/sudoers ]; then
		if [ -z "`grep $MASTERUSER /etc/sudoers | grep setquota`" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: `which setquota`" >> /etc/sudoers
		fi

		if [ -z "`grep $MASTERUSER /etc/sudoers | grep repquota`" ]; then
			echo "$MASTERUSER ALL = NOPASSWD: `which repquota`" >> /etc/sudoers
		fi
	fi

	if [ "$INSTALL" == "GS" -a -f /etc/sudoers -a -z "`grep $MASTERUSER /etc/sudoers | grep temp`" ]; then
		echo "$MASTERUSER ALL = (ALL, !root:$MASTERUSER) NOPASSWD: /home/$MASTERUSER/temp/*.sh" >> /etc/sudoers
		echo "$MASTERUSER ALL = (ALL, !root:$MASTERUSER) NOPASSWD: /bin/bash /home/$MASTERUSER/temp/*.sh" >> /etc/sudoers
	fi

	if [ "$INSTALL" == "WR" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ "$WEBSERVER" == "Lighttpd" ]; then
				HTTPDBIN=`lighttpd`
				HTTPDSCRIPT="/etc/init.d/lighttpd reload"
			elif [ "$WEBSERVER" == "Apache" ]; then
				HTTPDBIN=`apache2`
				HTTPDSCRIPT="/etc/init.d/apache2 reload"
			fi
		elif [ "$OS" == "centos" ]; then
			if [ "$WEBSERVER" == "Lighttpd" ]; then
				HTTPDBIN=`lighttpd`
				HTTPDSCRIPT='/bin/systemctl reload lighttpd'
			elif [ "$WEBSERVER" == "Apache" ]; then
				HTTPDBIN=`httpd`
				HTTPDSCRIPT='/bin/systemctl reload httpd'
			fi
		fi

		if [ -n "`which $HTTPDBIN`" -a -f /etc/sudoers ]; then
			if [ -z "`grep $MASTERUSER /etc/sudoers | grep $HTTPDBIN`" ]; then
				echo "$MASTERUSER ALL = NOPASSWD: $HTTPDSCRIPT" >> /etc/sudoers
			fi
		fi
	fi
fi

if [ "$INSTALL" == "WR" ]; then
	chown -cR $MASTERUSER:$WEBGROUPNAME /home/$MASTERUSER/ >/dev/null 2>&1

	cyanMessage " "
	yellowMessage "Following data need to be configured at the easy-wi.com panel:"

	cyanMessage " "
	greenOneLineMessage "The path to the folder \"sites-enabled\" is: "
	cyanMessage "/home/$MASTERUSER/sites-enabled/"

	greenOneLineMessage "The useradd command is: "
	cyanMessage "sudo $USERADD %cmd%"

	greenOneLineMessage "The usermod command is: "
	cyanMessage "sudo $USERMOD %cmd%"

	greenOneLineMessage "The userdel command is: "
	cyanMessage "sudo $USERDEL %cmd%"

	if [ -n "$HTTPDSCRIPT" ]; then
		greenOneLineMessage "The Webserver restart command is: "
		cyanMessage "sudo $HTTPDSCRIPT"
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

	if [ -z "`grep '/bin/false' /etc/shells`" ]; then
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
		okAndSleep "Adding AdoptOpenJDK backports"
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ -z "`grep adoptopenjdk /etc/apt/sources.list`" ]; then
				$INSTALLER install apt-transport-https ca-certificates dirmngr gnupg software-properties-common -y
				wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
				add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
			fi
		elif [ "$OS" == "centos" ]; then
			cat <<EOF > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/7/$(uname -m)
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF
		fi
		$INSTALLER -y update
		checkInstall adoptopenjdk-8-hotspot
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

	if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
		cyanMessage " "
		okAndSleep "Installing required packages wput screen bzip2 sudo rsync zip unzip"
		$INSTALLER -y install wput screen bzip2 sudo rsync zip unzip

		if [ "`uname -m`" == "x86_64" ]; then
			cyanMessage " "
			okAndSleep "Installing 32bit support for 64bit systems."

			dpkg --add-architecture i386
			$INSTALLER -y update

			$INSTALLER -y install zlib1g
			$INSTALLER -y install libc6-i386
			if [ "$OS" == "debian" -a "$OSVERSION" -gt "90" -o "$OS" == "ubuntu" -a "$OSVERSION" -gt "1803" ]; then
				$INSTALLER -y install lib32z1
				$INSTALLER -y install lib32readline7
				$INSTALLER -y install libreadline7:i386
			else
				$INSTALLER -y install ia32-libs
				$INSTALLER -y install lib32gcc1
				$INSTALLER -y install lib32readline5
				$INSTALLER -y install libreadline5:i386
			fi
			$INSTALLER -y install lib32ncursesw5
			$INSTALLER -y install lib32stdc++6
			$INSTALLER -y install lib64stdc++6
			$INSTALLER -y install libstdc++6
			$INSTALLER -y install libgcc1:i386
      $INSTALLER -y install libtinfo5:i386
      $INSTALLER -y install libncurses5:i386
			$INSTALLER -y install libncursesw5:i386
			$INSTALLER -y install libncurses5-dev
			$INSTALLER -y install libncursesw5-dev
			$INSTALLER -y install zlib1g:i386
		else
			if [ "$OS" == "debian" -a "$OSVERSION" -gt "90" -o "$OS" == "ubuntu" -a "$OSVERSION" -gt "1803" ]; then
				$INSTALLER -y install libreadline7 libncursesw5
			else
				$INSTALLER -y install libreadline5 libncursesw5
			fi
		fi
	elif [ "$OS" == "centos" ]; then
		cyanMessage " "
		okAndSleep "Installing required packages screen bzip2 sudo rsync zip unzip ncurses"
		checkInstall screen
		checkInstall bzip2
		checkInstall sudo
		checkInstall rsync
		checkInstall zip
		checkInstall unzip
		checkInstall ncurses-libs.i686

		# wput from rpmforge
		LASTEST_RPMFORGE_VERSION=$(curl -s http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el7/en/x86_64/rpmforge/RPMS/ | grep -o rpmforge-release-[0-9].[0-9].[0-9]-[0-9].el[0-9].rf.x86_64.rpm | head -n1)
		if [ -n "$LASTEST_RPMFORGE_VERSION" ]; then
			okAndSleep "Installing required packages rpmforge-release wput"
			wget -q --timeout=60 -P /tmp/ http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el7/en/x86_64/rpmforge/RPMS/"$LASTEST_RPMFORGE_VERSION"
			rpm -Uvh /tmp/"$LASTEST_RPMFORGE_VERSION"
			checkInstall wput
		fi

		if [ "`uname -m`" == "x86_64" ]; then
			okAndSleep "Installing 32bit support for 64bit systems."
			checkInstall glibc.i686
			checkInstall libstdc++.i686
			checkInstall lib32tinfo5
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

		# if steam failed then installing standard kernel (mini fix)
		if [ "$?" -ne "0" ]; then
			cyanMessage " "
			yellowMessage "Steam Bug found! Installing the latest Standard Kernel to run Steam."
			touch /tmp/easy-wi_reboot
			$INSTALLER update -y
			$INSTALLER install linux-image-amd64 linux-headers-amd64 -y
		fi

		if [ -f /home/$MASTERUSER/masterserver/steamCMD/linux32/steamclient.so ]; then
			su -c "mkdir -p ~/.steam/sdk32/" $MASTERUSER
			su -c "chmod 750 -R ~/.steam/" $MASTERUSER
			su -c "ln -s ~/masterserver/steamCMD/linux32/steamclient.so ~/.steam/sdk32/steamclient.so" $MASTERUSER
		fi
	fi

	chown -cR $MASTERUSER:$MASTERUSER /home/$MASTERUSER >/dev/null 2>&1

	if [ -f /etc/crontab -a -z "`grep 'Minecraft can easily produce 1GB' /etc/crontab`" ]; then
		cyanMessage " "
		okAndSleep "Installing Minecraft Crontabs"
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
		mysql --user=root --password="$MYSQL_ROOT_PASSWORD" <<_EOF_
DELETE FROM mysql.user WHERE User='easy_wi';
DROP DATABASE IF EXISTS easy_wi;
FLUSH PRIVILEGES;
_EOF_
	fi

	if [ -z "`id easywi_web 2> /dev/null`" -a ! -d /home/easywi_web ]; then
		$USERADD -md /home/easywi_web -g $WEBGROUPNAME -s /bin/bash -k /home/$MASTERUSER/skel/ easywi_web
	elif [ -z "`id easywi_web 2> /dev/null`" -a -d /home/easywi_web ]; then
		$USERADD -d /home/easywi_web -g $WEBGROUPNAME -s /bin/bash easywi_web
	fi

	makeDir /home/easywi_web/htdocs
	makeDir /home/easywi_web/logs
	makeDir /home/easywi_web/tmp
	makeDir /home/easywi_web/sessions
	chown -cR easywi_web:$WEBGROUPNAME /home/easywi_web >/dev/null 2>&1

	if [ -z "`id easywi_web 2> /dev/null`" ]; then
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
	if [ -n "${HEX_FOLDER}" ]; then
		mv ${HEX_FOLDER}/* ./
		rm -rf ${HEX_FOLDER}
	fi

	find /home/easywi_web/ -type f -exec chmod 0640 {} \;
	find /home/easywi_web/ -mindepth 1 -type d -exec chmod 0750 {} \;

	chown -cR easywi_web:$WEBGROUPNAME /home/easywi_web >/dev/null 2>&1

	DB_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c18`
	cyanMessage " "
	okAndSleep "Creating database easy_wi and connected user easy_wi"
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		cyanMessage " "
		cyanMessage "Please provide the root password for the MySQL Database."
		read MYSQL_ROOT_PASSWORD
	fi
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS easy_wi; GRANT ALL ON easy_wi.* TO 'easy_wi'@'localhost' IDENTIFIED BY '$DB_PASSWORD'; FLUSH PRIVILEGES;"

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
			cyanMessage " "
			cyanMessage " "
			okAndSleep "Installing package certbot"
			if [ "$OS" == "debian" ]; then
				if [ "$OSBRANCH" == "wheezy" ]; then
					wget https://dl.eff.org/certbot-auto
					chmod a+x certbot-auto
				elif [ "$OSBRANCH" == "jessie" ]; then
					if [ -z "`grep jessie-backports /etc/apt/sources.list`" ]; then
						okAndSleep "Adding jessie backports"
						echo "deb http://ftp.de.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
					fi
					$INSTALLER -y update
					$INSTALLER -y install certbot -t jessie-backports
				else
					checkInstall certbot
				fi
			elif [ "$OS" == "ubuntu" ]; then
				add-apt-repository -y ppa:certbot/certbot
				$INSTALLER -y update
				checkInstall certbot
			elif [ "$OS" == "centos" ]; then
				$INSTALLER-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional -y
				checkInstall certbot
				checkInstall mod_ssl
			fi
		elif [ "$SSL_KEY" == "Self-signed" ]; then
			if [ "$WEBSERVER" == "Apache" ]; then
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
			if [ "$OS" == "debian" -a "$OSVERSION" -ge "85" ]; then
				openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/$FILE_NAME.key -out $SSL_DIR/$FILE_NAME.crt -subj "/CN=$IP_DOMAIN"
			else
				if [ "$OS" == "centos" -a "OSVERSION" -ge "80" ]; then
					openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/$FILE_NAME.key -out $SSL_DIR/$FILE_NAME.crt -subj "/C=XX/CN=$IP_DOMAIN"
				else
					openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/$FILE_NAME.key -out $SSL_DIR/$FILE_NAME.crt -subj "/C=/ST=/L=/O=/OU=/CN=$IP_DOMAIN"
				fi
			fi
		fi
	fi

	#Certbot - create Cerfiticate
	if [ "$SSL" == "Yes" -a "$SSL_KEY" == "Lets Encrypt" ]; then
		if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
			if [ "$WEBSERVER" == "Apache" ]; then
				cyanMessage " "
				okAndSleep "Stopping PHP-FPM and Apache2."
				service php${USE_PHP_VERSION}-fpm stop
				service apache2 stop
			fi
			cyanMessage " "
			if [ "$OS" == "debian" -a "$OSBRANCH" == "wheezy" ]; then
				/root/certbot-auto certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
				if [ ! -d /etc/letsencrypt/live/"$IP_DOMAIN" ]; then
					cyanMessage " "
					redMessage 'Error in certificate.. it will be tried without "www."'
					/root/certbot-auto certonly --standalone -d "$IP_DOMAIN"
				fi
			else
				certbot certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
				if [ ! -d /etc/letsencrypt/live/"$IP_DOMAIN" ]; then
					cyanMessage " "
					redMessage 'Error in certificate.. it will be tried without "www."'
					certbot certonly --standalone -d "$IP_DOMAIN"
				fi
			fi
		elif [ "$OS" == "centos" ]; then
			if [ "$WEBSERVER" == "Apache" ]; then
				okAndSleep "Stopping Apache2."
				systemctl stop httpd.service
			elif [ "$WEBSERVER" == "Lighttpd" ]; then
				okAndSleep "Stopping Lighttpd and PHP-FPM."
				systemctl stop lighttpd
				systemctl stop php-fpm.service
			fi

			cyanMessage " "
			certbot certonly --standalone -d "$IP_DOMAIN" -d www."$IP_DOMAIN"
			if [ ! -d /etc/letsencrypt/live/"$IP_DOMAIN" ]; then
				cyanMessage " "
				redMessage 'Error in certificate.. it will be tried without "www."'
				certbot certonly --standalone -d "$IP_DOMAIN"
			fi
		fi
	fi

	if [ "$WEBSERVER" == "Lighttpd" ]; then
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
		echo "php_admin_value[session.save_path] = /home/easywi_web/sessions" >> $FILE_NAME_POOL

		chown $MASTERUSER:$WEBGROUPNAME $FILE_NAME_POOL
	fi

	FILE_NAME_VHOST=/home/$MASTERUSER/sites-enabled/$FILE_NAME.conf

	if [ "$WEBSERVER" == "Apache" ]; then
		echo '<VirtualHost *:80>' > $FILE_NAME_VHOST
		echo "    ServerName $IP_DOMAIN" >> $FILE_NAME_VHOST
		echo "    ServerAdmin info@$IP_DOMAIN" >> $FILE_NAME_VHOST

		if [ "$SSL" == "Yes" ]; then
			echo "    Redirect permanent / https://$IP_DOMAIN/" >> $FILE_NAME_VHOST
			echo '</VirtualHost>' >> $FILE_NAME_VHOST

			if [ "$OS" != "centos" ]; then
				okAndSleep "Activating TLS/SSL related Apache modules."
				a2enmod ssl
			fi

			if [ "$OS" != "centos" ]; then
				cyanMessage " "
				okAndSleep "Activating Headers related Apache modules."
				a2enmod headers
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
			echo " " >> $FILE_NAME_VHOST
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
		echo '       php_admin_value session.save_path "/home/easywi_web/sessions"' >> $FILE_NAME_VHOST
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

	chown $MASTERUSER:$WEBGROUPNAME $FILE_NAME_VHOST

	RestartWebserver

	if [ -z "`grep -o ./reboot.php /etc/crontab`" ]; then
		cyanMessage " "
		okAndSleep "Installing Easy-WI Crontabs"
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
	LOCAL_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')

	if [ -z "$LOCAL_IP" -o "$LOCAL_IP" == "0" -o "$LOCAL_IP" == "localhost" ]; then
		LOCAL_IP=`hostname -I | awk '{print $1}'`
	fi

	if [ "$OS" == "centos" ]; then
		checkInstall bzip2
	fi

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
		if [ -z "`grep '127.0.0.1' $QUERY_WHITLIST_TXT`" ]; then
			echo "127.0.0.1" >> $QUERY_WHITLIST_TXT
		fi

		if [ -n "$LOCAL_IP" ]; then
			if [ -n "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $LOCAL_IP`" -a -z "`grep $LOCAL_IP $QUERY_WHITLIST_TXT`" ]; then
				echo $LOCAL_IP >> $QUERY_WHITLIST_TXT
			fi
		fi

#####
# alle IPs: ip a | grep inet | awk '{print $2}'
# -> IP check ob mehrere IPs
# -> wenn nur eine IP, dann Single Command
# -> ansonsten per ts3server.ini die IP zuweisen
#####

		cyanMessage " "
		cyanMessage "Please specify the IPv4 address of the Easy-WI web panel."
		OPTIONS=("$LOCAL_IP" "Other")
		select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorAndQuit;;
				*) errorAndContinue;;
			esac
		done

		if [ "$OPTION" == "$LOCAL_IP" -a -n "$LOCAL_IP" ]; then
			IP_ADDRESS="$LOCAL_IP"
		else
			cyanMessage " "
			cyanMessage "Please provide the IP address of the Easy-WI web panel."
			read IP_ADDRESS
		fi

		if [ -n "$IP_ADDRESS" ]; then
			if [ -n "`grep -E '\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b' <<< $IP_ADDRESS`" -a -z "`grep $IP_ADDRESS $QUERY_WHITLIST_TXT`" ]; then
				echo $IP_ADDRESS >> $QUERY_WHITLIST_TXT
			fi
		fi
	else
		redMessage "Cannot edit the file $QUERY_WHITLIST_TXT, please maintain it manually."
	fi

	if [ ! -f /home/$MASTERUSER/.ts3server_license_accepted ]; then
		su -c "touch .ts3server_license_accepted" $MASTERUSER
		chown -cR $MASTERUSER:$MASTERUSER /home/$MASTERUSER/.ts3server_license_accepted 2>&1 >/dev/null
	fi

	QUERY_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c12`

	greenMessage " "
	greenMessage "Starting the TS3 server for the first time and shutting it down again as the password will be visible in the process tree."
	su -c "./ts3server_startscript.sh start serveradmin_password=$QUERY_PASSWORD" $MASTERUSER
	runSpinner 25
	su -c "./ts3server_startscript.sh stop" $MASTERUSER

	greenMessage " "
	greenMessage "Starting the TS3 server permanently."
	su -c "./ts3server_startscript.sh start" $MASTERUSER
fi

if [ "$INSTALL" == "MY" ]; then
	cyanMessage " "
	cyanMessage "Please enter the name of the database user, which does not exist yet."
	read MYSQL_USER

	MYSQL_USER_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c18`

	if [ "$EXTERNAL_INSTALL" == "No" ]; then
		if [ -n "`ps fax | grep 'mysqld' | grep -v 'grep'`" ]; then
			mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
			ERROR_CODE=$?

			until [ $ERROR_CODE == 0 ]; do
				cyanMessage " "
				cyanOneLineMessage "Password incorrect, please provide the "; greenOneLineMessage "root password "; cyanMessage "for the MySQL Database."
				read MYSQL_ROOT_PASSWORD

				mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
				ERROR_CODE=$?
			done

			mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EXECUTE ON *.* TO '$MYSQL_USER'@'localhost' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0; FLUSH PRIVILEGES;" 2> /dev/null
		else
			redMessage " "
			redMessage "Error: No Database Server running!"
		fi
	else
		mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
		ERROR_CODE=$?

		until [ $ERROR_CODE == 0 ]; do
			cyanMessage " "
			cyanOneLineMessage "Password incorrect, please provide the "; greenOneLineMessage "root"; cyanMessage " password for the MySQL Database."
			read MYSQL_ROOT_PASSWORD

			mysql -uroot -p$MYSQL_ROOT_PASSWORD -e exit 2> /dev/null
			ERROR_CODE=$?
		done

		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PASSWORD';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EXECUTE ON *.* TO '$MYSQL_USER'@'%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0; FLUSH PRIVILEGES;" 2> /dev/null
	fi
fi

# Removing not needed packages
if [ "$OS" == "debian" -o "$OS" == "ubuntu" ]; then
	$INSTALLER -y -q autoremove 2>&1 >/dev/null
elif [ "$OS" == "centos" ]; then
	$INSTALLER -y -q clean all
	rm -rf /var/cache/yum
fi

# Firewall CentOS
if [ "$OS" == "centos" ]; then
	if ([ -n "`rpm -qa firewalld`" -a -z "`systemctl status firewalld 2>/dev/null | egrep -o 'inactive'`" ]); then
		yellowMessage " "
		yellowMessage "Adding Firewall Rules for:"

		if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" ]; then
			if [ -z "`firewall-cmd --zone=public --list-all | egrep -o 'http'`" ]; then
				greenMessage " - HTTP Port: 80/tcp"
				firewall-cmd --zone=public --permanent --add-service=http 1> /dev/null
				FIREWALL="Yes"
			fi
			if [ "$SSL" == "Yes" -a -z "`firewall-cmd --zone=public --list-all | egrep -o 'https'`" ]; then
				greenMessage " - HTTPS Port: 443/tcp"
				firewall-cmd --zone=public --permanent --add-service=https 1> /dev/null
				FIREWALL="Yes"
			fi
		fi

		if [ "$INSTALL" == "EW" -o "$INSTALL" == "WR" -o "$INSTALL" == "GS" ]; then
			if [ "$PROFTP_INSTALL" != "NO" ]; then
				if [ -z "`firewall-cmd --zone=public --list-all | egrep -o 'ftp'`" ]; then
					greenMessage " - FTP Port: 21/tcp"
					firewall-cmd --zone=public --permanent --add-service=ftp 1> /dev/null
					FIREWALL="Yes"
				fi
			fi
		fi

		if [ "$INSTALL" == "WR" -o "$INSTALL" == "MY" ]; then
			if [ "$EXTERNAL_INSTALL" == "Yes" -a "$SQL" != "None" ]; then
				if [ -z "`firewall-cmd --zone=public --list-all | egrep -o 'mysql'`" ]; then
					greenMessage " - MySQL Port: 3306/tcp"
					firewall-cmd --zone=public --permanent --add-service=mysql 1> /dev/null
					FIREWALL="Yes"
				fi
			fi
		fi

		if [ "$INSTALL" == "VS" ]; then
			if [ -z "`firewall-cmd --zone=public --list-all | egrep -o '9987'`" ]; then
				greenMessage " - Teamspeak Port: 10011/tcp, 30033/tcp, 9987/udp"
				firewall-cmd --zone=public --permanent --add-port=10011/tcp 1> /dev/null
				firewall-cmd --zone=public --permanent --add-port=30033/tcp 1> /dev/null
				firewall-cmd --zone=public --permanent --add-port=9987/udp 1> /dev/null
				FIREWALL="Yes"
			fi
		fi

		if [ "$INSTALL" == "GS" ]; then
			if [ -z "`firewall-cmd --zone=public --list-all | egrep -o '4380'`" ]; then
				greenMessage " - Steam Port: 4380/udp, 27000-27030/udp"
				firewall-cmd --zone=public --permanent --add-port=4380/udp 1> /dev/null
				firewall-cmd --zone=public --permanent --add-port=27000-27030/udp 1> /dev/null
				FIREWALL="Yes"
			fi
		fi

		if [ "$FIREWALL" == "Yes" ]; then
			firewall-cmd --reload 1> /dev/null
			greenMessage " "
		else
			if [ "$INSTALL" == "GS" ]; then
				FIREWALL="Yes"
			fi
			greenMessage "Nothing to do."
			greenMessage " "
		fi
	else
		FIREWALL="No"
	fi
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
	redMessage " "
	if [ ! -f /root/database_root_login.txt ]; then
		touch /root/database_root_login.txt
		echo "User: root" > /root/database_root_login.txt
		echo "Password: $MYSQL_ROOT_PASSWORD" >> /root/database_root_login.txt
		greenOneLineMessage "Database root login data is saved in "; cyanOneLineMessage "\"/root/database_root_login.txt\""; greenMessage "."
		redMessage "Please download and remove this file from this system!"
		echo
		redMessage "Don´t use root Login for Easy-WI or so!"
		redMessage "The root Login is only for Expert User and Reseller!"
	fi
	yellowMessage " "
elif [ "$INSTALL" == "GS" ]; then
	greenMessage " "
	greenOneLineMessage "Gameserver Root setup is done. Please enter the above data at the webpanel at "; cyanOneLineMessage "\"App/Game Master > Overview > Add\""; greenMessage "."
	greenMessage " "
	greenOneLineMessage "Username: "; cyanMessage "$MASTERUSER"

	if [ -f /home/easywi_web/htdocs/keys/"$MASTERUSER" ]; then
		greenOneLineMessage "Keyfile Name: "; cyanMessage "$MASTERUSER"
	else
		yellowMessage "Don't forget to copy Keyfile into \"/home/easywi_web/keys/\""
	fi
	if [ "$OS" == "centos" -a "$FIREWALL" == "Yes" ]; then
		redMessage " "
		redMessage "Don't forget to open Game Server Ports self!"
		redMessage " "
		cyanMessage 'Command:'
		yellowMessage 'firewall-cmd --zone=public --permanent --add-port=Port_Number/tcp_or_udp'
		yellowMessage 'After adding: firewall-cmd --reload'
		yellowMessage " "
		cyanMessage 'Example:'
		yellowMessage 'firewall-cmd --zone=public --permanent --add-port=27015/udp'
		yellowMessage 'firewall-cmd --reload'
	fi
	yellowMessage " "
	if [ -f /tmp/easy-wi_reboot ]; then
		greenMessage "Please execute following Command after reboot:"
		cyanMessage "cd /home/"$MASTERUSER"/masterserver/steamCMD/ && su -c \"./steamcmd.sh +login anonymous +quit\" $MASTERUSER"
		yellowMessage " "
		doReboot "System will rebooting now for activating a new Kernel!"
	fi
elif [ "$INSTALL" == "VS" ]; then
	greenMessage " "
	greenMessage "Teamspeak 3 setup is done."
	greenOneLineMessage "TS3 Query password is "; cyanMessage "$QUERY_PASSWORD"
	greenOneLineMessage "Please enter this server at the webpanel at "; cyanOneLineMessage "\"Voiceserver > Master > Add\""; greenMessage "."
	greenMessage " "
	greenOneLineMessage "Username: "; cyanMessage "$MASTERUSER"
	if [ -f /home/easywi_web/htdocs/keys/"$MASTERUSER" -a "$SSH_KEY_NOT_COPY" != "YES" ]; then
		greenOneLineMessage "Keyfile Name: "; cyanMessage "$MASTERUSER"
	else
		yellowMessage "Don't forget to copy Keyfile into \"/home/easywi_web/keys/\""
	fi
	greenMessage " "
elif [ "$INSTALL" == "WR" ]; then
	if [ "$PHPINSTALL" == "Yes" ]; then
		yellowMessage " "
		yellowMessage "Don't forget to change date.timezone (your Timezone) inside your php.ini."
	fi
	greenMessage " "
	greenOneLineMessage "Webspace Root setup is done. Please enter the above data at the webpanel at "; cyanOneLineMessage "\"Webspace > Master > Add\""; greenMessage "."
	greenMessage " "
	greenOneLineMessage "Username: "; cyanMessage "$MASTERUSER"
	greenOneLineMessage "Webgroup: "; cyanMessage "$WEBGROUPNAME"
	if [ -f /home/easywi_web/htdocs/keys/"$MASTERUSER" -a "$SSH_KEY_NOT_COPY" != "YES" ]; then
		greenOneLineMessage "Keyfile Name: "; cyanMessage "$MASTERUSER"
	else
		yellowMessage "Don't forget to copy Keyfile into \"/home/easywi_web/htdocs/keys/\""
	fi
	greenMessage " "
	if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
		if [ ! -f /root/database_root_login.txt ]; then
			touch /root/database_root_login.txt
			echo "User: root" > /root/database_root_login.txt
			echo "Password: $MYSQL_ROOT_PASSWORD" >> /root/database_root_login.txt
			greenOneLineMessage "Database root login data is saved in "; cyanOneLineMessage "\"/root/database_root_login.txt\""; greenMessage "."
			redMessage "Please download and remove this file from this system!"
			redMessage " "
			redMessage "Don't use root Login for Easy-WI or so!"
			redMessage "The root Login is only for Expert User and Reseller!"
		fi
		greenMessage " "
	fi
elif [ "$INSTALL" == "MY" ]; then
	if [ -n "$MYSQL_USER" -a -n "$MYSQL_USER_PASSWORD" ]; then
		greenMessage " "
		greenOneLineMessage "MySQL setup is done. Please enter the server at the webpanel at "; cyanOneLineMessage "\"MySQL > Master > Add\""; greenMessage "."
		greenMessage " "
		greenOneLineMessage "DB user name are "; cyanOneLineMessage "$MYSQL_USER"; greenOneLineMessage " and the password is "; cyanMessage "$MYSQL_USER_PASSWORD"
		greenMessage " "
	fi
	if [ -n "$MYSQL_ROOT_PASSWORD" -a "$SQL" != "None" ]; then
		if [ ! -f /root/database_root_login.txt ]; then
			touch /root/database_root_login.txt
			echo "User: root" > /root/database_root_login.txt
			echo "Password: $MYSQL_ROOT_PASSWORD" >> /root/database_root_login.txt
			greenOneLineMessage "Database root login data is saved in "; cyanOneLineMessage "\"/root/database_root_login.txt\""; greenMessage "."
			redMessage "Please download and remove this file from this system!"
			redMessage " "
			redMessage "Don´t use root Login for Easy-WI or so!"
			redMessage "The root Login is only for Expert User and Reseller!"
		fi
		greenMessage " "
	fi
fi

if [ -f /root/database_root_login.txt ]; then
	chmod 600 /root/database_root_login.txt 2>&1 >/dev/null
fi

clearPassword
cyanMessage " "

if [ "$DEBUG" == "ON" ]; then
	set +x
fi

exit 0
