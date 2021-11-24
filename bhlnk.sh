#!/bin/bash
part=(system vendor)
module=(vietsub fonts theme)
dir=$(pwd)
bin="$dir/bin/linux"
bro="$dir/zip_temp"
chmod -R 777 $bin
chmod -R 777 $dir/bin
if [ -f input.zip ]; then
     input=input.zip
elif [ -f rom.zip ]; then
     input=rom.zip
else
    input="$(zenity --title "Pick your ROM" --file-selection 2>/dev/null)"
fi
getszie()
{
	part_size[0]=$(find "system.img" -printf "%s")
	part_size[1]=$(find "vendor.img" -printf "%s")
}
super()
{
echo "#############################"
echo "#     Unpack Super.img .... #"
echo "#############################"
echo ""
echo "Convert sparse images to raw images ...."
echo ""
simg2img super.img raw.img
echo "Unpack super parttion ...."
echo ""
./bin/lpunpack raw.img
}
zipfile()
{
echo "#############################"
echo "#     Unpack Zip rom .... #"
echo "#############################"
	mkdir zip_temp
	mkdir temp
	unzip -t $input
	unzip $input -d zip_temp
	for ((i = 0 ; i < 2 ; i++)); do
		./bin/brotli --decompress zip_temp/"${part[$i]}.new.dat.br" -o zip_temp/"${part[$i]}.new.dat"
		python3 ./bin/sdat2img.py zip_temp/"${part[$i]}.transfer.list" zip_temp/"${part[$i]}.new.dat" "${part[$i]}.img"
		echo "extract "${part[$i]}.img" : done"
	done
	getszie
	if [[ -f "$bro/dynamic_partitions_op_list" ]]; then
		for ((i = 0 ; i < 2 ; i++)); do
		sed -i "s/${part_size[$i]}/"${part[$i]}_size"/g" "$bro/dynamic_partitions_op_list"
		done
	fi
}
######################
mkrw()
{
echo "#############################"
echo "#       READ-WRITE ....     #"
echo "#############################"
echo ""
echo "Get Parttion size ...."
echo ""
getszie
echo "Resize Parttion ...."
for ((i = 0 ; i < 2 ; i++)); do
	size=$(echo "${part_size[$i]} + 50000000" | bc)
	size1=$(echo "$size / 1024" | bc)
	echo "new "${part[$i]}.img" is : $size"
	e2fsck -f "${part[$i]}.img"
	resize2fs "${part[$i]}.img" $size1
done
echo ""
echo "Start remove Read-Only ...."
for ((i = 0 ; i < 2 ; i++)); do
	e2fsck -y -E unshare_blocks "${part[$i]}.img"
	echo ""${part[$i]}.img" : done"
done
}
##########
mount()
{
echo "#############################"
echo "#        Mounting ....     #"
echo "#############################"
echo ""
echo "Enter your password to use Sudo ...."
for ((i = 0 ; i < 2 ; i++)); do
	mkdir temp/"${part[$i]}"
	sudo mount "${part[$i]}.img" temp/"${part[$i]}"
done
}
########
debloat()
{
cd $dir
echo "#############################"
echo "#       Debloating ....     #"
echo "#############################"
echo ""
echo "Debloating ...."
###########
sys=`cat $dir/module/debloat/system.txt`
ven=`cat $dir/module/debloat/vendor.txt`
echo "In System : "
cd $dir/temp/system/system
  for app in $sys; do
        sudo rm -rf "$app" 2>/dev/null
        echo "done"
  done
echo "In Vendor : "
cd $dir/temp/vendor
  for app in $ven; do
        sudo rm -rf "$app" 2>/dev/null
        echo "done"
  done
}
#########
#########
umount()
{
echo "#############################"
echo "#        Unmounting ....    #"
echo "#############################"
echo ""
cd $dir/temp
sleep 3
for ((i = 0 ; i < 2 ; i++)); do
	sudo umount "${part[$i]}"
	echo "Umount "${part[$i]}" :  done"
	sleep 3
done
}
##########
shrink ()
{
echo "#############################"
echo "#        Shrinking ....     #"
echo "#############################"
echo ""
cd $dir
sleep 1
for ((i = 0 ; i < 2 ; i++)); do
	resize2fs -f -M "${part[$i]}.img"
	echo "Shrink "${part[$i]}" :  done"
done
echo "Expan system size for gboard .... "
cd $dir
e2fsck -f system.img -y
dd if=/dev/zero bs=1M count=200 >> system.img
resize2fs system.img
getszie
if [[ -f "$bro/dynamic_partitions_op_list" ]]; then
	for ((i = 0 ; i < 2 ; i++)); do
	sed -i "s/"${part[$i]}_size"/"${part_size[$i]}"/g" "$bro/dynamic_partitions_op_list"
	done
fi
}
cleanup()
{
	cd $dir
	if [[ -d "temp" ]]; then
		rm -r temp
		rm -r zip_temp
	fi
}
remove_source()
{
echo "#############################"
echo "#  remove source file ....   #"
echo "#############################"
echo ""
cd $dir/zip_temp
rm firmware-update/vbmeta.img
	for ((i = 0 ; i < 2 ; i++)); do
		if [[ -f "${part[$i]}.new.dat.br" ]]; then
			rm "${part[$i]}.new.dat.br"
			rm "${part[$i]}.new.dat"
			rm "${part[$i]}.patch.dat"
			rm "${part[$i]}.transfer.list"
		fi
	done
cd ..
}
permis()
{
  sudo chmod 644 $1
  sudo chown root $1
  sudo chgrp root $1
  echo "Set permission of $1 : done "
}
vietsub()
{
echo "#############################"
echo "#       VIETSUB-ING ....    #"
echo "#############################"
echo ""
	cd $dir/module
	echo "copy bhlnk's overlay and stuff"
for ((i = 0 ; i < 3 ; i++)); do
	mkdir "${module[$i]}_f"
	sudo mount "${module[$i]}.img" "${module[$i]}_f"
done
	echo "Adding Vietnamese Language"
	sudo cp -arf vietsub_f/overlay/. $dir/temp/vendor/overlay
  sudo cp -rf "thermal-normal.conf" $dir/temp/vendor/etc
  permis "$dir/temp/vendor/etc/thermal-normal.conf"
	sudo cp -rf "miui.apk" $dir/temp/system/system/app/miui
	permis "$dir/temp/system/system/app/miui/miui.apk"
	echo "Adding Roboto Fonts"
	sudo cp -arf fonts_f/system/fonts/. $dir/temp/system/system/fonts
	echo "Adding Crack Theme from https://yukongya.herokuapp.com"
	sudo cp -arf theme_f/system/app/MIUIThemeManager/. $dir/temp/system/system/app/MIUIThemeManager
	echo "done"

  for ((i = 0 ; i < 3 ; i++)); do
  	sudo umount "${module[$i]}_f"
  	rm -rf "${module[$i]}_f"
  done
	cd $dir
}
buildprop()
{
cd $dir/temp
cd system/system
sudo sed -i '/ro.product.locale/c\ro.product.locale=vi-VN' build.prop
sudo sed -i '/ro.miui.has_security_keyboard/c\ro.miui.has_security_keyboard=0' build.prop
sudo sed -i '$ a ro.miui.backdrop_sampling_enabled=true' build.prop
sudo sed -i '$ a persist.sys.allow_sys_app_update=true' build.prop
cd $dir/temp
cd vendor
sudo sed -i '/ro.vendor.cabc.enable/c\ro.vendor.cabc.enable=false' build.prop
sudo sed -i '/ro.vendor.bcbc.enable/c\ro.vendor.bcbc.enable=false' build.prop
sudo sed -i '/ro.vendor.dfps.enable/c\ro.vendor.dfps.enable=false' build.prop
sudo sed -i '/ro.vendor.smart_dfps.enable/c\ro.vendor.smart_dfps.enable=false' build.prop
sudo sed -i '$ a persist.sys.allow_sys_app_update=true' build.prop
}
repackz()
{
echo "#############################"
echo "#         Compress          #"
echo "#############################"
echo ""
echo "Compress to sparse img .... "
for ((i = 0 ; i < 2 ; i++)); do
  echo "Compress "${part[$i]}.img" "
	img2simg "${part[$i]}.img" "s_${part[$i]}.img"
done
echo "Compress to new.dat .... "
for ((i = 0 ; i < 2 ; i++)); do
	echo "- Repack ${part[$i]}.img"
 	python3 ./bin/linux/img2sdat.py "s_${part[$i]}.img" -o $bro -v 4 -p "${part[$i]}"
done

#level brotli
echo "Compress to brotli .... "
#
for ((i = 0 ; i < 2 ; i++)); do
   	echo "- Repack ${part[$i]}.new.dat"
	brotli -6 -j -w 24 "$bro/${part[$i]}.new.dat" -o "$bro/${part[$i]}.new.dat.br"
	rm -rf "${part[$i]}.img"
	rm -rf "s_${part[$i]}.img"
	rm -rf "$bro/${part[$i]}.new.dat"
done
if [ -d $bro/META-INF ]; then
	echo "- Zipping"
	cp "$dir/bin/vbmeta.img" $bro
	[ -f ./MIUI_VIETSUB.zip ] && rm -rf ./MIUI_VIETSUB.zip
	$bin/7za a -tzip "$dir/MIUI_VIETSUB.zip" $bro/*  
fi
if [ -f "$dir/MIUI_VIETSUB.zip" ]; then
      echo "- Repack done"
else
      echo "- Repack error"
fi
}
cleanup
echo "#############################"
echo "#         STARTING ....     #"
echo "#############################"
echo ""
read -p "Press [Enter] key to start modify..."
if [[ -f "$input" ]]; then
	echo "Zip rom detect"
	zipfile
elif [[ -f "super.img" ]]; then
	echo "Super.img detect"
else exit 0
fi
mkrw
mount
###############
debloat
vietsub
buildprop
#read -p "Press [Enter] key to start modify..."
umount
shrink
remove_source
repackz
