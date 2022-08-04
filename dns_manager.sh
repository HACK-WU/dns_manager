#!/usr/bin/bash

set -u

named_conf="/etc/named.conf"
named_rfc_zones="/etc/named.rfc1912.zones"
var_named_path="/var/named/"

if [ !  -f "$named_conf".bak ];then
	echo -e  "\033[31m$named_conf.bak 文件不存在，请手动创建，并保证$named_conf.bak 文件为原始配置文件。\033[0m"
	exit
fi  		#备份原配置文件

if [ !  -f "$named_rfc_zones".bak ];then
	echo -e  "\033[31m$named_rfc_zones.bak 文件不存在，请手动创建，并保证$named_rfc_zones.bak 文件为原始配置文件。\033[0m"
	exit
fi  		#备份原配置文件

cp -p "$named_conf".bak  "$named_conf"	#重置配置文件
cp -p "$named_rfc_zones".bak  "$named_rfc_zones"	#重置配置文件
echo -e "\033[33m配置文件重置成功\033[0m"
##############################  named_conf配置文件    #####################
function  conf {			#修改named_conf访问控制配置文件。
	[ -f $named_conf ]|| echo  -e   "\033[31m出错,$named_conf 文件不存在!!!\033[0m"
	local option="any;"
	sed  -i  "s/\(53\s\){.*}/\1{ $option }/g" $named_conf
	sed  -i  "s/\(allow-query.*\){.*}/\1{ $option }/g" $named_conf
}

function view {		#用于配置dns分离解析
	#参数：
	#	$1: lan，局域网网段
	#	$2: wan,广域网网段，建议使用any


	local res=$(grep  -E -c  "^zone.*IN " $named_conf)
	if [ $res -ne 0 ];then
	
	local num1=$(grep  -E -n  "^zone.*IN " $named_conf|cut -d ":" -f1)
	local num2=$(( num1+3 ))
	sed  -i "$num1,$num2 d" $named_conf		#删除zone原配置
	fi

	local lan=$1
	local wan=$2

local view_lan="
view lan {
        match-clients { $lan; };
        zone \".\" IN {
                type hint;
                file \"named.ca\";
        };
        include \"/etc/lan.zones\";
};"


local view_wan="
view wan {
        match-clients { $wan; };
        zone \".\" IN {
                type hint;
                file \"named.ca\";
        };
        include \"/etc/wan.zones\";
};"
	res=$(grep -E -c  "include.*root.key" $named_conf)	
	if [ $res -ne 0 ];then
	num1=$(grep -E  -n  "include.*root.key" $named_conf|cut -d ":" -f1 )
	num2=$((num1-1 ))
	sed -i "$num2,$num1 d" $named_conf
	fi

	echo "$view_lan" >> $named_conf
	echo "$view_wan" >> $named_conf

}
############################ named_zones	###################################33
domain=null	#域名
A_PTR=null
function zones { 	
	#参数： 
	#	$1,置为A后者PTR，表明是反向解析还是正向解析
	#	$2,需要解析的域名,或者ip网段
	#	$3,需要修改的文件 ; 
	#	$4,type的值，为master/slave 可以省略，默认为master
	#	$5,master的地址，如果$4为slave，则必须有$5参数
	
	domain="$2"
	local file="$domain"zone
	A_PTR="A"
	domain2=null
	if [ "$1" == "PTR"  ];then
		local domain2=$(echo "$domain"| awk  -F "."  '{printf $3"."$2"."$1 "\n"  } ')
		A_PTR="PTR"
	fi

	local allow="allow-update { none; };"
	
	set +u
	if [ -z $4 ];then 
		local type1="master"
	else
		local type1=$4	#设置type的默认值为master
		allow="masters { $5; };"
	fi
	set -u	
	
		

set +u
local dom_zone="
zone \"$domain\" IN {
        type $type1;
        file \"$file\";
        $allow
};
"

local ip_zone="
zone \"$domain2.in-addr.arpa\" IN {
        type $type1;
        file \"$file\";
        $allow
};
"
set -u
	[ "$1" == "PTR" ] && echo "$ip_zone" >> $3 || echo "$dom_zone" >> $3
}

#zones PTR  192.168.23  $named_rfc_zones
##############################  var_zone ############################################
master_slave=null
file_path=null	#zone文件的路径	

