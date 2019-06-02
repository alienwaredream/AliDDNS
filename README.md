下载地址：
最新版本：https://ilemonrain.com/download/shell/AliDDNSv2.sh

AliDDNS 2.0 部署教程

脚本整体不需要做任何修改！如果你不理解AliDDNS 2.0的运行原理，请不要擅自改动！因乱改脚本核心导致运行崩溃，作者有权拒绝回答任何问题！
首先，登录你的服务器，安装必需组件：

For CentOS：

yum install -y wget curl cronie
For Debian 8+：

apt install -y wget curl cron
For Ubuntu/Debian 7：

apt-get install -y wget curl cron
然后下载AliDDNS脚本到你的服务器上：

wget -O /usr/sbin/AliDDNS-v2.0.sh https://ilemonrain.com/download/shell/AliDDNSv2.sh
下载地址请参考上面的 更新记录 & 下载地址 一节！
为脚本文件加上可执行属性：

chmod +x /usr/sbin/AliDDNS-v2.0.sh
执行脚本，开始配置：

/usr/sbin/AliDDNS-v2.0.sh
弹出启动菜单：

AliDDNS 工具 (阿里云云解析修改工具)

使用方法 (Usage)：
AliDDNS.sh run 配置并运行工具 (如果已有配置将会直接运行)
AliDDNS.sh config 仅配置工具
AliDDNS.sh clean 清理配置文件及运行环境
AliDDNS.sh version 显示版本信息

[Info] 选择你要使用的功能:

配置并运行 AliDDNS
仅配置 AliDDNS
清理环境
退出
输入数字以选择: _

在这里，我们输入 1 (数字1) ，后按下回车，开始进入AliDDNS配置向导：

[Info] 请输入一级域名 (比如 example.com)
(此项必须填写，查看帮助请输入“h”):
假如你需要设置AliDDNS的域名为ddns.example.com，那么请在这里输入 example.com

分解开就是 [ddns] . [example.com]

同时，登录阿里云云解析 https://dns.console.aliyun.com/，在需要DDNS的域名上，添加一个记录：

记录类型：A
主机记录：[请填写你的二级域名]
解析线路：默认
记录值：127.0.0.1 (或者随便填写一个IP地址)
TTL： [请根据实际需要选择合适的TTL]
同步默认线路：是 (勾选)
简单粗暴的，看都不看的复制粘贴，作者也有权拒绝回答任何问题！
完成后按下回车键，继续填写二级域名：

[Info] 请输入二级域名 (比如 ddns)
(此项必须填写，查看帮助请输入“h”):
同上面的范例，我们输入 ddns ，之后按下回车键继续：

[Info] 请输入记录的TTL(Time-To-Live)值：
(默认为600，查看帮助请输入“h”):
如果你使用的是免费版的阿里云云解析，此处可以填写的数值范围为：600~86400；
如果你使用的是收费版(企业版)的阿里云云解析，此处可以填写的数值范围为：1~86400 (根据你购买的产品类型决定)。

填写完成后，按下回车键继续：

[Info] 请输入阿里云AccessKey ID
(此项必须填写，查看帮助请输入“h”):
AccessKey ID 和 AccessKey Secret 推荐使用 子用户AccessKey(访问控制台RAM) 分配的权限！这样最安全！

使用子用户AccessKey，请分配 AliyunDNSReadOnlyAccess(只读访问云解析(DNS)的权限) 和 AliyunDNSFullAccess(管理云解析(DNS)的权限) 这两个权限！推荐有动手能力的用户使用子用户AccessKey！

如果不会操作或者图省事，请使用 全局AccessKey ！但此时一定要注意！千万不要泄露你的全局AccessKey或者将你的全局AccessKey发布到公网上！这样等同于把你的号白送人，还可以名正言顺的白嫖你的阿里云账号！如果发生泄露，请立刻删除泄露的AccessKey！

填写完成后，按下回车键继续：

