#!/bin/bash

# Copyright 2025 Renjiwintech
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================
# NASMATE 安装脚本 (v1.1)
# 仓库地址: https://github.com/renjiwinTECH/Nasmate
# 更新地址: https://github.com/renjiwinTECH/Nasmate
#Apache 2.0
# ==============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 进度条函数
progress_bar() {
    local duration=${1}
    local bar_length=50
    local sleep_interval=$(echo "scale=5; $duration/$bar_length" | bc)
    local progress=""
    local current_progress=""
    
    echo -ne "${CYAN}["
    for (( i=0; i<bar_length; i++ )); do
        echo -ne " "
    done
    echo -ne "] 0%${NC}\r"
    
    for (( i=0; i<bar_length; i++ )); do
        progress+="="
        current_progress="${progress}"
        if (( i < bar_length-1 )); then
            current_progress+=">"
        fi
        
        percentage=$(( (i+1)*100/bar_length ))
        echo -ne "${CYAN}[${current_progress}"
        for (( j=0; j<$((bar_length-i-1)); j++ )); do
            echo -ne " "
        done
        echo -ne "] ${percentage}%${NC}\r"
        sleep $sleep_interval
    done
    echo -ne "\n\n"
}

# 显示NASMATE标题
show_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "==================================================="
    echo " ███╗   ██╗ █████╗ ███████╗███╗   ███╗ █████╗ ████████╗███████╗"
    echo " ████╗  ██║██╔══██╗██╔════╝████╗ ████║██╔══██╗╚══██╔══╝██╔════╝"
    echo " ██╔██╗ ██║███████║███████╗██╔████╔██║███████║   ██║   █████╗  "
    echo " ██║╚██╗██║██╔══██║╚════██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝  "
    echo " ██║ ╚████║██║  ██║███████║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗"
    echo " ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
    echo "==================================================="
    echo -e "${NC}"
    echo -e "${BLUE}官方仓库: https://github.com/renjiwinTECH/Nasmate${NC}"
    echo -e "${BLUE}安装脚本版本: v1.1 | 最后更新: 2025-07-29${NC}"
    echo -e "===================================================\n"
}

# 检查用户是否为root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}✗ 错误：此脚本必须以root权限运行！${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}✓ 权限验证：root用户${NC}"
}

# 检查系统版本
check_os_version() {
    echo -e "${CYAN}🔍 正在检测系统版本...${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu)
                if [[ $VERSION_ID < "20" ]]; then
                    echo -e "${RED}✗ 错误：不支持的Ubuntu版本 ($VERSION_ID)，需要20.04或更高${NC}"
                    exit 1
                fi
                ;;
            debian)
                if [[ $VERSION_ID < "9" ]]; then
                    echo -e "${RED}✗ 错误：不支持的Debian版本 ($VERSION_ID)，需要9或更高${NC}"
                    exit 1
                fi
                ;;
            centos|rhel)
                if [[ $VERSION_ID < "7.2" ]]; then
                    echo -e "${RED}✗ 错误：不支持的CentOS版本 ($VERSION_ID)，需要7.2或更高${NC}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}✗ 错误：不支持的操作系统 $ID${NC}"
                echo "请使用Ubuntu 20+, Debian 9+ 或 CentOS 7.2+"
                exit 1
                ;;
        esac
        echo -e "${GREEN}✓ 系统版本: ${PRETTY_NAME}${NC}"
    else
        echo -e "${RED}✗ 错误：无法确定操作系统版本${NC}"
        exit 1
    fi
}

# 检查CPU架构
check_architecture() {
    echo -e "${CYAN}🔍 正在检测CPU架构...${NC}"
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  echo -e "${GREEN}✓ CPU架构: amd64 (x86-64)${NC}" ;;
        armv7l)  echo -e "${GREEN}✓ CPU架构: arm32 (v7)${NC}" ;;
        aarch64) echo -e "${GREEN}✓ CPU架构: arm64 (v8)${NC}" ;;
        *)
            echo -e "${RED}✗ 错误：不支持的CPU架构 ($ARCH)${NC}"
            echo "支持的架构: x86-64 (amd64), arm32 (v7-v7l), arm64 (v8)"
            exit 1
            ;;
    esac
}

