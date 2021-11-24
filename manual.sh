#!/bin/bash
part=(system vendor)
dir=$(pwd)
bin="$dir/bin/linux"
bro="$dir/zip_temp"
mkdir manual
if [[ $1 == "-u" ]]; then
  echo "Manual unpack brotli to ext4"
  for ((i = 0 ; i < 2 ; i++)); do
		brotli --decompress "$2.new.dat.br" -o manual/"$2.new.dat"
		python3 ./bin/sdat2img.py "$2.transfer.list" manual/"$2.new.dat" "$2.img"
		echo "extract "$2.img" : done"
	done
	getszie
  cd manual
  touch dynamic_partitions_op_list
	if [[ -f "dynamic_partitions_op_list" ]]; then
		for ((i = 0 ; i < 2 ; i++)); do
		echo "luoi qua "
		done
	fi
fi

if [[ $1 == "-r" ]]; then
  echo "#############################"
  echo "#         Compress          #"
  echo "#############################"
  echo ""

  echo $(find "$2.img" -printf "%s") >> "$2.txt"
  echo "Compress to sparse img .... "
  echo "Compress "$2.img" "
  img2simg "$2.img" "s_$2.img"
  echo "Compress to new.dat .... "
  echo "- Repack $2.img"
  python3 ./bin/linux/img2sdat.py "s_$2.img" -o $dir -v 4 -p "$2"
  echo "Compress to brotli .... "
  	echo "- Repack $2.new.dat"
  	brotli -6 -j -w 24 "$2.new.dat" -o "$2.new.dat.br"
  	rm -rf "$2.img"
  	rm -rf "s_$2.img"
  	rm -rf "$2.new.dat"
fi
