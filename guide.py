#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os

def clear_screen():
    os.system('clear')

def check_files():
    required_files = ['frpc', 'frpc.toml']
    missing = [f for f in required_files if not os.path.exists(f)]
    if missing:
        print("缺少必要文件：", ", ".join(missing))
        print("请重新运行安装脚本！！！")
        exit(1)

def write_public_config():
    config = """serverAddr = "frp.freefrp.net"
serverPort = 7000
auth.token = "freefrp.net"

webServer.addr = "0.0.0.0"
webServer.port = 7400
webServer.user = "admin"
webServer.password = "admin"
"""
    with open('frpc.toml', 'w') as f:
        f.write(config)

def validate_proxy_name(name):
    if len(name) > 5:
        return False
    return all(char.isalnum() for char in name)

def get_user_input():
    while True:
        proxy_name = input("穿透名称（便于区分）：").strip()
        if validate_proxy_name(proxy_name):
            break
        print("名称无效：必须为不超过5位的字母数字组合")
    
    local_ip = input("本地地址（默认127.0.0.1）：").strip() or "127.0.0.1"
    
    while True:
        local_port = input("本地端口：").strip()
        if local_port.isdigit():
            break
        print("端口必须为数字")
    
    while True:
        protocol = input("穿透协议（1:tcp 2:udp）：").strip()
        if protocol in ['1', '2']:
            protocol = 'tcp' if protocol == '1' else 'udp'
            break
        print("请选择1或2")
    
    return proxy_name, local_ip, local_port, protocol

def append_proxy_config(name, local_ip, local_port, protocol):
    config = f"""
[[proxies]]
name = "{name}"
type = "{protocol}"
localIP = "{local_ip}"
localPort = {local_port}
remotePort = 40043
"""
    with open('frpc.toml', 'a') as f:
        f.write(config)

def run_frpc():
    # 清理旧日志
    if os.path.exists('nohup.out'):
        os.remove('nohup.out')
    
    # 启动frpc
    os.system('nohup ./frpc -c frpc.toml > nohup.out 2>&1 &')
    
    # 等待3秒并显示日志
    print("\n启动日志（3秒）：")
    os.system('sleep 3 && head -n 20 nohup.out')
    
    # 检查进程状态
    os.system('sleep 2')
    result = os.popen('ps aux | grep "frpc -c frpc.toml" | grep -v grep').read()
    
    if not result:
        print("\n启动失败，进程已退出！请检查配置")
        return False
    
    return True

def public_service():
    write_public_config()
    proxy_name, local_ip, local_port, protocol = get_user_input()
    append_proxy_config(proxy_name, local_ip, local_port, protocol)
    
    print("\n配置完成，正在启动frpc...")
    if run_frpc():
        print("\n穿透成功！")
        print(f"公网地址：frp.freefrp.net:40043")
        print(f"协议：{protocol}")
    else:
        print("启动失败，请自行检查配置")

def self_service():
    editor = os.environ.get('EDITOR', 'vi')
    os.system(f'{editor} frpc.toml')
    print("配置已保存，请手动启动frpc")

def main():
    clear_screen()
    print("NASMATE\nMade by github @RenjiWinTech\nAnd freefrp.net")
    
    while True:
        print("\n早上好！亲爱的用户")
        print("您想进行哪项操作？")
        print("1. Frpc（穿透）")
        print("2. 退出")
        
        choice = input("请选择: ").strip()
        
        if choice == '1':
            check_files()
            print("\n请选择服务类型：")
            print("1. 使用公共服务")
            print("2. 使用您自建服务")
            
            service_choice = input("请选择: ").strip()
            if service_choice == '1':
                public_service()
            elif service_choice == '2':
                self_service()
            else:
                print("无效选择")
        
        elif choice == '2':
            print("再见！")
            exit(0)
        
        else:
            print("无效选择，请重新输入")

if __name__ == "__main__":
    main()