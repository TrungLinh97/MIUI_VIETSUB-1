#!/bin/bash
echo "Starting donwload rom and auto run bhlnk script"
wget -q -O input.zip $1
./bhlnk.sh
