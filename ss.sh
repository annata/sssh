#!/bin/bash
# author:annata
# url:https://github.com/annata/sssh
. /etc/profile

set -e

usage(){
	echo -e '开始翻墙或者更新翻墙信息：ss.sh+create+ss服务器ip+ss服务器端口+加密方法+密码，示例:\nss.sh create 123.123.123.123 9001 aes-256-cfb sdhywfygb324234b\n取消翻墙，复原所有更改：\nss.sh remove';
}
sstunnel(){
	sstunnelpid=`ps -ef|grep ss-tunnel|grep -v grep|awk '{print $2}'`
	if [ ! -z $sstunnelpid ]
	then
		kill $sstunnelpid
	fi
	ss-tunnel -c /etc/shadowsocks-libev/udp.json -L "8.8.8.8:53" -u -f "/root/.sscnf/ss-tunnel.pid"
	echo '创建udp包代理进程成功！'
}
ssredir(){
	ssredirpid=`ps -ef|grep ss-redir|grep -v grep|awk '{print $2}'`
	if [ ! -z $ssredirpid ]
	then
		kill $ssredirpid
	fi
	ss-redir -c /etc/shadowsocks-libev/tcp.json -f "/root/.sscnf/ss-redir.pid"
	echo '创建tcp包透明代理进程成功！'
}
chinadns(){
	if [ ! -e /root/.sscnf/chinadns-1.3.2/src/chinadns ]
	then
		if [ ! -e $DIR/chinadns-1.3.2.tar.gz ]
		then
			wget -O /root/.sscnf/chinadns-1.3.2.tar.gz --no-check-certificate https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz
		else
			cp -f $DIR/chinadns-1.3.2.tar.gz /root/.sscnf/chinadns-1.3.2.tar.gz
		fi
		cd /root/.sscnf
		tar zxvf chinadns-1.3.2.tar.gz
		cd chinadns-1.3.2
		./configure
		make
	fi
	# curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /root/.sscnf/chinadns-1.3.2/chnroute.txt
	# echo '更新中国ip列表成功！'
	cd /root/.sscnf/chinadns-1.3.2

	chinadnspid=`ps -ef|grep chinadns|grep -v grep|awk '{print $2}'`
	if [ ! -z $chinadnspid ]
	then
		kill $chinadnspid
	fi
	nohup /root/.sscnf/chinadns-1.3.2/src/chinadns -m -c chnroute.txt -s 223.5.5.5,127.0.0.1:1080 &
	echo '启动chinadns成功！'
}
updateresolv(){
	if [ ! -e /etc/resolv.conf.ss.bak ]
	then
		mv /etc/resolv.conf /etc/resolv.conf.ss.bak
	fi
	echo 'nameserver 127.0.0.1' > /etc/resolv.conf
}
createipsetandiptables(){
	iptables -t nat -D OUTPUT -p tcp -j shadowsocks || true

	iptables -t nat -F shadowsocks || true
	iptables -t nat -X shadowsocks || true
	ipset destroy shadowsocks || true
	ipset create shadowsocks hash:net
	ipset add shadowsocks 10.30.30.0/24
	cat /root/.sscnf/chinadns-1.3.2/chnroute.txt | awk '{print "ipset add shadowsocks "$0}' | sh
	iptables -t nat -N shadowsocks
	iptables -t nat -A shadowsocks -d $ip/32 -j RETURN
	iptables -t nat -A shadowsocks -d 0.0.0.0/8 -j RETURN
	iptables -t nat -A shadowsocks -d 10.0.0.0/8 -j RETURN
	iptables -t nat -A shadowsocks -d 127.0.0.0/8 -j RETURN
	iptables -t nat -A shadowsocks -d 169.254.0.0/16 -j RETURN
	iptables -t nat -A shadowsocks -d 172.16.0.0/12 -j RETURN
	iptables -t nat -A shadowsocks -d 192.168.0.0/16 -j RETURN
	iptables -t nat -A shadowsocks -d 224.0.0.0/4 -j RETURN
	iptables -t nat -A shadowsocks -d 240.0.0.0/4 -j RETURN
	iptables -t nat -A shadowsocks -m set --match-set shadowsocks dst -j RETURN
	iptables -t nat -A shadowsocks -p tcp -j REDIRECT --to-ports 1090

	iptables -t nat -A OUTPUT -p tcp -j shadowsocks
	echo '创建iptables规则成功！'
}
create(){
	if [[ -z $ip || -z $port || -z $method || -z $pass ]]
	then
		usage
		exit 1
	fi
	service systemd-resolved stop || true
	apt install -y wget curl make gcc ipset shadowsocks-libev || true
	service shadowsocks-libev stop || true
	systemctl disable shadowsocks-libev.service || true
	echo -e "{\"server\":\"$ip\",\"server_port\":$port,\"local_port\":1080,\"password\":\"$pass\",\"timeout\":60,\"method\":\"$method\"}" > /etc/shadowsocks-libev/udp.json
	echo -e "{\"server\":\"$ip\",\"server_port\":$port,\"local_port\":1090,\"password\":\"$pass\",\"timeout\":60,\"method\":\"$method\"}" > /etc/shadowsocks-libev/tcp.json
	if [ ! -d /root/.sscnf ]
	then
		mkdir /root/.sscnf
	fi
	sstunnel
	ssredir
	chinadns
	updateresolv
	createipsetandiptables

	echo '翻墙成功！'
}
remove(){
	iptables -t nat -D OUTPUT -p tcp -j shadowsocks || true

	iptables -t nat -F shadowsocks || true
	iptables -t nat -X shadowsocks || true
	ipset destroy shadowsocks || true
	if [ -e /etc/resolv.conf.ss.bak ]
	then
		rm -f /etc/resolv.conf || true
		mv /etc/resolv.conf.ss.bak /etc/resolv.conf
	fi
	chinadnspid=`ps -ef|grep chinadns|grep -v grep|awk '{print $2}'`
	if [ ! -z $chinadnspid ]
	then
		kill $chinadnspid
	fi
	ssredirpid=`ps -ef|grep ss-redir|grep -v grep|awk '{print $2}'`
	if [ ! -z $ssredirpid ]
	then
		kill $ssredirpid
	fi
	sstunnelpid=`ps -ef|grep ss-tunnel|grep -v grep|awk '{print $2}'`
	if [ ! -z $sstunnelpid ]
	then
		kill $sstunnelpid
	fi
	rm -rf /root/.sscnf || true
	apt remove -y shadowsocks-libev
	apt autoremove -y
	echo '取消翻墙，复原所有更改成功！'
}
if [ `id -u` != "0" ]
then
	echo '必须是root权限'
	exit 1
fi
source /etc/os-release
case $ID in
debian|ubuntu|devuan)
    echo $ID
	;;
centos|fedora|rhel)
    echo '不支持该发行版'
    exit 1
	;;
*)
	echo '不支持该发行版'
    exit 1
    ;;
esac
if [ "$1" == "create" ]
then
	ip="$2"
	port="$3"
	method="$4"
	pass="$5"
	DIR="$( cd "$( dirname "$0"  )" && pwd  )"
	create
else 
	if [ "$1" == "remove" ] 
	then
		remove
	else
		usage
	fi
fi