function var_zone {	
	#参数： 
	#	$1,值为二级域名的名称，比如：hackwu.cn. ,不可以省略。
	#	$2,值为lan/wan，表示是匹配局域网还是广域网，可以省略，默认为no，表示不开启分离解析
	#	$3,值为master/slave,表示此服务是主服务器还是从服务器，可以省略，默认为master

	local domain="$1"zone	

	set +u
	if [[ -z $3 && -n $2 ]];then
		case $2 in 
		lan)	local lan_wan=lan  ;;
		wan)    local lan_wan=wan ;;
		master) local master_slave=master ;;
		slave)	local master_slave=slave ;;
		*)	echo -e "\033[31m参数错误\033[0m" ;;
		esac
	
		[ -z $lan_wan ] && local lan_wan=no
		[ -z $master_slave ] && local master_slave=master
	else	
		[ -z $2 ] && local lan_wan=no||local lan_wan=$2
		[ -z $3 ] && local master_slave=master || master_slave=$3		
	fi
	set -u	
		
	if [ "$lan_wan" != "no"  ];then				#判读是否开启分离解析，然后设置文件的相对路径
		local relative_path="$lan_wan/$domain"
	else
		local relative_path="$domain"
	fi
		

	if [ "$master_slave" == "slave"  ];then			#判断是主服务器还是从服务器，然偶设置文件的绝对路径
		file_path="$var_named_path"slaves/$relative_path
	else
		file_path="$var_named_path"$relative_path	
		
	fi

	local dir_path=${file_path%/*}			
	local var_named_path2=${var_named_path%/*}

	if [[ "$dir_path" != "$var_named_path" && "$dir_path" != "$var_named_path2" ]];then
		mkdir -p $dir_path 
		chown named:named $dir_path 
		echo -e "\033[33m目录授权完毕\033[0m"
		ls -l $dir_path -d
	fi
	touch $file_path ;
	chown :named $file_path
	echo -e "\033[33mzone文件授权完毕\033[0m"
	ls -l $file_path 	
	
}

function input_zone {	
	#参数： $@  里面封装了多对参数，每队参数由一个三级域名和一个ip组成

	local dom=$domain
	
	if [ "$A_PTR" == "PTR"  ];then
		echo "$@"
		dom=$(echo "$@" | awk '{ print $2 }'| awk -F "." '{print $2"."$3"."}')
	fi	
	
local str="\$TTL 1D
@       IN SOA  $dom rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      dns.com."
	echo  -e "$str" > $file_path
	
	local str="dom     $A_PTR       ip"
	local num=0
	local third_domain=null
	local ip=null
	for item in $@
	do
		
		let num2=num%2
		if [ $num2 -eq 0  ] ;then
			third_domain=$item
			
		else
			ip=$item
			if [ "$A_PTR" == "PTR"  ];then
				[[ "$ip" =~ \.$ ]]|| ip=$ip.
       			fi

			echo   $(echo "$str"| sed -e "s/dom/$third_domain/g;s/ip/$ip/g ") >> $file_path
		fi
		let num++
		
	done
	


}

#conf
#zones A  hackwu.cn.  $named_rfc_zones
#var_zone $domain
#input_zone www	192.168.23.10  hello 192.168.20.13

#conf 
#zones PTR  192.168.20. $named_rfc_zones
#var_zone $domain
#input_zone 12 www.hackwu.cn.  45 hello.hackwu.cn.

#conf
#zones A  hackwu.cn.  $named_rfc_zones slave 192.168.23.12
#var_zone $domain wan slave
#input_zone www	192.168.23.10  hello 192.168.20.13

#conf
#view  192.168.23.0/24    any
#zones A  hackwu.cn.  $named_rfc_zones 
#var_zone $domain lan 
#input_zone www	192.168.23.10  hello 192.168.20.13
#var_zone $domain wan
#input_zone www 192.168.10.10 hello 192.168.20.20

function start {
	if systemctl status named &>/dev/null ;then
		systemctl restart named
	else
		systemctl start named
	fi
	echo "named 服务启动成功！！"
}

function A {
	local dom=$(whiptail --title "二级域名设置" --inputbox "请输入二级域名，比如：hackwu.cn." 10 60  3>&1 1>&2 2>&3)
	[[ "$dom" =~ ^[a-zA-Z0-9]+\.[a-z]+$  ]]&& dom=$dom.
	[[ "$dom" =~ ^[a-zA-Z0-9]+\.[a-z]+\.$  ]] || echo "域名格式错误！"
	zones A $dom $named_rfc_zones
	var_zone $domain
	local thrid_dom=$(whiptail --title "三级域名解析设置" --inputbox "请输入三级域名，以及对应的ip，比如:wwww 192.168.23.10 ,可以有多组" 10 60  3>&1 1>&2 2>&3)	
	input_zone $thrid_dom	
	echo  -e  "\033[33m正向解析配置完成\033[0m"
	whiptail --title "配置成功" --msgbox "正向解析配置完成" 10 60	
	
}

function PTR {
        local ip=$(whiptail --title "ip网段设置" --inputbox "请输入一个ip网段，比如：192.168.23." 10 60  3>&1 1>&2 2>&3)
        [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+$  ]]&& ip=$ip.
        [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.$  ]] || echo "ip网段格式错误！"

        zones PTR $ip  $named_rfc_zones
        var_zone $domain
        local host_dom=$(whiptail --title "反向解析配置" --inputbox "请输入网络号和完整域名，比如:12 www.hackwu.cn. ,可以有多组" 10 60  3>&1 1>&2 2>&3)
        input_zone $host_dom
	echo  -e  "\033[33m反向解析配置完成\033[0m"
	whiptail --title "配置成功" --msgbox "反向解析配置完成" 10 60	

}

function dns_common {
	echo "通用配置"	
while  :
do
    local OPTION=$(whiptail --title "通用配置" --menu "YES: 确定，NO: 保存退出" 15 60 2\
    "1" "正向解析" \
    "2" "反向解析"  3>&1 1>&2 2>&3)
     
    exitstatus=$?
    if [ $exitstatus  -eq  0 ]; then
	conf
	case $OPTION in
	1)A   ;;
	2)PTR ;;
	*) break ;;
	esac
    else
	break
    fi
done
		
}




function man {
	OPTION=$(whiptail --title "DNS服务管理" --menu "请选择以下功能：" 15 60 3 \
	    "1" "DNS通用配置" \
	    "2" "DNS分离解析配置" \
	    "3" "DNS主从服务器配置" 3>&1 1>&2 2>&3)
     
	    exitstatus=$?
	    if [ $exitstatus  -eq  0 ]; then
	        echo "Your favorite programming language is" $OPTION
	    else
	        echo "You chose Cancel."
	    fi
}

dns_common
start
echo "finshed"



