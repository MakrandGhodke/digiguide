import socket
import re
import os

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def update_config(ip):
    config_path = os.path.join('frontend', 'lib', 'config.dart')
    if not os.path.exists(config_path):
        print(f"[ERROR] Could not find {config_path}")
        return

    with open(config_path, 'r') as f:
        content = f.read()
    
    # Regex to find the baseUrl line and replace it
    # Pattern looks for: static const String baseUrl = 'http://<any_ip>:8000';
    pattern = r"static const String baseUrl = 'http://[0-9\.]+:8000';"
    replacement = f"static const String baseUrl = 'http://{ip}:8000';"
    
    if re.search(pattern, content):
        new_content = re.sub(pattern, replacement, content)
        with open(config_path, 'w') as f:
            f.write(new_content)
        print(f"[INFO] Updated config.dart to use IP: {ip}")
    else:
        print("[WARNING] Could not find baseUrl pattern in config.dart")

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == '--localhost':
        print("[-] Force Mode: USB/Localhost")
        current_ip = '127.0.0.1'
    else:
        print("[-] Detecting Local IP Address...")
        current_ip = get_ip()
        print(f"[-] Detected IP: {current_ip}")
    
    update_config(current_ip)
