#!/bin/bash

# 更新日志
# Update 20180914 :
# [Fix] 再次修复: CPU 100%占用问题
#       这次找到了AliDDNS卡100%死循环的原因，并且加了一个小的检测机制，理论上应该不会再出现
#       CPU卡100%的问题了(如果有问题请私信脚本作者，谢谢！)

BuildTime="20180914"

# 专家模式开关
# 注意： 只有当你了解整个AliDDNS工作流程，并且有一定的动手能力，希望对AliDDNS脚本的更多参数进行
#       深度定制时，你可以打开这个开关，会提供更多可以设置的选项，但如果你不懂、超级小白，请不要
#       打开这个开关！因打开专家模式后配置失误发生的问题，作者不负任何责任！
#       如需打开专家模式，请将脚本文件中的 Switch_AliDDNS_ExpertMode 变量值设置为1，即可打开
#       专家模式，如需关闭，请将此值设置为0！
Switch_AliDDNS_ExpertMode="0"

# ===================================================================================
#
# 下面的代码均为程序的核心代码，请不要触动任何地方的代码，直接运行脚本即可使用！
#
# ===================================================================================

# Shell环境初始化
# 字体颜色定义
Font_Black="\033[30m"  
Font_Red="\033[31m" 
Font_Green="\033[32m"  
Font_Yellow="\033[33m"  
Font_Blue="\033[34m"  
Font_Purple="\033[35m"  
Font_SkyBlue="\033[36m"  
Font_White="\033[37m" 
Font_Suffix="\033[0m"
# 消息提示定义
Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Warning="${Font_Yellow}[Warning] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Fail="${Font_Red}[Failed] ${Font_Suffix}"
# Shell变量开关初始化
Switch_env_is_root="0"
Switch_env_curl_exist="0"
Switch_env_openssl_exist="0"
Switch_env_nslookup_exist="0"
Switch_env_sudo_exist="0"
Switch_env_system_release="none"
# AliDDNS组件-变量初始化
AliDDNS_DomainName=""
AliDDNS_SubDomainName=""
AliDDNS_TTL=""
AliDDNS_AK=""
AliDDNS_SK=""
AliDDNS_LocalIP=""
AliDDNS_DomainServerIP=""
# ServerChan组件-变量初始化
Switch_ServerChan_Enable="0"
ServerChan_SCKEY=""
ServerChan_Text=""
ServerChan_Content=""

# Shell脚本信息显示
echo -e "${Font_Green}
#=========================================================
# AliDDNS 工具 (阿里云云解析修改工具)
# 
# Build:    ${BuildTime}
# 支持平台:  CentOS/Debian/Ubuntu
# 作者:     iLemonrain (原作者: kyriosli/koolshare-aliddns)
# Blog:     https://blog.ilemonrain.com
# E-mail:   ilemonrain@ilemonrain.com
#========================================================

${Font_suffix}"

# 检查Root权限，并配置开关
function_Check_Root(){
	if [ "`id -u`" != "0" ]; then
        Switch_env_is_root="0"
    else
        Switch_env_is_root="1"
    fi
}

function_Check_Enviroment(){
    if [ -f "/usr/bin/curl" ]; then
        Switch_env_curl_exist="1"
    else
        Switch_env_curl_exist="0"
    fi
    if [ -f "/usr/bin/openssl" ]; then
        Switch_env_openssl_exist="1"
    else
        Switch_env_openssl_exist="0"
    fi
    if [ -f "/usr/bin/nslookup" ]; then
        Switch_env_nslookup_exist="1"
    else
        Switch_env_nslookup_exist="0"
    fi
    if [ -f "/usr/bin/sudo" ]; then
        Switch_env_sudo_exist="1"
    else
        Switch_env_sudo_exist="0"
    fi
    if [ -f "/etc/redhat-release" ]; then
        Switch_env_system_release="centos"
    elif [ -f "/etc/lsb-release" ]; then
        Switch_env_system_release="ubuntu"
    elif [ -f "/etc/debian_version" ]; then
        Switch_env_system_release="debian"
    else
        Switch_env_system_release="unknown"
    fi
}

