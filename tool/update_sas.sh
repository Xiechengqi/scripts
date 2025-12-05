function centos_check_hba(){
    mpt3sas_version=`modinfo mpt3sas|grep ^version`
    if [ "$mpt3sas_version" == "version:        30.00.00.00" ];then
		echo -e "SAS card driver upgraded ..."
    else
        rpm -ivh /root/kmod-mpt3sas-30.00.00.00_el7.6-1.x86_64.rpm
       	echo -e "SAS card driver needs to be upgrade ..."
    fi
}

function ubuntu_check_hba(){
    mpt3sas_version=`modinfo mpt3sas|grep ^version`
	lspci |egrep 'MegaRAID SAS-3 3108|Logic SAS3008' >/dev/null
    if [ $? != 0 ]; then
       	echo -e "Not SAS (SAS3008 | SAS3108)card ..."
    elif [ "$mpt3sas_version" == "version:        29.100.00.00" ];then
       	echo -e "SAS card driver upgraded ..."
    elif [ "3.10.0-957.el7.x86_64" != "5.3.0-42-generic" ];then
		ubuntu_update_kernel
	else
       	echo -e "SAS card driver needs to be upgrade ..."
	fi
}
function ubuntu_update_kernel(){
	grep 'set default="Advanced options for Ubuntu>Ubuntu, with Linux 5.3.0-42-generic"' /boot/grub/grub.cfg >/dev/null
	if [ $? != 0 ]; then
		apt-get install -y linux-image-5.3.0-42-generic
		sed -i 's#^GRUB_DEFAULT=0#GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.3.0-42-generic"#g' /etc/default/grub
		grub-mkconfig -o /boot/grub/grub.cfg
		update-grub
	else
		echo "Restart the server ..."
	fi
}

function main(){
	centos_check_hba
}

main
