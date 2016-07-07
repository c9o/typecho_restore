#!/bin/sh

function print_help(){
	echo 'Usage: $shell path_to_latest_archive dir_to_typecho'
}

function parse_db(){
	config_file=$2
	db_key=$1
	cat "$config_file" | grep -A 6 '$db' | grep '=>' | grep "$db_key" | awk -F "'" '{print $4}'
}

if [ "$#" -lt "2" ] 
then
	print_help
	exit 1
fi

latest=$1
te_dir=$2
cu_dir=`pwd`
rs_dir="$cu_dir/ForRestoreTypecho"
te_config="$te_dir/config.inc.php"
te_usr_dir="$te_dir/usr"

db_host=$(parse_db 'host' "$te_config")
db_port=$(parse_db 'port' "$te_config")
db_user=$(parse_db 'user' "$te_config")
db_pass=$(parse_db 'password' "$te_config")
db_name=$(parse_db 'database' "$te_config")

#echo "$db_host $db_port $db_user $db_pass $db_name"

## test and print

if [ ! -f ${latest} ]; then  
    echo "$latest is not latest backup archive!!"
    exit 2
fi

echo "latest.tar.gz locates in $latest"

if [ ! -d ${te_dir} ]; then  
    echo "$te_dir is not home of typecho!!"
    exit 2
fi

echo "Home of typecho is $te_dir"

## prepare

echo "Preparing..."
if [ ! -d ${rs_dir} ]; then
    mkdir -p $rs_dir
fi

cd $rs_dir
cp $latest . -rf
tar xf $latest

## check md5

echo "Checking md5..."
cp $rs_dir/tmp/database.sql /tmp/ -rf
cp $rs_dis/tmp/user.tar.gz /tmp/ -rf
md5sum -c $rs_dir/tmp/database.sql.md5sum
md5sum -c $rs_dir/tmp/user.tar.gz.md5sum

## restore usr
cd $rs_dir/tmp
tar xf user.tar.gz
cp -rf $rs_dir/tmp/home/wwwroot/www.bitbite.cn/usr $te_dir
cd $te_dir
chown www:www -R usr
rm usr/theme/Themia-for-TE -rf

## restore database

cd $rs_dir/tmp
sed -i "s/www.bitbite.cn/www.bitbite.xyz/g" database.sql
mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" "$db_name" < database.sql


## clean

cd $cu_dir
rm -rf $rs_dir
echo "Done. Bye!"
