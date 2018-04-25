# sssh
用于debian9的shadowsocks番茄脚本


- 用法

```
开始翻墙或者更新翻墙信息：ss.sh+create+ss服务器ip+ss服务器端口+加密方法+密码，示例:
ss.sh create 123.123.123.123 9001 aes-256-cfb sdhywfygb324234b


运行失败或者需要再次修改信息可以直接再次运行即可


取消翻墙，复原所有更改，示例：
ss.sh remove

如果需要根据亚洲路由表更新中国ip列表的话，将第39行和第40行注释删掉即可
```



- 原理

```
本脚本做了以下几件事情：
1.通过apt安装ss和一些依赖
2.启动ss的tunnel作udp代理用来代理dns请求，占用端口1080
3.启动ss的redir作tcp代理用来代理tcp请求，占用端口1090
4.检测，不存在则下载安装chinadns用来进行dns检测，如果是被墙域名将会走上面的ss-tunnel，本国域名直连
5.修改iptables和ipset对ip进行区分，本地ip或者国内ip直连，国外ip的tcp流量会被重定向到上述的ss-redir
```
