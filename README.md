# 1、DNS图形化管理工具 (dns_manager.sh)



​	**DNS图形化管理工具，可以很轻松的实现DNS服务的相关配置，无需手动更改配置文件即可轻松使用**

**此工具可以实现以下功能**

* **DNS基本功能**
* **智能DNS，分离解析功能**
* **DNS主从服务配置功能**

![image-20220805215619435](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805215619435.png)



# 2、运行环境

* **Centos 7.6**



# 3、使用前准备

* 下载DNS软件

  ```shell
  yum install -y bind
  ```

* 备份配置文件

  ```she
  cp /etc/named.conf{,.bak}
  cp /etc/named.rfc1912.zones{,.bak}
  ```

* 脚本授权

  ```she
  chmod a+x dns_manager.sh
  ```



# 4、DNS 通用配置

​		此页面可以实现DNS的基本功能，可以选择是进行正向解析配置，还是反向解析配置，当配置完成后，会返回此页面

可以选择继续配置，或者选择no保存退出此页面。

![image-20220805220518464](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805220518464.png)



## 4.1正向解析

 	1.  在表单中，输入你需要解析的域名，注意仅仅只是二级域名和顶级域名部分。比如：hackwu.cn.然后回车即可。

![image-20220805220918835](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805220918835.png)



 ## 通用域名配置解析

这部分就是，设置你的具体的域名需要解析成的ip地址。比如：

   * www.hakcwu.cn.  	192.168.23.10
   * home.hackwu.cn.     192.168.1.10

以上就是对应不同域名需要解析成的ip地址。

**这样这需要在以下表单中，输入三级域名 以及对应的ip地址即可。然后回车**

![image-20220805221545258](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805221545258.png)

![image-20220805221627925](C:/Users/29315/AppData/Roaming/Typora/typora-user-images/image-20220805221627925.png)



**保存退出之后，shell终端，会打印配置的相关信息**

![image-20220805221933066](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805221933066.png)

**这样简单的操作，一个基本的DNS服务及配置完成了**

**同理反向解析的操作，也基本是这样**



# 5、DNS分离解析配置

DNS分离解析配置，就是配置当不同网段访问DNS服务器时，DNS对相同的域名，却解析出不同的IP地址。这个一般分为局域网和广域网。

DNS分离解析配置，和通用配置差不多，只不过需要告诉服务器，局域网的网段，广域网网段，一般使用any即可。表示任意网段。

![image-20220805222320749](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805222320749.png)

然后后面的操作，需要分别填写局域网和广域网，的不同的解析ip。具体操作和通用配置，基本一致。



# 6、DNS主从服务器配置

这项操作，需要分别在主服务器上和从服务器上运行此脚本。

## 6.1在主服务器上

需要事先配置DNS通用配置，或者DNS分离解析配置，然后在执行此操作

![image-20220805223002822](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/3029image-20220805223002822.png)

选择本机时主服务器，然后输入从服务器的IP地址即可。

![image-20220805223106825](https://xingqiu-tuchuang-1256524210.cos.ap-shanghai.myqcloud.com/30293029image-20220805223106825.png)



## 6.2 从服务器上

在主服务上配置完成后，直接在从服务器上选择主从服务器上配置。

然后选择对应的与主服务器上一致的操作。是通用配置还是分离解析配置，需要和主服务器上保持一致。

![image-20220805223416399](C:/Users/29315/AppData/Roaming/Typora/typora-user-images/image-20220805223416399.png)

然后后面输入与主服务器上一致的配置信息，即可完成配置。

**配置完成后，只需要将客户端的DNS服务地址，改成从服务器的地址即可。**


