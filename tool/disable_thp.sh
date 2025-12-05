#/bin/bash
function modify_grub(){
    # modify /etc/default/grub
    grep "transparent_hugepage=never" /etc/default/grub > /dev/null
    if [ $? == 0 ]; then
        echo "/etc/default/grub Modified ..."
    else
        /bin/cp /etc/default/grub /etc/default/grub.`date +'%Y%m%d'`
        sed -i '/^GRUB_CMDLINE_LINUX=/s/\("\)$/ transparent_hugepage=never"/g' /etc/default/grub
    fi
}

function centos_backup_grubcfg(){
    # backup grub.cfg
    if [ -f /boot/grub2/grub.cfg.* ] || [ -f /boot/efi/EFI/centos/grub.cfg.* ];then
    	echo "grub.cfg Backed up ..."
    elif [ -f /boot/grub2/grub.cfg ];then
		/bin/cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.`date +'%Y%m%d'`
        /bin/cp /boot/grub2/grub.cfg /root/boot_grub2_grub.cfg.`date +'%Y%m%d'`
    elif [ -f /boot/efi/EFI/centos/grub.cfg ];then
        /bin/cp /boot/efi/EFI/centos/grub.cfg /boot/efi/EFI/centos/grub.cfg.`date +'%Y%m%d'`
        /bin/cp /boot/efi/EFI/centos/grub.cfg /root/boot_efi_EFI_centos_grub.cfg.`date +'%Y%m%d'`
    else
        echo "grub.cfg file does not exist ..."
	exit 0
    fi
}

function centos_grub2_mkconfig(){
    # grub2-mkconfig
    if [ -f /boot/efi/EFI/centos/grub.cfg ] && [ -f /boot/efi/EFI/centos/grub.cfg.* ];then
        diff /boot/efi/EFI/centos/grub.cfg /boot/efi/EFI/centos/grub.cfg.* > /dev/null
		if [ $? != 0 ]; then
	    	echo "Restart the server ..."
            exit 0
        fi
    fi
    if [ -f /boot/grub2/grub.cfg ] && [ -f /boot/grub2/grub.cfg.* ];then
    	diff /boot/grub2/grub.cfg /boot/grub2/grub.cfg.* > /dev/null
		if [ $? != 0 ]; then
	    	echo "Restart the server ..."
            exit 0
        fi
    fi
    grub2-mkconfig -o /boot/grub2/grub.cfg
    grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
}

function ubuntu_backup_grubcfg(){
    # backup grub.cfg
    if [ -f /boot/grub/grub.cfg.* ];then
    	echo "grub.cfg Backed up ..."
    elif [ -f /boot/grub/grub.cfg ];then
		/bin/cp /boot/grub/grub.cfg /boot/grub/grub.cfg.`date +'%Y%m%d'`
        /bin/cp /boot/grub/grub.cfg /root/boot_grub_grub.cfg.`date +'%Y%m%d'`
    else
        echo "grub.cfg file does not exist ..."
    fi
}

function ubuntu_grub2_mkconfig(){
    # grub2-mkconfig
    if [ -f /boot/grub/grub.cfg ] && [ -f /boot/grub/grub.cfg.* ];then
    	diff /boot/grub/grub.cfg /boot/grub/grub.cfg.* > /dev/null
		if [ $? != 0 ]; then
	    	echo "Restart the server ..."
            exit 0
        fi
    fi
	update-grub
}

function main(){
    if [ ! -f /sys/kernel/mm/transparent_hugepage/enabled ];then
        echo "/sys/kernel/mm/transparent_hugepage/enabled file does not exist ..."
    	exit 0
    fi

    grep "\[never\]" /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
    if [ $? == 0 ]; then
        echo "THP has been disabled ..."
        exit 0
    fi
	modify_grub
	centos_backup_grubcfg
	centos_grub2_mkconfig

}

main
