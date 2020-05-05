 #!/bin/bash

 install_menu(){
	echo "It seems you haven't Install BBR2 Kernel, We 'll install it"
	read -p "1：Install 2：Exit without action:" num
	case "$num" in
		1)
		system_check
		;;
		2)
		exit 1
		;;
	esac
 }
 system_check(){
	if [ -f /usr/bin/yum ]; then
		centos_install
	else
		echo -e "Support Linux LBS CentOS ONLY"
		echo -e "Script Deleting...."
		rm -f bbr2.sh
		exit 1
	fi
}

centos_install(){
	mkdir centos
	cd centos
	wget https://asset.obus.me/recourse/bbr2/kernel-headers-5.4.0_rc6-1.x86_64.rpm
	wget https://asset.obus.me/recourse/bbr2/kernel-5.4.0_rc6-1.x86_64.rpm
	yum -y localinstall *
	grub2-set-default 0
	echo "tcp_bbr" >> /etc/modules-load.d/tcp_bbr.conf
	echo "tcp_bbr2" >> /etc/modules-load.d/tcp_bbr2.conf
	echo "tcp_dctcp" >> /etc/modules-load.d/tcp_dctcp.conf
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control = bbr2" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
	sysctl -p
  echo "Delete the temple file"
	rm -rf ~/centos
	read -p "Install BBR2 Successfully, reboot now? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "Rebooting..."
		reboot
	fi
}

 
 start_menu(){
  	echo "[BBR2 Menu]"
 	check_kernel
 	switch=$?
 	if [[ $switch =~ 1 ]]
 	then	
 		echo "========================================="
 		echo "1: Disable BBR2 Cogenstion"
 	elif [[ $switch =~ 2 ]]
 	then
  		echo "========================================="
 		echo "1: Enable BBR2 Cogenstion"
 	else
 		install_menu
 	fi

 	ecn=$(cat /sys/module/tcp_bbr2/parameters/ecn_enable)
	if [[ $ecn =~ Y ]]
	then
		echo "2：Disable ECN Feature"
	else
		if [[ $switch =~ 1 ]]
		then
			echo "2：Enable ECN Feature"
		else
			echo "2：Enable ECN Feature (Please Enable BBR2 First)"
		fi
	fi
	echo "3：Exit without action"
	stty erase '^H' && read -p "Please Choose The Menu:" num
	case "$num" in
		1)
		if [[ $switch =~ 1 ]]
		then
			echo 0 > /sys/module/tcp_bbr2/parameters/ecn_enable
			sysctl net.ipv4.tcp_congestion_control=cubic
			echo "Cogenstion sets to the default Cubic and ECN is disabled"
		else
			sysctl net.ipv4.tcp_congestion_control=bbr2
			echo "Cogenstion sets to bbr2"
		fi
		;;
		2)
		if [[ $ecn =~ Y ]]
		then
			echo 0 > /sys/module/tcp_bbr2/parameters/ecn_enable
			echo "Disable ECN Feature Successfully"
		else
			if [[ $switch =~ 2 ]]
			then
				echo "Illegal Operation! Please Enable BBR2 Cogestion First!"
			else
				echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable
				echo "Enable ECN Feature Successfully"
			fi
		fi
		;;
		3)
		exit 1
		;;
	esac
}

 check_kernel(){
 	congestion=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
	case "$congestion" in
		'bbr2')
		echo 'You have Installed BBR2 Kernel and it Works'
		return 1
 		;;
	esac
	
	all_congestion=$(cat /proc/sys/net/ipv4/tcp_allowed_congestion_control)
	echo ${all_congestion}
	[[ ${all_congestion} =~ 'bbr2' ]] && echo 'You have Installed BBR2 Kernel but it does not Work.' && return 2

	return 0
}

clear
start_menu