# 检查内存
check_memory() {
    echo -e "${CYAN}🔍 正在检测系统内存...${NC}"
    TOTAL_MEM=$(free -m | awk '/Mem:/ {print $2}')
    if [ $TOTAL_MEM -lt 128 ]; then
        echo -e "${YELLOW}⚠️ 警告：内存不足 (${TOTAL_MEM}MB < 128MB)${NC}"
        read -p "是否强制继续? (y/n): " choice
        case "$choice" in
            y|Y) echo -e "${YELLOW}▶ 继续安装...${NC}" ;;
            *) echo -e "${RED}✗ 安装中止${NC}"; exit 1 ;;
        esac
    else
        echo -e "${GREEN}✓ 内存充足: ${TOTAL_MEM}MB${NC}"
    fi
}

# 检查CPU核心
check_cpu() {
    echo -e "${CYAN}🔍 正在检测CPU核心...${NC}"
    CPU_CORES=$(nproc)
    if [ $CPU_CORES -lt 1 ]; then
        echo -e "${YELLOW}⚠️ 警告：CPU核心不足 (${CPU_CORES} < 0.5核心)${NC}"
        read -p "是否强制继续? (y/n): " choice
        case "$choice" in
            y|Y) echo -e "${YELLOW}▶ 继续安装...${NC}" ;;
            *) echo -e "${RED}✗ 安装中止${NC}"; exit 1 ;;
        esac
    else
        echo -e "${GREEN}✓ CPU核心数: ${CPU_CORES}${NC}"
    fi
}

# 安装Python
install_python() {
    echo -e "\n${MAGENTA}🚀 第一步：安装Python环境${NC}"
    
    # 检查Python是否已安装
    if command -v python3 &>/dev/null; then
        PY_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        echo -e "${GREEN}✓ Python已安装，版本: ${PY_VERSION}${NC}"
    else
        echo -e "${YELLOW}⚠️ 未检测到Python环境，开始安装...${NC}"
        
        # 根据系统选择安装命令
        if command -v apt &>/dev/null; then
            echo -e "${CYAN}▶ 更新APT软件源...${NC}"
            if ! apt update -qq; then
                echo -e "${RED}✗ APT更新失败！${NC}"
                change_source
                apt update -qq
            fi
            
            echo -e "${CYAN}▶ 安装Python3...${NC}"
            if ! apt install -y python3; then
                echo -e "${RED}✗ Python安装失败！${NC}"
                change_source
                apt install -y python3
            fi
            
        elif command -v yum &>/dev/null; then
            echo -e "${CYAN}▶ 安装Python3...${NC}"
            if ! yum install -y python3; then
                echo -e "${RED}✗ Python安装失败！${NC}"
                change_source
                yum install -y python3
            fi
        else
            echo -e "${RED}✗ 错误：未找到支持的包管理器${NC}"
            exit 1
        fi
        
        # 验证安装
        if ! command -v python3 &>/dev/null; then
            echo -e "${RED}✗ Python安装失败！${NC}"
            echo -e "${YELLOW}请手动安装Python后重新运行脚本${NC}"
            exit 1
        else
            PY_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
            echo -e "${GREEN}✓ Python安装成功，版本: ${PY_VERSION}${NC}"
        fi
    fi
    
    # 更新软件包
    echo -e "\n${CYAN}▶ 更新系统软件包...${NC}"
    if command -v apt &>/dev/null; then
        apt upgrade -y -qq
    elif command -v yum &>/dev/null; then
        yum update -y -q
    fi
    echo -e "${GREEN}✓ 系统更新完成${NC}"
}