[Info] 请输入阿里云Access Key Secret
(此项必须填写，查看帮助请输入“h”):
同上，填写你的AccessKey ID对应的AccessKey Secret。获取你的AccessKey Secret属于账号高风险操作，请准备好用来接收阿里云验证码的手机！

填写完成后，新版的AliDDNS 2.0如果没有激活专家模式，会直接进入执行流程；如果启动了专家模式，以下参数请在你理解的基础上填写！否则请一律留空！

[Info] 请输入获取本机IP使用的命令
(查看帮助请输入“h”):
输入获取本机IP地址使用的命令。如果你不懂或者不需要配置，请留空，直接回车！

[Info] 请输入解析使用的DNS服务器
(此项必须填写，查看帮助请输入“h”):
输入nslookup命令解析使用的DNS服务器。如果你不懂或者不需要配置，请留空，直接回车！

之后，会自动开始DDNS(测试)运行过程：

[Info] 检测到存在的配置，自动读取现有配置
如果你不需要，请通过菜单中的清理环境选项进行清除
[Info] 正在写入配置文件……
[Info] 正在获取本机IP……
[Info] 本机IP：...
[Info] 正在获取 ddns.example.com 的IP……
[Info] 解析结果：ddns.example.com -> 127.0.0.1
[Info] 正在生成时间戳……
[Info] 获取到RecordID：*
[Info] 正在更新解析记录……
{"RecordId":"","RequestId":"----"}
[Info] 已经更新RecordID：*
[Success] DDNS记录更新成功，新的IP为：...

出现最后的 DDNS记录更新成功 提示，即为DDNS记录同步成功，稍后等待DNS解析生效，即可完成DDNS域名更换！

3. Crontab (定时任务) 部署教程
首先，在命令行执行命令：

crontab -e
会弹出一个提示，问选择哪个编辑器，请按照自己的喜好选择一个文本编辑器：

Select an editor. To change later, run 'select-editor'.

/bin/nano <---- easiest
/usr/bin/vim.basic
/usr/bin/vim.tiny
Choose 1-3 [1]:

选择完成后，会打开一个文本编辑器，请在文件的最后添加如下一行：

*/5 * * * * /usr/sbin/AliDDNS-v2.0.sh run >/dev/null 2>&1 &
添加完成后，保存退出。

当提示 crontab: installing new crontab 时，表示crontab写入成功，执行命令重启cron进程：

For CentOS：

service crond restart
For Ubuntu/Debian：

service cron restart
并将Cron加入开机启动项：

For CentOS：

chkconfig crond on
For Ubuntu/Debian：

systemctl enable cron
即可完成定时任务的部署。

4. 常见问题 FAQ
FAQ1：脚本是原创的嘛？遵循开源协议了嘛？
脚本核心是基于koolshare的aliddns脚本制作，在原有的基础上进行改动，以实现平台移植和更好的环境适应。开源协议是什么？好吃么？（也欢迎各位大佬给我科普下什么是GPL协议，还有其具体作用）

FAQ2：脚本目前保存在了哪里？以后会删库跑路嘛？
脚本目前保存在了BitBucket（因为GitHub同名账号不是本人），如果我不改ID或者彻底弃坑的话，我应该不会删项目（但当整个项目成熟到一定程度后，我会将项目的开发进入休眠期，也就是长时间不再进行新功能的开发，仅做BUG修改）

FAQ3：这个脚本需要修改脚本内容嘛？
不需要！甚至你不应该修改！（相对于2.0版本，1.0版本请作对应修改）请直接运行脚本即可，脚本已自带完善的配置向导

FAQ4：那AliDDNS 1.0版本以后会怎么处理？
我会逐步放弃开发AliDDNS 1.0版本，目前会修复所有BUG，直到稳定后，放弃1.0版本的开发，转而开发2.0版本以及接锅tcp-nanqinglang项目

(更多FAQ有待补充)

5. 联系作者 & BUG建议反馈 & 吃土求捐赠！
Telegram：https://t.me/ilemonrain
Telegram个人频道：https://t.me/ilemonrain_channel
捐赠方式：TG私信获取
