	
# for recovery (global)

on init-recovery
	mount /system

	mount -f /cache	
	ls /cache/recovery/	
	ls /cache/fota/	

	unmount /cache	
	exec -f "/system/bin/e2fsck -v -y <dev_node:/cache>"

	mount /cache	
	fcut --limited-file-size=1024k -f /cache/recovery/last_recovery /tmp/recovery_old.tmp

# running --data_resizing with the userdata binaray
on resizing-data
	mount /system

	mount /data
	find -v --print=/tmp/data.list /data
	unmount /data

	loop_begin 2
		exec "/system/bin/e2fsck -y -f <dev_node:/data>"
		exec "/system/bin/resize2fs -R <footer_length> <dev_node:/data>"
	loop_end

	mount /data
	df /data
	verfiy_data <dev_node:/data> /data 5
	verfiy_data --size-from-file=/tmp/data.list
	unmount /data
	
# only run command csc_factory
on pre-multi-csc
	precondition define /carrier
	mount -r /carrier
	format /carrier

# all
on exec-multi-csc
	echo 
	echo "-- Appling Multi-CSC..."
	unmount /system
	mount --option=rw /system
	echo "Applied the CSC-code : <salse_code>"
	
	ln -v -r --force-link -f /system/csc/common/system/app/ /system/app/
	cp -y -f -r -v /system/csc/common /

	cmp -r -f /system/csc/common/system/app/ /system/app/

	ln -v -r --force-link -f /system/csc/<salse_code>/system/app/ /system/app/
	cp -y -f -r -v /system/csc/<salse_code>/system /system

	cmp -r -f /system/csc/common/csc/<salse_code>/system/app/ /system/app/
	
	rm -v /system/csc_contents
	ln -v -s /system/csc/<salse_code>/csc_contents /system/csc_contents

	rm -v -r -f --limited-file-size=0 --type=file --except-root-dir /system/priv-app
	rm -v -r -f --limited-file-size=0 --type=file --except-root-dir /system/app
	
	unmount /system
	echo "Successfully applied multi-CSC."

# RECOVERY_DISABLE_SYMLINK
on exec-multi-csc-disable-symlink
	echo 
	echo "-- Appling Multi-CSC..."
	unmount /system
	mount --option=rw /system
	echo "Applied the CSC-code : <salse_code>"
	
#	ln -v -r --force-link -f /system/csc/common/system/app/ /system/app/
	cp -y -f -r -v /system/csc/common /

	cmp -r -f /system/csc/common/system/app/ /system/app/

#	ln -v -r --force-link -f /system/csc/<salse_code>/system/app/ /system/app/
	cp -y -f -r -v /system/csc/<salse_code>/system /system

	cmp -r -f /system/csc/common/csc/<salse_code>/system/app/ /system/app/
	
	rm -v /system/csc_contents
	ln -v -s /system/csc/<salse_code>/csc_contents /system/csc_contents

	rm -v -r -f --limited-file-size=0 --type=file --except-root-dir /system/priv-app
	rm -v -r -f --limited-file-size=0 --type=file --except-root-dir /system/app
	
	unmount /system
	echo "Successfully applied multi-CSC."

# only run command csc_factory
on exec-multi-csc-data
	mount -f /efs
	mkdir -f radio system 0771 /efs/recovery
	write -f /efs/recovery/bootmessage "exec-multi-csc-data\n"
	unmount /efs

	unmount -f /system
	#mount /data
	#cp -y -f -r -v --with-fmode=0644 --with-dmode=0771 --with-owner=system.system /data/csc/common /
	#cp -y -f -r -v --with-fmode=0644 --with-dmode=0771 --with-owner=system.system /data/csc/<salse_code> /
	#rm -v -r -f --limited-file-size=0 --type=file --except-root-dir /data/app
	#rm -v -r -f /data/csc
	#unmount /data

# run condition wipe-data and csc_factory
on exec-install-preload
	echo "-- Set Factory Reset done..."
	mount -f /efs
	mkdir -f radio system 0771 /efs/recovery
	write -f /efs/recovery/bootmessage "exec-install-preload\n"
	write -f /efs/recovery/currentlyFactoryReset "done"
	ls /efs/imei/
	unmount /efs

    #echo "-- Copying media files..."
	#mount /data
    #mount /system
	#mkdir media_rw media_rw 0770 /data/media
	#cp -y -r -v -f --with-fmode=0664 --with-dmode=0775 --with-owner=media_rw.media_rw /system/hidden/INTERNAL_SDCARD/ /data/media/
	#unmount /data
	#mount /data
	#cmp -r /system/hidden/INTERNAL_SDCARD/ /data/media/

    #echo "--  preload checkin..."
    #precondition define /preload

    #mount -f /preload
    #precondition mounted /preload

	#cp -y -r -v -f --with-fmode=0664 --with-dmode=0775 --with-owner=media_rw.media_rw /preload/INTERNAL_SDCARD/ /data/media/
	#unmount /data
	#mount /data
	#cmp -r /preload/INTERNAL_SDCARD/ /data/media/

