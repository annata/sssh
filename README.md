# sssh
用于debian9的shadowsocks翻墙脚本
其他的基于debian的发行版或者debian旧版本待测试，非基于debian的发行版暂时不可用
ubuntu16.04LTS，ubuntu18.04LTS已经测试可用

update 2018/11/02
增加对centos 7 的支持，fedora 与 centos 6 未做测试。

- 开始
```
apt install -y git
git clone https://github.com/annata/sssh.git
cd sssh
chmod 755 ss.sh
./ss.sh create 123.123.123.123 9001 aes-256-cfb sdhywfygb324234b  #只是示例自行修改成自己的ss服务器
```

- 用法

```
开始翻墙或者更新翻墙信息：ss.sh+create+ss服务器ip+ss服务器端口+加密方法+密码，示例:
ss.sh create 123.123.123.123 9001 aes-256-cfb sdhywfygb324234b


运行失败或者需要再次修改信息可以直接再次运行即可


取消翻墙，复原所有更改，示例：
ss.sh remove

如果需要根据亚洲路由表更新中国ip列表的话，将第44行和第45行注释的#删掉即可
```

- 注意

```
1.本脚本将会占用 tcp 1080   tcp 1090  udp53   端口，运行前自行确认端口是否被占用
2.使用ss.sh create由于某些原因安装失败以后（例如端口被占用，输入的参数错误等等），可能会导致网络无法连接，再次运行ss.sh create时由于网络无法连接无法安装成功，此时可以先运行ss.sh remove复原所有更改，再次运行ss.sh create即可
3.ss.sh create相同参数下具有幂等性，可以多次运行ss.sh create
4.ss.sh create运行成功后启动的进程和代理在重启以后不会自动重启，请自行将ss.sh带上参数放入启动脚本里
5.ubuntu由于systemd-resolved会占用udp 53端口，所以本脚本会停止systemd-resolved服务，如果你不知道systemd-resolved是什么，可以无视
6.本脚本将会修改 /etc/resolv.conf 中的内容，可能会影响相关依赖的服务（例：kubernetes中的 coredns 服务会不断重启）
```


- 原理

```
本脚本做了以下几件事情：
1.通过apt安装ss和一些依赖
2.启动ss的tunnel作udp代理用来代理dns请求，占用tcp端口1080
3.启动ss的redir作tcp代理用来代理tcp请求，占用tcp端口1090
4.检测，不存在则下载安装chinadns用来进行dns检测，如果是被墙域名将会走上面的ss-tunnel，本国域名直连，占用udp端口53
5.备份本机的域名解析/etc/resolv.conf,并将域名解析服务器设置为127.0.0.1,即本机使本机的域名解析走本机的udp53端口
6.修改iptables和ipset对ip进行区分，本地ip或者国内ip直连，国外ip的tcp流量会被重定向到上述的ss-redir
```