function_Install_Enviroment(){
    if [ "${Switch_env_curl_exist}" = "0" ] || [ "${Switch_env_openssl_exist}" = "0" ] || [ "${Switch_env_nslookup_exist}" = "0" ]; then
        echo -e "${Msg_Warning}未检查到必需组件或者组件不完整，正在尝试安装……"
        if [ "${Switch_env_is_root}" = "1" ]; then
            if [ "${Switch_env_system_release}" = "centos" ]; then
                echo -e "${Msg_Info}检测到系统分支：CentOS"
                echo -e "${Msg_Info}正在安装必需组件……"
                yum install curl bind-utils openssl -y
            elif [ "${Switch_env_system_release}" = "ubuntu" ]; then
                echo -e "${Msg_Info}检测到系统分支：Ubuntu"
                echo -e "${Msg_Info}正在安装必需组件……"
                apt-get install curl dnsutils openssl -y
            elif [ "${Switch_env_system_release}" = "debian" ]; then
                echo -e "${Msg_Info}检测到系统分支：Debian"
                echo -e "${Msg_Info}正在安装必需组件……"
                apt-get install curl dnsutils openssl -y
            else
                echo -e "${Msg_Warning}系统分支未知，取消环境安装，建议手动安装环境！"
            fi
            if [ -f "/usr/bin/curl" ]; then
                Switch_env_curl_exist="1"
            else
                Switch_env_curl_exist="0"
                echo -e "${Msg_Error}curl组件安装失败！可能会影响到程序运行！建议手动安装！"
            fi
            if [ -f "/usr/bin/openssl" ]; then
                Switch_env_openssl_exist="1"
            else
                Switch_env_openssl_exist="0"
                echo -e "${Msg_Error}openssl组件安装失败！可能会影响到程序运行！建议手动安装！"
            fi
            if [ -f "/usr/bin/nslookup" ]; then
                Switch_env_nslookup_exist="1"
            else
                Switch_env_nslookup_exist="0"
                echo -e "${Msg_Error}nslookup组件安装失败！可能会影响到程序运行！建议手动安装！"
            fi
        elif [ -f "/usr/bin/sudo" ]; then
            echo -e "${Msg_Warning}检测到当前脚本并非以root权限启动，正在尝试通过sudo命令安装……"
            if [ "${Switch_env_system_release}" = "centos" ]; then
                echo -e "${Msg_Info}检测到系统分支：CentOS"
                echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
                sudo yum install curl bind-utils -y
            elif [ "${Switch_env_system_release}" = "ubuntu" ]; then
                echo -e "${Msg_Info}检测到系统分支：Ubuntu"
                echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
                sudo apt-get install curl dnsutils -y
            elif [ "${Switch_env_system_release}" = "debian" ]; then
                echo -e "${Msg_Info}检测到系统分支：Debian"
                echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
                sudo apt-get install curl dnsutils -y
            else
                echo -e "${Msg_Warning}系统分支未知，取消环境安装，建议手动安装环境！"
            fi
        else
            echo -e "${Msg_Error}系统缺少必需环境，并且无法自动安装，建议手动安装！"
        fi
    fi
}

# 判断是否有已存在的配置文件 (是否已经配置过环境)
function_AliDDNS_CheckConfig(){
    if [ -f "/etc/OneKeyAliDDNS/config.cfg" ]; then
        echo -e "${Msg_Info}检测到存在的配置，自动读取现有配置\n       如果你不需要，请通过菜单中的清理环境选项进行清除"
        # 读取配置文件
        AliDDNS_DomainName=`sed '/^AliDDNS_DomainName=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_SubDomainName=`sed '/^AliDDNS_SubDomainName=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_TTL=`sed '/^AliDDNS_TTL=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_AK=`sed '/^AliDDNS_AK=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_SK=`sed '/^AliDDNS_SK=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_LocalIP=`sed '/^AliDDNS_LocalIP=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        AliDDNS_DomainServerIP=`sed '/^AliDDNS_DomainServerIP=/!d;s/.*=//' /etc/OneKeyAliDDNS/config.cfg | sed 's/\"//g'`
        if [ "${AliDDNS_DomainName}" = "" ] || [ "${AliDDNS_SubDomainName}" = 0 ] || [ "${AliDDNS_TTL}" = "" ] \
                || [ "${AliDDNS_AK}" = "" ] || [ "${AliDDNS_SK}" = "" ] || [ "${AliDDNS_LocalIP}" = "" ] \
                || [ "${AliDDNS_DomainServerIP}" = "" ]; then
            echo -e "${Msg_Error}配置文件有误，请检查配置文件，或者建议清理环境后重新配置 !"
            exit 1
        fi
        Switch_AliDDNS_Config_Exist="1"
    else
        Switch_AliDDNS_Config_Exist="0"
    fi
}

