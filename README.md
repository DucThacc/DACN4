# VulnApp - Web Security Defense System
**Thiết kế và triển khai hệ thống bảo vệ ứng dụng web thông minh tích hợp IDS/IPS và WAF**

---

## 📋 Mục lục
1. [Cấu trúc Project](#cấu-trúc-project)
2. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
3. [Cài đặt nhanh](#cài-đặt-nhanh)
4. [⚠️ CÁC ĐỊA CHỈ IP CẦN THAY ĐỔI](#các-địa-chỉ-ip-cần-thay-đổi)
5. [Deployment Chi Tiết](#deployment-chi-tiết)
6. [Testing & Validation](#testing--validation)
7. [Phân Tích Log](#phân-tích-log)
8. [IDS → IPS Mode Switching](#ids--ips-mode-switching)

---

## 📁 Cấu trúc Project

```
VulnApp/
├── web-waf/                          # Web Application + WAF (DVWA + ModSecurity + MySQL)
│   ├── docker-compose.yml            # Services: mysql, dvwa
│   ├── Dockerfile                    # Custom DVWA image with ModSecurity
│   ├── .env                          # Environment variables (⚠️ CẦN EDIT)
│   ├── configs/
│   │   ├── modsecurity/
│   │   │   ├── modsecurity.conf      # ModSecurity rules & config
│   │   │   ├── default.conf          # Apache vhost config
│   │   │   └── crs-setup.conf        # OWASP CRS setup
│   │   └── dvwa/
│   │       └── (placeholder)
│   ├── logs/
│   │   ├── modsec_audit/             # ModSecurity audit logs
│   │   └── apache_access/            # Apache access logs
│   └── scripts/
│       ├── test_sqli.sh              # SQL Injection test
│       ├── test_xss.sh               # XSS test
│       ├── test_lfi.sh               # Local File Inclusion test
│       ├── test_nmap.sh              # Network scan test
│       └── analyze_logs.py           # Log analysis script
│
├── suricata/                         # Network IDS/IPS
│   ├── docker-compose.yml            # Suricata service
│   ├── .env                          # Environment variables (⚠️ CẦN EDIT)
│   ├── configs/
│   │   └── suricata.yaml             # Suricata configuration (⚠️ CẦN EDIT)
│   ├── rules/
│   │   └── custom-rules.rules        # Custom detection rules
│   └── logs/
│       ├── eve.json                  # EVE JSON alerts
│       ├── stats.log                 # Statistics
│       └── (other logs)
│
├── deploy.sh                         # Master deployment script
└── README.md                         # This file
```

---

## ⚙️ Yêu cầu hệ thống

**Yêu cầu hệ thống:**
- OS: Ubuntu 20.04 LTS hoặc mới hơn
- RAM: Minimum 8GB (khuyến nghị 16GB)
- CPU: 4+ cores
- Storage: 20GB free space
- **Docker Engine: 20.10+**
- **Docker Compose: v1.29+ HOẶC v2.x (script tự động detect)**
  - ✅ Hỗ trợ `docker-compose` (v1)
  - ✅ Hỗ trợ `docker compose` (v2)
  - Script tự động chọn đúng phiên bản

**Trên máy phát triển (Development):**
- Git
- Docker & Docker Compose
- curl, jq (optional nhưng hữu ích)

---

## 🚀 Cài đặt nhanh

### 1️⃣ Clone Repository
```bash
git clone <your-repo> vulnapp && cd vulnapp
```

### 2️⃣ ⚠️ CẬP NHẬT CÁC ĐỊA CHỈ IP (QUAN TRỌNG!)
Xem phần [CÁC ĐỊA CHỈ IP CẦN THAY ĐỔI](#các-địa-chỉ-ip-cần-thay-đổi) bên dưới

### 3️⃣ Deploy (tách riêng từng stack)
```bash
# Web + WAF
cd web-waf && bash deploy.sh

# Suricata IDS
cd ../suricata && bash deploy.sh

# Suricata IPS (Blocking) - yêu cầu root
cd ../suricata && sudo bash deploy.sh ips
```

### 4️⃣ Kiểm tra
```bash
docker ps

# Expected output:
# CONTAINER ID   IMAGE              NAMES
# xxx            jasonish/suricata  suricata-ids
# xxx            dvwa-image         dvwa-app
# xxx            mysql:5.7          mysql-dvwa
```

---

## ⚠️ CÁC ĐỊA CHỈ IP CẦN THAY ĐỔI

### 🔴 **QUAN TRỌNG: Trước khi deploy, bạn PHẢI thay đổi các giá trị sau cho phù hợp với Ubuntu Server của bạn!**

#### **1. web-waf/.env**
```bash
# File: web-waf/.env
# Dòng cần thay đổi:

DVWA_HOST=localhost
# ↓ THÀNH
DVWA_HOST=192.168.1.100    # ← IP của Ubuntu Server

MYSQL_HOST=mysql
# (Giữ nguyên nếu chạy trong Docker network)
```

#### **2. suricata/.env**  
```bash
# File: suricata/.env

HOME_NET=172.20.0.0/16
# ↓ THỨ NẾU UBUNTU SERVER CÓ DOCKER NETWORK KHÁC

NETWORK_INTERFACE=eth0
# ↓ THÀNH interface thực tế của Ubuntu (xem: ip link show)
# Ví dụ: eth0, ens0, ens33, enp0s3, wlan0, vv

SURICATA_MODE=idsmode
# ↓ ĐỔI THÀNH (nếu muốn IPS blocking):
SURICATA_MODE=ipsmode
```

#### **3. suricata/docker-compose.yml**
```yaml
# File: suricata/docker-compose.yml
# Dòng cần thay đổi:

command: suricata -c /etc/suricata/suricata.yaml -i eth0
#                                                    ^^^^
# ↓ THÀNH eth0, ens0, ens33, vv (interface của Ubuntu)

# Kiểm tra interface trên Ubuntu:
# $ ip link show
# 1: lo: ...
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...  ← interface này
# 3: docker0: ...
```

#### **4. suricata/configs/suricata.yaml**
```yaml
# File: suricata/configs/suricata.yaml

vars:
  address-groups:
    HOME_NET: "[172.20.0.0/16]"  
    # ↓ ĐỔI THÀNH subnet của Docker containers
    # Để check: docker network inspect web-shield (xem IPAM)

af-packet:
  - interface: eth0
    # ↓ THÀNH interface thực tế của Ubuntu
```

---

### 🔍 **Cách tìm đúng giá trị IP & Interface trên Ubuntu Server**

**Lệnh kiểm tra:**
```bash
# 1. IP address của Ubuntu Server
hostname -I
# Output: 192.168.1.100 172.17.0.1

# 2. Network interfaces
ip link show
# Output:
# 1: lo: <LOOPBACK,UP,LOWER_UP> 
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>  ← interface này
# 3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP>

# 3. Docker network subnet
docker network inspect web-shield | grep Subnet
# Output: "Subnet": "172.20.0.0/16"

# 4. Container IPs
docker inspect -f '{{.Name}} - {{.NetworkSettings.Networks.web-shield.IPAddress}}' $(docker ps -q)
# Output:
# /mysql-dvwa - 172.20.0.2
# /dvwa-app - 172.20.0.3
```

**Ví dụ cụ thể (Ubuntu Server 192.168.1.100 với interface eth0):**

```bash
# web-waf/.env
DVWA_HOST=192.168.1.100

# suricata/.env  
HOME_NET=172.20.0.0/16
NETWORK_INTERFACE=eth0
SURICATA_MODE=idsmode

# suricata/docker-compose.yml
command: suricata -c /etc/suricata/suricata.yaml -i eth0

# suricata/configs/suricata.yaml
vars:
  address-groups:
    HOME_NET: "[172.20.0.0/16]"

af-packet:
  - interface: eth0
```

---

## 📚 Deployment Chi Tiết

### **Cách 1: Sử dụng Deploy Script theo từng folder (KHUYẾN NGHỊ)**

```bash
# 1. Deploy Web-WAF
cd web-waf && bash deploy.sh

# 2. Deploy Suricata IDS
cd ../suricata && bash deploy.sh

# 3. Chuyển Suricata sang IPS (tuỳ chọn)
cd ../suricata && sudo bash deploy.sh ips
```

### **Cách 2: Manual Deployment**

#### **Step 1: Deploy Web-WAF**
```bash
cd web-waf
mkdir -p logs/{modsec_audit,apache_access}
docker-compose up -d

# Verify
docker ps | grep dvwa
docker logs dvwa-app

# Get DVWA IP
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa-app
```

#### **Step 2: Deploy Suricata**
```bash
cd ../suricata
mkdir -p logs
docker-compose up -d

# Verify
docker ps | grep suricata
docker logs suricata-ids
```

#### **Step 3: Enable IPS Mode (Optional)**
```bash
# On Ubuntu Server (với root privileges):
sudo modprobe nf_queue
sudo iptables -I INPUT 1 -j NFQUEUE --queue-num 0
sudo iptables -I FORWARD 1 -j NFQUEUE --queue-num 0

# Update config
cd suricata
sed -i 's/mode: idsmode/mode: ipsmode/' configs/suricata.yaml
docker-compose restart suricata
```

---

## 🧪 Testing & Validation

### **Test 1: SQL Injection Detection**
```bash
cd web-waf
bash scripts/test_sqli.sh

# Expected:
# - ModSecurity log entry
# - Suricata alert in eve.json
```

### **Test 2: XSS Detection**
```bash
bash scripts/test_xss.sh

# Check logs:
tail -f logs/modsec_audit/audit.log
tail -f ../suricata/logs/eve.json
```

### **Test 3: Network Scanning**
```bash
# Requires nmap and sudo
bash scripts/test_nmap.sh

# Should trigger Suricata SCAN alerts
```

### **Test 4: Manual Testing**
```bash
# Get DVWA IP
DVWA_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa-app)

# SQL Injection
curl "http://$DVWA_IP/vulnerabilities/sqli/?id=1' UNION SELECT 1-- -"

# XSS
curl "http://$DVWA_IP/vulnerabilities/xss_r/?name=<script>alert('XSS')</script>"

# LFI
curl "http://$DVWA_IP/vulnerabilities/fi/?page=../../../../etc/passwd"
```

---

## 📊 Phân Tích Log

### **ModSecurity Audit Log**
```bash
# View real-time
tail -f web-waf/logs/modsec_audit/audit.log

# Count detections
wc -l web-waf/logs/modsec_audit/audit.log

# Search specific attack
grep -i "union" web-waf/logs/modsec_audit/audit.log
grep -i "xss" web-waf/logs/modsec_audit/audit.log
```

### **Suricata EVE JSON**
```bash
# View all alerts
cat suricata/logs/eve.json | jq 'select(.event_type == "alert")'

# Count alerts
cat suricata/logs/eve.json | jq -s 'length'

# Filter by alert type
cat suricata/logs/eve.json | jq 'select(.alert.signature | contains("SQL"))'

# Get source IPs
cat suricata/logs/eve.json | jq '.src_ip' | sort | uniq -c

# Python analysis script
python3 web-waf/scripts/analyze_logs.py \
  --suricata suricata/logs/eve.json \
  --modsec web-waf/logs/modsec_audit/audit.log
```

### **Real-time Monitoring**
```bash
# Terminal 1: Watch Suricata
watch -n 1 'wc -l suricata/logs/eve.json'

# Terminal 2: Watch ModSecurity
tail -f web-waf/logs/modsec_audit/audit.log

# Terminal 3: Monitor containers
docker stats
```

---

## 🔄 IDS → IPS Mode Switching

### **Enable IPS Mode** (Blocking Mode)

```bash
# Step 1: On Ubuntu Server (with root/sudo)
sudo modprobe nf_queue
sudo iptables -I INPUT 1 -j NFQUEUE --queue-num 0
sudo iptables -I FORWARD 1 -j NFQUEUE --queue-num 0

# Verify iptables rules
sudo iptables -L -n | grep NFQUEUE

# Step 2: Update Suricata config
cd suricata
sed -i 's/mode: idsmode/mode: ipsmode/' configs/suricata.yaml

# Or manually edit:
# configs/suricata.yaml - line ~80:
# mode: ipsmode  # ← uncomment

# Step 3: Restart Suricata
docker-compose restart suricata

# Verify
docker logs suricata-ids | grep "IPS"

# Step 4: Test blocking
curl "http://localhost/?id=1' UNION SELECT 1--"
# Should be dropped/blocked

docker logs suricata-ids | grep "DROP"
```

### **Disable IPS Mode** (Back to IDS)
```bash
sed -i 's/mode: ipsmode/mode: idsmode/' suricata/configs/suricata.yaml
docker-compose -f suricata/docker-compose.yml restart suricata

# Remove iptables rules (optional)
sudo iptables -D INPUT -j NFQUEUE --queue-num 0
sudo iptables -D FORWARD -j NFQUEUE --queue-num 0
```

---

## 🔧 Troubleshooting

| Vấn đề | Giải pháp |
|--------|----------|
| DVWA không connect MySQL | `docker logs mysql-dvwa` - check error |
| Port 80 conflict | Edit docker-compose.yml: `ports: "8080:80"` |
| Suricata không bắt traffic | Kiểm tra interface: `ip link show` |
| ModSecurity log empty | Bật debug mode: `setvar:tx.debug_logging=1` |
| IPS mode không hoạt động | Kiểm tra iptables rules: `sudo iptables -L -n` |
| Memory full | Giảm workers Suricata |

---

## 📝 Chỉnh sửa Rules

### **ModSecurity Rules** (web-waf/configs/modsecurity/modsecurity.conf)
```apache
# Thêm custom rule
SecRule ARGS "malicious_pattern" \
    "id:2001,phase:2,deny,status:403,msg:'Custom Attack Blocked'"

# Restart để apply
docker-compose -f web-waf/docker-compose.yml restart dvwa
```

### **Suricata Rules** (suricata/rules/custom-rules.rules)
```
alert http any any -> any any (msg:"Custom Alert"; \
  flow:to_server,established; \
  content:"specific_string"; \
  sid:3001; rev:1;)

# Reload rules: Suricata tự tải lại sau khi detect thay đổi
```

---

## 📈 Performance Optimization (8GB RAM)

```bash
# Monitor resource usage
docker stats

# If memory issues:

# 1. Reduce Suricata workers (configs/suricata.yaml)
workers:
  - worker_id: 1
    cpu-set: "0"  # ← 1 core instead of 2

# 2. Reduce memory limits (docker-compose.yml)
mem_limit: 512m  # suricata
mem_limit: 256m  # dvwa

# 3. Disable unused features
# - Disable file extraction
# - Reduce rule set
# - Limit log retention
```

---

## 🎓 Ghi chú học thuật

### **Kiến trúc bảo mật**
- **Layer 1**: Network (Suricata IDS/IPS)
- **Layer 2**: Protocol (HTTP validation)
- **Layer 3**: Application (ModSecurity WAF + OWASP CRS)
- **Layer 4**: Database (MySQL)

### **Detection vs Prevention**
| Aspect | IDS Mode | IPS Mode |
|--------|----------|----------|
| Function | Detect attacks | Block attacks |
| Latency | Minimal | Slight increase |
| False Positives | Acceptable | Must be tuned |
| Network Setup | Simple | Complex (iptables) |

### **Metrics được đo**
1. **Detection Rate**: % attacks detected
2. **False Positive Rate**: % benign traffic flagged
3. **Response Time**: Latency impact
4. **Logging Completeness**: % attacks logged

---

## 📞 Support

### **Logs để kiểm tra**
- ModSecurity: `web-waf/logs/modsec_audit/audit.log`
- Apache: `web-waf/logs/apache_access/access.log`
- Suricata: `suricata/logs/eve.json`
- Docker: `docker logs <container_name>`

### **Useful Commands**
```bash
# View all logs
docker-compose logs --all

# Interactive DVWA
docker exec -it dvwa-app bash

# Check network
docker network inspect web-shield

# Resource usage
docker stats --no-stream
```

---

## 📄 License & References

- [DVWA](https://github.com/digininja/DVWA)
- [ModSecurity](https://modsecurity.org/)
- [OWASP CRS](https://corelt.org/)
- [Suricata](https://suricata.io/)

---

**Tác giả**: Security Lab  
**Phiên bản**: 1.0  
**Cập nhật lần cuối**: March 2026

---

✅ **Deployment checklist:**
- [ ] Clone repository
- [ ] Update IP addresses in .env files
- [ ] Update network interface in suricata configs
- [ ] Run deploy.sh
- [ ] Verify all containers running
- [ ] Run test scripts
- [ ] Check logs
- [ ] (Optional) Enable IPS mode

🎉 **Bạn đã sẵn sàng để bảo vệ ứng dụng web!**