on post-exec-install-preload
	mount -f /efs
	mkdir -f radio system 0771 /efs/recovery
	write -f /efs/recovery/bootmessage "post-exec-install-preload\n"
	unmount /efs
	# for KOR
    #mount /system
    #precondition file /system/preload
	#mount /data
	#mkdir system system 0775 /data/app
	#cp -y -f -v --with-fmode=0664 --with-owner=system.system /system/preload/*.ppk /data/app/*.apk

on exec-delete-selective-file
    echo "-- Deleting selective files"

    unmount /system
    mount --option=rw /system

#    ls /system/lib64

#    cat /system/csc/rm.list

    rm -f /system/lib64/libiq_client.so
    rm -f /system/lib64/libiq_service.so

#    ls /system/lib64

    unmount /system

    echo "Successfully deleted data selecitvely"

on exec-check-meminfo
	echo "-- meminfo..."
	ls /tmp
	rm -v -f tmp/meminfo
	cp -y -f -v /proc/meminfo /tmp/meminfo
	df ./tmp

# remove sec directorys of another sales code for single SKU feature
on clear-sec-directory
# for debugging
#	mkdir /system/omc
#	mkdir /system/omc/ATT
#	mkdir /system/omc/ATT/etc
#	mkdir /system/omc/ATT/res
#	mkdir /system/omc/ATT/sec
#	mkdir /system/omc/SPR
#	mkdir /system/omc/SPR/etc
#	mkdir /system/omc/SPR/res
#	mkdir /system/omc/SPR/sec
#	mkdir /system/omc/<salse_code>
#	mkdir /system/omc/<salse_code>/etc
#	mkdir /system/omc/<salse_code>/res
#	mkdir /system/omc/<salse_code>/sec
#	find -v --print=/system/omc/ATT/sec/11.list /system/omc
#	find -v --print=/system/omc/ATT/sec/12.list /system/omc
#	find -v --print=/system/omc/SPR/sec/22.list /system/omc
#	find -v --print=/system/omc/SPR/sec/23.list /system/omc
#	find -v --print=/system/omc/<salse_code>/sec/33.list /system/omc
#	find -v --print=/system/omc/<salse_code>/sec/34.list /system/omc
	
	#for debugging
	find -v --print=/tmp/before_clear_sec.list /system/omc
	find --skip-with=/<salse_code>/ --name-with=/sec --print=/tmp/rm_sec.list /system/omc
	rm -v -r -f --from-defined-file=/tmp/rm_sec.list /system/omc
	#for debugging
	find -v --print=/tmp/after_claer_sec.list /system/omc

on exec-delete-apn-changes
    echo "-- Deleting VZW's apn file"

#    ls /efs/sec_efs/

    rm -f /efs/sec_efs/apn-changes.xml

#    ls /efs/sec_efs/

    echo "Successfully deleted VZW's apn file"

on pre-exec-wipe-data
	echo "-- Start Factory Reset..."
	mount -f /efs
	write -f /efs/recovery/currentlyFactoryReset "start wipe-data\n"
	unmount /efs

on amazon_symlink_TMB
	echo "-- amazon_symlink_tmb..."
	ln -v -s --force-link -f /system/etc/tmb/amzn.mshop.properties /system/etc/amzn.mshop.properties
	
on amazon_symlink_ATT
	echo "-- amazon_symlink_att..."
	ln -v -s --force-link -f /system/etc/att/amazon-kindle.properties /system/etc/amazon-kindle.properties
	ln -v -s --force-link -f /system/etc/att/amzn.mshop.properties /system/etc/amzn.mshop.properties

on amazon_symlink_VZW
	echo "-- amazon_symlink_vzw..."
	ln -v -s --force-link -f /system/etc/vzw/amazon-kindle.properties /system/etc/amazon-kindle.properties
	ln -v -s --force-link -f /system/etc/vzw/amzn.mshop.properties /system/etc/amzn.mshop.properties
	ln -v -s --force-link -f /system/etc/vzw/amzn.mp3.properties /system/etc/amzn.mp3.properties
	ln -v -s --force-link -f /system/etc/vzw/amzn.apps.ref /system/etc/amzn.apps.ref
	ln -v -s --force-link -f /system/etc/vzw/amzn.aiv.properties /system/etc/amzn.aiv.properties
	ln -v -s --force-link -f /system/etc/vzw/Audible.param /system/etc/Audible.param

on amazon_symlink_USC
	echo "-- amazon_symlink_usc..."
	ln -v -s --force-link -f /system/etc/usc/amzn.mshop.properties /system/etc/amzn.mshop.properties

on amazon_symlink_3IE
	echo "-- amazon_symlink_3IE..."
	ln -v -s --force-link -f /system/etc/3ie/amzn.mshop.properties /system/etc/amzn.mshop.properties

on amazon_symlink_DRE
	echo "-- amazon_symlink_DRE..."
	ln -v -s --force-link -f /system/etc/dre/amzn.mshop.properties /system/etc/amzn.mshop.properties 

on amazon_symlink_H3G
	echo "-- amazon_symlink_H3G..."
	ln -v -s --force-link -f /system/etc/h3g/amzn.aiv.properties /system/etc/amzn.aiv.properties

on amazon_symlink_O2U
	echo "-- amazon_symlink_O2U..."
	ln -v -s --force-link -f /system/etc/o2u/amzn.mshop.properties /system/etc/amzn.mshop.properties