# 更换软件源
change_source() {
    echo -e "${YELLOW}是否尝试更换系统软件源? (y/n): ${NC}"
    read choice
    if [[ $choice =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}▶ 更换系统软件源...${NC}"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh)
        echo -e "${GREEN}✓ 软件源更换完成${NC}"
    else
        echo -e "${RED}✗ 用户取消更换软件源${NC}"
        exit 1
    fi
}

# 下载文件
download_files() {
    echo -e "\n${MAGENTA}🚀 第二步：下载所需文件${NC}"
    
    # 创建安装目录
    echo -e "${CYAN}▶ 创建安装目录...${NC}"
    mkdir -p /nasmate
    cd /nasmate || exit
    echo -e "${GREEN}✓ 目录创建: /nasmate${NC}"
    
    # 下载Python脚本
    echo -e "${CYAN}▶ 下载主程序 (guide.py)...${NC}"
    if ! curl -sL -o /nasmate/guide.py \
        "https://raw.githubusercontent.com/renjiwinTECH/Nasmate/main/guide.py"; then
        echo -e "${RED}✗ 下载失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 下载完成: guide.py${NC}"
    
    # 询问是否使用加速
    echo -e "${YELLOW}"
    echo "==================================================="
    echo "是否使用镜像加速下载frp? "
    echo " - 国内用户建议选择 (y) 加速下载"
    echo " - 国际用户建议选择 (n) 直接下载"
    echo "==================================================="
    echo -e "${NC}"
    read -p "请输入选择 (y/n): " choice
    case "$choice" in
        y|Y) 
            PREFIX="https://ghfast.top/"
            echo -e "${CYAN}✓ 已启用镜像加速${NC}"
            ;;
        *) 
            PREFIX=""
            echo -e "${CYAN}✓ 使用直连下载${NC}"
            ;;
    esac
    
    # 根据架构下载frp
    echo -e "\n${CYAN}▶ 下载FRP内网穿透工具...${NC}"
    case $(uname -m) in
        x86_64)
            FRP_URL="${PREFIX}https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_amd64.tar.gz"
            ;;
        armv7l)
            FRP_URL="${PREFIX}https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_arm.tar.gz"
            ;;
        aarch64)
            FRP_URL="${PREFIX}https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_arm64.tar.gz"
            ;;
    esac
    
    # 下载并解压frp
    echo -e "${CYAN}▶ 下载地址: ${FRP_URL}${NC}"
    if ! curl -sL "$FRP_URL" | tar xz -C /nasmate --strip-components=1; then
        echo -e "${RED}✗ FRP下载或解压失败！${NC}"
        exit 1
    fi
    
    # 设置权限
    chmod +x /nasmate/frpc
    chmod +x /nasmate/frps
    echo -e "${GREEN}✓ FRP下载完成并解压${NC}"
    echo -e "${GREEN}✓ 文件列表: $(ls -m)${NC}"
}

# 创建系统命令
create_system_command() {
    echo -e "\n${MAGENTA}🚀 第三步：创建系统命令${NC}"
    
    # 创建符号链接
    ln -sf /nasmate/guide.py /usr/local/bin/nasmate
    chmod +x /usr/local/bin/nasmate
    
    # 验证命令
    if command -v nasmate &>/dev/null; then
        echo -e "${GREEN}✓ 系统命令创建成功${NC}"
        echo -e "${CYAN}现在可以通过 'nasmate' 命令运行程序${NC}"
    else
        echo -e "${YELLOW}⚠️ 警告：命令创建失败，请手动添加${NC}"
        echo "您可以手动运行: ln -s /nasmate/guide.py /usr/local/bin/nasmate"
    fi
}

# 完成信息
show_completion() {
    echo -e "\n${GREEN}"
    echo "==================================================="
    echo " NASMATE 安装成功！"
    echo "==================================================="
    echo -e "${NC}"
    echo -e "${CYAN}安装目录: /nasmate ${NC}"
    echo -e "${CYAN}包含文件: $(ls -m /nasmate)${NC}"
    echo -e "\n${YELLOW}使用方法:${NC}"
    echo -e " 直接在终端输入: ${GREEN}nasmate${NC}"
    echo -e "\n${MAGENTA}感谢使用 NASMATE!${NC}"
    echo -e "${BLUE}官方仓库: https://github.com/renjiwinTECH/Nasmate${NC}"
    echo -e "${BLUE}问题反馈: https://github.com/renjiwinTECH/Nasmate/issues${NC}"
    echo -e "\n${YELLOW}正在启动 NASMATE...${NC}"
    
    # 显示进度条后启动
    progress_bar 3
    nasmate
}

# 主函数
main() {
    show_banner
    check_root
    check_os_version
    check_architecture
    check_memory
    check_cpu
    install_python
    download_files
    create_system_command
    show_completion
}

# 执行主函数
main