function_AliDDNS_SetConfig(){
    # AliDDNS_DomainName
    if [ "${AliDDNS_DomainName}" = "" ]; then
        echo -e "\n${Msg_Info}请输入一级域名 (比如 example.com)"
	    read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_DomainName
        [ "${AliDDNS_DomainName}" = "h" ] && function_document_AliDDNS_DomainName && echo -e "${Msg_Info}请输入一级域名 (比如 example.com)" && read -p "(此项必须填写，查看提示请输入 "h"):" AliDDNS_DomainName
        while [ -z "${AliDDNS_DomainName}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入一级域名 (比如 example.com)"
	        read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_DomainName
	    done
    fi
    # AliDDNS_SubDomainName
    if [ "${AliDDNS_SubDomainName}" = "" ]; then
        echo -e "\n${Msg_Info}请输入二级域名 (比如 ddns)"
	    read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_SubDomainName
        [ "${AliDDNS_SubDomainName}" = "h" ] && function_document_AliDDNS_SubDomainName && echo -e "${Msg_Info}请输入二级域名 (比如 ddns)" && read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_SubDomainName
        while [ -z "${AliDDNS_SubDomainName}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入二级域名 (比如 ddns)"
            read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_SubDomainName
	    done
    fi
    # AliDDNS_TTL
    if [ "${AliDDNS_TTL}" = "" ]; then
        echo -e "\n${Msg_Info}请输入记录的TTL(Time-To-Live)值："
	    read -p "(默认为600，查看帮助请输入“h”):" AliDDNS_TTL
        [ "${AliDDNS_TTL}" = "h" ] && function_document_AliDDNS_TTL && echo -e "${Msg_Info}请输入记录的TTL(Time-To-Live)值：" && read -p "(默认为600):" AliDDNS_TTL
        [ -z "${AliDDNS_TTL}" ] && echo -e "${Msg_Info}检测到输入空值，设置AliDDNS_TTL值为：“600”" && AliDDNS_TTL="600"
    fi
    # AliDDNS_AK
    if [ "${AliDDNS_AK}" = "" ]; then
        echo -e "\n${Msg_Info}请输入阿里云AccessKey ID"
	    read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_AK
        [ "${AliDDNS_AK}" = "h" ] && function_document_AliDDNS_AK && echo -e "${Msg_Info}请输入阿里云AccessKey ID" && read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_AK
        while [ -z "${AliDDNS_AK}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入阿里云AccessKey ID"
            read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_AK
	    done
    fi
    # AliDDNS_SK
    if [ "${AliDDNS_SK}" = "" ]; then
        echo -e "\n${Msg_Info}请输入阿里云Access Key Secret"
	    read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_SK
        [ "${AliDDNS_SK}" = "h" ] && function_document_AliDDNS_SK && echo -e "${Msg_Info}请输入阿里云Access Key Secret" && read -p "(默认为600):" AliDDNS_SK
        while [ -z "${AliDDNS_SK}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入阿里云Access Key Secret"
            read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_SK
	    done
    fi
    # AliDDNS_LocalIP
    if [ "${Switch_AliDDNS_ExpertMode}" = "1" ]; then
        if [ "${AliDDNS_LocalIP}" = "" ]; then
            echo -e "\n${Msg_Info}请输入获取本机IP使用的命令"
	        read -p "(查看帮助请输入“h”):" AliDDNS_LocalIP
            [ "${AliDDNS_LocalIP}" = "h" ] && function_document_AliDDNS_LocalIP && echo -e "${Msg_Info}请输入获取本机IP使用的命令" && read -p "(查看帮助请输入“h”):" AliDDNS_LocalIP
            [ -z "${AliDDNS_LocalIP}" ] && echo -e "${Msg_Info}检测到输入空值，设置执行命令为：“curl -s whatismyip.akamai.com”" && AliDDNS_LocalIP="curl -s whatismyip.akamai.com"
        fi
    else
        AliDDNS_LocalIP="curl -s whatismyip.akamai.com"
    fi
    # AliDDNS_DomainServerIP
    if [ "${Switch_AliDDNS_ExpertMode}" = "1" ]; then
        if [ "${AliDDNS_DomainServerIP}" = "" ]; then
            echo -e "\n${Msg_Info}请输入解析使用的DNS服务器"
	        read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_DomainServerIP
            [ "${AliDDNS_DomainServerIP}" = "h" ] && function_document_AliDDNS_DomainServerIP && echo -e "${Msg_Info}请输入解析使用的DNS服务器" && read -p "(此项必须填写，查看帮助请输入“h”):" AliDDNS_DomainServerIP
            [ -z "${AliDDNS_DomainServerIP}" ] && echo -e "${Msg_Info}检测到输入空值，设置默认DNS服务器为：“223.5.5.5”" && AliDDNS_DomainServerIP="223.5.5.5"
        fi
    else
        AliDDNS_DomainServerIP="223.5.5.5"
    fi
}

function_AliDDNS_WriteConfig(){
    # 写入配置文件
    echo -e "\n${Msg_Info}正在写入配置文件……"
    if [ "${Switch_env_is_root}" = "1" ]; then 
        Config_configdir="/etc/OneKeyAliDDNS/"
    else
        Config_configdir="~/OneKeyAliDDNS/"
    fi
    mkdir -p ${Config_configdir}
    rm -f ${Config_configdir}config.cfg
    cat>${Config_configdir}config.cfg<<EOF
AliDDNS_DomainName="${AliDDNS_DomainName}"
AliDDNS_SubDomainName="${AliDDNS_SubDomainName}"
AliDDNS_TTL="${AliDDNS_TTL}"
AliDDNS_AK="${AliDDNS_AK}"
AliDDNS_SK="${AliDDNS_SK}"
AliDDNS_LocalIP="${AliDDNS_LocalIP}"
AliDDNS_DomainServerIP="${AliDDNS_DomainServerIP}"
EOF
}

# 帮助文档
function_document_AliDDNS_DomainName(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_DomainName 说明${Font_Suffix}       
       这个参数决定你要修改的DDNS域名中，一级域名的名称。
       请保证你要配置的域名，DNS服务器已经转入阿里云云解析 (免费版企业版都可以)，也就是状态
       必须为“正常”或者“未设置解析”，不可以为“DNS服务器错误”等提示。
       此参数和 AliDDNS_SubDomainName 连接到一起 (即 AliDDNS_SubDomainName.AliDDNS_DomainName)
       即为最终配置的DDNS域名。例如AliDDNS.DomainName设置为“example”，AliDDNS_SubDomainName设置为“ddns”
       连接到一起就是“ddns.example.com”\n"
    AliDDNS_DomainName=""
}

function_document_AliDDNS_SubDomainName(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_SubDomainName 说明${Font_Suffix}       
       这个参数决定你要修改的DDNS域名中，二级域名的名称。
       请保证你要配置的域名，DNS服务器已经转入阿里云云解析 (免费版企业版都可以)，也就是状态
       必须为“正常”或者“未设置解析”，不可以为“DNS服务器错误”等提示。
       此参数和 AliDDNS_SubDomainName 连接到一起 (即 AliDDNS_SubDomainName.AliDDNS_DomainName)
       即为最终配置的DDNS域名。例如AliDDNS.DomainName设置为“example”，AliDDNS_SubDomainName设置为“ddns”
       连接到一起就是“ddns.example.com”\n"
    AliDDNS_SubDomainName=""
}

function_document_AliDDNS_TTL(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_TTL 说明${Font_Suffix}       
       这个参数决定你要修改的DDNS记录中，TTL(Time-To-Line)时长。
       越短的TTL，DNS更新生效速度越快 (但也不是越快越好，因情况而定)
       免费版产品可设置为 (600-86400) (即10分钟-1天)
       收费版产品可根据所购买的云解析企业版产品配置设置为 (1-86400) (即1秒-1天)
       请免费版用户不要设置TTL低于600秒，会导致运行报错！\n"
    AliDDNS_TTL=""
}

function_document_AliDDNS_AK(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_AK 说明${Font_Suffix}       
       这个参数决定修改DDNS记录所需要用到的阿里云API信息 (AccessKey ID)。
       获取AccessKey ID和AccessKey Secret请移步：
       https://usercenter.console.aliyun.com/#/manage/ak
       ${Font_Red}注意：${Font_Suffix}请不要泄露你的AK/SK给任何人！
       一旦他们获取了你的AK/SK，将会直接拥有控制你阿里云账号的能力！
       为了您的阿里云账号安全，请不要随意分享AK/SK(包括请求帮助时候的截图)！"
    AliDDNS_AK=""
}

function_document_AliDDNS_SK(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_SK 说明${Font_Suffix}       
       这个参数决定修改DDNS记录所需要用到的阿里云API信息 (Access Key Secret)。
       获取AccessKey ID和AccessKey Secret请移步：
       https://usercenter.console.aliyun.com/#/manage/ak
       ${Font_Red}注意：${Font_Suffix}请不要泄露你的AK/SK给任何人！
       一旦他们获取了你的AK/SK，将会直接拥有控制你阿里云账号的能力！
       为了您的阿里云账号安全，请不要随意分享AK/SK(包括请求帮助时候的截图)！"
    AliDDNS_SK=""
}

function_document_AliDDNS_LocalIP(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_LocalIP 说明${Font_Suffix}       
       这个参数决定如何获取到本机的IP地址。
       出于稳定性考虑，默认使用whatismyip.akamai.com作为获取IP的方式，
       你也可以指定自己喜欢的获取IP方式。输入格式为需要执行的命令。
       请不要在命令中带双引号！解析配置文件时候会过滤掉！"
    AliDDNS_LocalIP=""
}

function_document_AliDDNS_DomainServerIP(){
    echo -e "${Msg_Info}${Font_Green}AliDDNS_DomainServerIP 说明${Font_Suffix}       
       这个参数决定如何获取到DDNS域名当前的解析记录。
       会使用nslookup命令查询，此参数控制使用哪个DNS服务器进行解析。
       默认使用“223.5.5.5”进行查询 (因为都是阿里家的东西)"
    AliDDNS_DomainServerIP=""
}

# 程序核心功能 ===========================================================

# 获取本机IP
function_AliDDNS_GetLocalIP(){
    echo -e "${Msg_Info}正在获取本机IP……"
    if [ "${AliDDNS_LocalIP}" = "" ]; then
        echo -e "${Msg_Error}AliDDNS_LocalIP参数为空或无效！"
        echo -e "${Msg_Fail}程序运行出现致命错误，正在退出……"
        exit 1
    fi
    AliDDNS_LocalIP=`$AliDDNS_LocalIP 2>&1`
    if [ "${AliDDNS_LocalIP}" = "" ]; then
        echo -e "${Msg_Error}未能获取本机IP！"
        echo -e "${Msg_Fail}程序运行出现致命错误，正在退出……"
        exit 1
    else
        echo -e "${Msg_Info}本机IP：${AliDDNS_LocalIP}"
    fi
}

# 新版获取域名IP的方法，使用腾讯云的HttpDNS
#
#function_AliDDNS_DomainIP(){
#    echo -e "${Msg_Info}正在获取 $AliDDNS_SubDomainName.$AliDDNS_DomainName 的IP……"
#    AliDDNS_DomainIP=`curl -s http://119.29.29.29/d?dn=$AliDDNS_SubDomainName.$AliDDNS_DomainName`
#    if [ "$?" -eq "0" ]; then
#        # 如果执行成功，分离出结果中的IP地址
#        if [ "${AliDDNS_DomainIP}" = "" ]; then
#            echo -e "${Msg_Info}解析结果：$AliDDNS_SubDomainName.$AliDDNS_DomainName -> (结果为空)"
#            echo -e "${Msg_Warning}$AliDDNS_SubDomainName.$AliDDNS_DomainName 未检测到任何有效的解析记录，可能是DNS记录不存在或尚未生效"
#            echo -e "${Msg_Info}程序可能会报告InvalidParameter异常错误，如出现此错误，请前往阿里云云解析面板手动添加一条任意记录值的A解析记录即可！"
#        else
#            echo -e "${Msg_Info}解析结果：$AliDDNS_SubDomainName.$AliDDNS_DomainName -> $AliDDNS_DomainIP"
#        fi
#        # 进行判断，如果本次获取的新IP和旧IP相同，结束程序运行
#        if [ "$AliDDNS_LocalIP" = "$AliDDNS_DomainIP" ]
#        then
#            echo -e "${Msg_Info}当前IP ($AliDDNS_LocalIP) 与 $AliDDNS_SubDomainName.$AliDDNS_DomainName ($AliDDNS_DomainIP) 的IP相同"
#            echo -e "${Msg_Success}未发生任何变动，无需进行改动，正在退出……"
#            exit 0
#        fi 
#    fi
#}    

# 旧版获取域名IP的方法，如果新版方法发生异常，请删掉新版代码，取消旧版的注释，保存即可！

# 获取DDNS域名当前解析记录IP
function_AliDDNS_DomainIP(){
    echo -e "${Msg_Info}正在获取 $AliDDNS_SubDomainName.$AliDDNS_DomainName 的IP……"
    AliDDNS_DomainIP=`nslookup $AliDDNS_SubDomainName.$AliDDNS_DomainName $AliDDNS_DomainServerIP 2>&1`
    if [ "$?" -eq "0" ]; then
        # 如果执行成功，分离出结果中的IP地址
        AliDDNS_DomainIP=`echo "$AliDDNS_DomainIP" | grep 'Address:' | tail -n1 | awk '{print $NF}'`
        if [ "${AliDDNS_DomainIP}" = "" ]; then
            echo -e "${Msg_Info}解析结果：$AliDDNS_SubDomainName.$AliDDNS_DomainName -> (结果为空)"
            echo -e "${Msg_Info}$AliDDNS_SubDomainName.$AliDDNS_DomainName 未检测到任何有效的解析记录，可能是DNS记录不存在或尚未生效"
        else
            echo -e "${Msg_Info}解析结果：$AliDDNS_SubDomainName.$AliDDNS_DomainName -> $AliDDNS_DomainIP"
        fi
    # 进行判断，如果本次获取的新IP和旧IP相同，结束程序运行
        if [ "$AliDDNS_LocalIP" = "$AliDDNS_DomainIP" ]
        then
            echo -e "${Msg_Info}当前IP ($AliDDNS_LocalIP) 与 $AliDDNS_SubDomainName.$AliDDNS_DomainName ($AliDDNS_DomainIP) 的IP相同"
            echo -e "${Msg_Success}未发生任何变动，无需进行改动，正在退出……"
            exit 0
        fi 
    fi
}

function_AliDDNS_GetTimestamp(){
    echo -e "${Msg_Info}正在生成时间戳……"
    timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
}

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c
    do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}
# URL加密命令
enc() {
    echo -n "$1" | urlencode
}
# 发送请求函数
send_request() {
    local args="AccessKeyId=$AliDDNS_AK&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$AliDDNS_SK&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

# 获取记录值 (RecordID)
get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

# 请求记录值 (RecordID)
query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$AliDDNS_SubDomainName.$AliDDNS_DomainName&Timestamp=$timestamp"
}
# 更新记录值 (RecordID)
update_record() {
    send_request "UpdateDomainRecord" "RR=$AliDDNS_SubDomainName&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$AliDDNS_TTL&Timestamp=$timestamp&Type=A&Value=$AliDDNS_LocalIP"
}
# (Update 20180703 Bugfix : 屏蔽add_record，避免发生记录重复冲突问题，感谢 mylyne 反馈)
# 添加记录值 (RecordID)
# add_record() {
#    send_request "AddDomainRecord" "RR=$AliDDNS_SubDomainName&DomainName=$AliDDNS_DomainName&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$AliDDNS_TTL&Timestamp=$timestamp&Type=A&Value=$AliDDNS_LocalIP"
# }

# RecordID更新
function_AliDDNS_UpdateRecord(){
    echo -e "${Msg_Info}正在更新记录……"
    if [ "${AliDDNS_RecordID}" = "" ]; then
        echo -e "${Msg_Info}正在获取RecordID……"
        AliDDNS_RecordID=`query_recordid | get_recordid`
        if [ "${AliDDNS_RecordID}" = "" ]; then
            echo -e "${Msg_Warning}未能获取到RecordID，可能没有检测到有效的解析记录 (RecordID：$AliDDNS_RecordID)"
        else
            echo -e "${Msg_Info}RecordID -> $AliDDNS_RecordID"
            echo -e "${Msg_Info}正在更新解析记录：$AliDDNS_SubDomainName.$AliDDNS_DomainName -> $AliDDNS_LocalIP ……"
            update_record $AliDDNS_RecordID
            echo -e "\n${Msg_Info}已经更新RecordID：$AliDDNS_RecordID"
        fi
    fi
    if [ "${AliDDNS_RecordID}" = "" ]; then
        # 输出失败结果 (因为没有获取到RecordID)
        echo -e "${Msg_Fail}DDNS记录更新失败！"
        exit 1
    else
        # 输出成功结果
        echo -e "${Msg_Success}DDNS记录更新成功，新的IP为：$AliDDNS_LocalIP"
        # ServerChan推送组件
        function_ServerChan_SuccessMsgPush
        exit 0
    fi
}

function_AliDDNS_CleanEnviroment(){
    rm -f /etc/OneKeyAliDDNS/config.cfg
    rm -f ~/OneKeyAliDDNS/config.cfg
    rm -f /etc/OneKeyAliDDNS/config-ServerChan.cfg
    rm -f ~/OneKeyAliDDNS/config-ServerChan.cfg
    Switch_env_is_root="0"
    AliDDNS_DomainName=""
    AliDDNS_SubDomainName=""
    AliDDNS_TTL=""
    AliDDNS_AK=""
    AliDDNS_SK=""
    AliDDNS_LocalIP=""
    AliDDNS_DomainServerIP=""
    Switch_ServerChan_Enable="0"
    ServerChan_SCKEY=""
    ServerChan_Text=""
    ServerChan_Content=""
}

function_AliDDNS_ShowVersion(){
    echo -e "
# AliDDNS 工具 (阿里云云解析修改工具)
# 
# Build:    ${BuildTime}
# 支持平台:  CentOS/Debian/Ubuntu
# 作者:     iLemonrain (原作者: kyriosli/koolshare-aliddns)
# Blog:     https://blog.ilemonrain.com
# E-mail:   ilemonrain@ilemonrain.com
"
exit 0
}

function_ServerChan_Configure(){
    if [ "${ServerChan_SCKEY}" = "" ]; then
        echo -e "\n${Msg_Info}请输入ServerChan SCKEY："
	    read -p "(此项必须填写):" ServerChan_SCKEY
        [ "${ServerChan_SCKEY}" = "h" ] && function_document_ServerChan_SCKEY && echo -e "${Msg_Info}请输入ServerChan SCKEY：" && read -p "(此项必须填写，查看提示请输入 "h"):" ServerChan_SCKEY
        while [ -z "${ServerChan_SCKEY}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入ServerChan SCKEY："
	        read -p "(此项必须填写):" ServerChan_SCKEY
	    done
    fi
        if [ "${ServerChan_ServerFriendlyName}" = "" ]; then
        echo -e "\n${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
	    read -p "(此项必须填写，便于识别):" ServerChan_ServerFriendlyName
        [ "${ServerChan_ServerFriendlyName}" = "h" ] && function_document_ServerChan_ServerFriendlyName && echo -e "${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号" && read -p "(此项必须填写，便于识别):" ServerChan_ServerFriendlyName
        while [ -z "${ServerChan_ServerFriendlyName}" ]
	    do
		    echo -e "${Msg_Error}此项不可为空，请重新填写"
            echo -e "${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
	        read -p "(此项必须填写，便于识别):" ServerChan_ServerFriendlyName
	    done
    fi
}

function_ServerChan_CheckConfig(){
    if [ -f "/etc/OneKeyAliDDNS/config-ServerChan.cfg" ]; then
        Switch_ServerChan_ConfigExist="1"
    else
        Switch_ServerChan_ConfigExist="0"
    fi
}

function_ServerChan_ReadConfig(){
    if [ -f "/etc/OneKeyAliDDNS/config-ServerChan.cfg" ]; then
        # 读取配置文件
        Switch_ServerChan_Enable=`sed '/^Switch_ServerChan_Enable=/!d;s/.*=//' /etc/OneKeyAliDDNS/config-ServerChan.cfg | sed 's/\"//g'`
        ServerChan_ServerFriendlyName=`sed '/^ServerChan_ServerFriendlyName=/!d;s/.*=//' /etc/OneKeyAliDDNS/config-ServerChan.cfg | sed 's/\"//g'`
        ServerChan_SCKEY=`sed '/^ServerChan_SCKEY=/!d;s/.*=//' /etc/OneKeyAliDDNS/config-ServerChan.cfg | sed 's/\"//g'`
        # 开关变量设1
        Switch_ServerChan_ConfigExist="1"
    else
        Switch_ServerChan_ConfigExist="0"
    fi
}

function_ServerChan_WriteConfig(){
    # 写入配置文件
    echo -e "\n${Msg_Info}正在写入配置文件……"
    if [ "${Switch_env_is_root}" = "1" ]; then 
        Config_configdir="/etc/OneKeyAliDDNS/"
    else
        Config_configdir="~/OneKeyAliDDNS/"
    fi
    mkdir -p ${Config_configdir}
    rm -f ${Config_configdir}config-ServerChan.cfg
    cat>${Config_configdir}config-ServerChan.cfg<<EOF
Switch_ServerChan_Enable="${Switch_ServerChan_Enable}"
ServerChan_ServerFriendlyName="${ServerChan_ServerFriendlyName}"
ServerChan_SCKEY="${ServerChan_SCKEY}"
EOF
}

# 如果你有动手能力，可以尝试定制ServerChan推送的消息内容
function_ServerChan_SuccessMsgPush(){
    function_ServerChan_ReadConfig
    if [ "${Switch_ServerChan_ConfigExist}" = "1" ]; then
        if [ ${Switch_ServerChan_Enable} = "1" ]; then
            echo -e "${Msg_Info}检测到ServerChan配置，正在推送消息到ServerChan平台……"
            ServerChan_Text="服务器IP发生变动_AliDDNSv2"
            ServerChan_Content="服务器：${ServerChan_ServerFriendlyName}，新的IP为：$AliDDNS_LocalIP，请注意服务器状态"
            curl -s "http://sc.ftqq.com/$ServerChan_SCKEY.send?text=${ServerChan_Text}" -d "&desp=${ServerChan_Content}"
            if [ "$?" -eq "0" ]; then
                echo -e "\n${Msg_Success}ServerChan 推送成功，服务器IP变动消息已经送达微信，请注意查收"
            else
                echo -e "${Msg_Warning}ServerChan 推送失败 (curl命令执行出现异常)"
            fi
        fi
    fi
    rm -f /etc/OneKeyAliDDNS/_ServerChan_tmp_output
}

Entrance_AliDDNS_Configure_And_Run(){
    function_Check_Root
    function_Check_Enviroment
    function_Install_Enviroment
    function_AliDDNS_CheckConfig
    function_AliDDNS_SetConfig
    function_AliDDNS_WriteConfig
    function_AliDDNS_GetLocalIP
    function_AliDDNS_DomainIP
    function_AliDDNS_GetTimestamp
    function_AliDDNS_UpdateRecord
    exit 0
}

Entrance_AliDDNS_RunOnly(){
    function_AliDDNS_CheckConfig
    if [ "${Switch_AliDDNS_Config_Exist}" = "0" ]; then
        echo -e "${Msg_Error} 未检测到任何有效配置，请先不带参数运行程序以进行配置！"
        exit 1
    fi
    function_Check_Enviroment
    function_Install_Enviroment
    function_AliDDNS_GetLocalIP
    function_AliDDNS_DomainIP
    function_AliDDNS_GetTimestamp
    function_AliDDNS_UpdateRecord
    exit 0
}

Entrance_AliDDNS_ConfigureOnly(){
    function_Check_Root
    function_Check_Enviroment
    function_Install_Enviroment
    function_AliDDNS_CheckConfig
    function_AliDDNS_SetConfig
    function_AliDDNS_WriteConfig
    echo -e "${Msg_Success}配置文件写入完成"
    exit 0
}

Entrance_ServerChan_Config(){
    function_Check_Root
    function_Check_Enviroment
    function_ServerChan_CheckConfig
    if [ "${Switch_ServerChan_ConfigExist}" = "1" ]; then
        echo -e "${Msg_Info}ServerChan配置文件已存在，如需重新配置请执行清理环境！"
        exit 0
    else
        Switch_ServerChan_Enable="1"
        function_ServerChan_Configure
        function_ServerChan_WriteConfig
    fi
    echo -e "${Msg_Success}配置文件写入完成，重新执行脚本即可激活ServerChan功能"
    echo -e "${Msg_Info}如需禁用ServerChan，执行清理环境即可"
    exit 0
}

Entrance_Global_CleanEnv(){
    echo -e "${Msg_Info}正在清理环境……"
    function_AliDDNS_CleanEnviroment
    echo -e "${Msg_Success}环境清理完成，重新执行脚本以开始配置"
    exit 0
}

Entrance_Version(){
    function_AliDDNS_ShowVersion
    exit 0
}

case "$1" in
    run)
        Entrance_AliDDNS_RunOnly
        ;;
    config)
        Entrance_AliDDNS_ConfigureOnly
        ;;
    clean)
        Entrance_Global_CleanEnv
        ;;
    clean)
        Entrance_Version
        ;;
    *)
        echo -e "${Font_Blue} AliDDNS 工具 (阿里云云解析修改工具)${Font_Suffix} 
        
使用方法 (Usage)：
AliDDNS.sh run       配置并运行工具 (如果已有配置将会直接运行)
AliDDNS.sh config    仅配置工具
AliDDNS.sh clean     清理配置文件及运行环境
AliDDNS.sh version   显示版本信息

"
        ;;
esac

echo -e "${Msg_Info}选择你要使用的功能: "
echo -e " 1. 配置并运行 AliDDNS \n 2. 仅配置 AliDDNS \n 3. 仅运行 AliDDNS \n 4. 配置ServerChan微信推送 \n 5. 清理环境 \n 0. 退出 \n"
read -p "输入数字以选择:" Function

if [ "${Function}" == "1" ]; then
	Entrance_AliDDNS_Configure_And_Run
elif [ "${Function}" == "2" ]; then
	Entrance_AliDDNS_ConfigureOnly
elif [ "${Function}" == "3" ]; then
	Entrance_AliDDNS_RunOnly
elif [ "${Function}" == "4" ]; then
	Entrance_ServerChan_Config
elif [ "${Function}" == "5" ]; then
	Entrance_Global_CleanEnv
else
    exit 0
fi