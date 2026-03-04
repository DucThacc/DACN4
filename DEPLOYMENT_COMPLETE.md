# 📦 VulnApp - Complete Deployment Package

## ✅ Gói hoàn chỉnh đã được tạo!

Tất cả files, configs, scripts đã được chuẩn bị sẵn để bạn có thể **clone 1 lần duy nhất** và deploy trên Ubuntu Server mà không cần chỉnh sửa thêm (ngoài IP).

---

## 📂 Cấu trúc đầu ra

```
VulnApp/
├── 📄 README.md                 ← 🌟 START HERE - Hướng dẫn chi tiết
├── 📄 QUICKREF.md               ← Cheat sheet cho common tasks
├── 📄 STRUCTURE.md              ← File structure documentation
├── 📄 .gitignore                ← Ready for git
├── 📄 deploy.sh                 ← Auto deployment script
│
├── web-waf/                     ← 🟡 DVWA + ModSecurity + MySQL
│   ├── README.md                ← WAF-specific guide
│   ├── docker-compose.yml       ← Services config
│   ├── Dockerfile               ← DVWA with ModSecurity
│   ├── .env                     ← ⚠️ CẦN EDIT: DVWA_HOST
│   ├── configs/modsecurity/
│   │   ├── modsecurity.conf     ← WAF rules (detection/blocking)
│   │   ├── default.conf         ← Apache config
│   │   └── crs-setup.conf       ← OWASP CRS
│   ├── logs/                    ← Auto-generated
│   │   ├── modsec_audit/        ← WAF alerts
│   │   └── apache_access/       ← HTTP logs
│   └── scripts/
│       ├── test_sqli.sh         ← SQL injection tests
│       ├── test_xss.sh          ← XSS tests
│       ├── test_lfi.sh          ← LFI tests
│       ├── test_nmap.sh         ← Network scan tests
│       └── analyze_logs.py      ← Analysis tool
│
├── suricata/                    ← 🟡 Network IDS/IPS
│   ├── README.md                ← IDS-specific guide
│   ├── docker-compose.yml       ← ⚠️ CẦN EDIT: interface name
│   ├── .env                     ← ⚠️ CẦN EDIT: HOME_NET, interface
│   ├── configs/
│   │   └── suricata.yaml        ← ⚠️ CẦN EDIT: HOME_NET, interface
│   ├── rules/
│   │   └── custom-rules.rules   ← Custom detection rules
│   └── logs/                    ← Auto-generated
│       ├── eve.json             ← IDS alerts (JSON)
│       └── stats.log            ← Stats
│
└── DEPLOYMENT_COMPLETE.md       ← This file
```

---

## 🎯 Các điểm cần thay đổi trước khi deploy (⚠️ CRITICAL)

### **1. web-waf/.env**
```bash
# Thay đổi dòng này:
DVWA_HOST=localhost
# Thành:
DVWA_HOST=<Ubuntu_Server_IP>  # VD: 192.168.1.100
```

### **2. suricata/.env**
```bash
# Thay đổi các dòng này:
HOME_NET=172.20.0.0/16
# Thành: (giữ nguyên nếu đây là Docker network subnet)

NETWORK_INTERFACE=eth0
# Thành: <interface của Ubuntu>  # VD: eth0, ens0, ens33, wlan0
```

### **3. suricata/docker-compose.yml**
```yaml
# Tìm dòng:
command: suricata -c /etc/suricata/suricata.yaml -i eth0

# Thay đổi eth0 thành:
command: suricata -c /etc/suricata/suricata.yaml -i <interface>
```

### **4. suricata/configs/suricata.yaml**
```yaml
# Tìm 2 chỗ:
vars:
  address-groups:
    HOME_NET: "[172.20.0.0/16]"  ← ĐỔI NẾUHOME_NET khác

af-packet:
  - interface: eth0  ← ĐỔI thành interface thực tế
```

---

## 🔍 Cách tìm giá trị IP đúng (trên Ubuntu Server)

```bash
# 1. IP address của Ubuntu
hostname -I

# 2. Network interface
ip link show
# Tìm cái có UP,LOWER_UP (không phải docker0 hay lo)

# 3. Docker network subnet (sau khi chạy deploy.sh lần 1)
docker network inspect web-shield | jq '.IPAM.Config[0].Subnet'
```

---

## 🚀 Deployment Steps

### Step 0: Clone & Configure
```bash
# Copy project
git clone <your-repo> ~/vulnapp && cd ~/vulnapp

# Get system info
ubuntu_ip=$(hostname -I | awk '{print $1}')
interface=$(ip route | grep default | awk '{print $5}')
echo "Ubuntu IP: $ubuntu_ip"
echo "Interface: $interface"

# Update configs (manually or use sed)
sed -i "s/DVWA_HOST=.*/DVWA_HOST=$ubuntu_ip/" web-waf/.env
sed -i "s/NETWORK_INTERFACE=.*/NETWORK_INTERFACE=$interface/" suricata/.env
```

### Step 1: Deploy
```bash
# Option A: Automatic
bash deploy.sh

# Option B: With IPS mode
sudo bash deploy.sh ips

# Option C: Manual
cd web-waf && mkdir -p logs/{modsec_audit,apache_access} && docker-compose up -d
cd ../suricata && mkdir -p logs && docker-compose up -d
```

### Step 2: Verify
```bash
# Check all containers running
docker ps | grep -E "dvwa|mysql|suricata"

# Test DVWA access
curl http://$ubuntu_ip/

# Check logs
docker logs dvwa-app
docker logs mysql-dvwa
docker logs suricata-ids
```

### Step 3: Test Attacks
```bash
cd web-waf
bash scripts/test_sqli.sh
bash scripts/test_xss.sh
bash scripts/test_lfi.sh

# View alerts
tail -f ../suricata/logs/eve.json | jq '.alert.signature'
tail -f logs/modsec_audit/audit.log
```

---

## 📋 What's Included

### ✅ Complete

- [x] Docker Compose configurations (2 separate services)
- [x] DVWA Dockerfile with ModSecurity pre-built
- [x] ModSecurity with OWASP CRS rules
- [x] Suricata IDS configuration (ready for IPS mode)
- [x] 4 automated test scripts (SQLi, XSS, LFI, Nmap)
- [x] Log analysis Python script
- [x] Master deployment script
- [x] Comprehensive documentation (4 guides)
- [x] Quick reference card
- [x] Project structure documentation
- [x] .gitignore for clean repository

### 📝 Documentation

- [x] README.md - Complete guide with IP configuration explained
- [x] web-waf/README.md - WAF-specific configuration & troubleshooting
- [x] suricata/README.md - IDS/IPS configuration & mode switching
- [x] QUICKREF.md - Quick commands for common tasks
- [x] STRUCTURE.md - File structure & purposes
- [x] This file - Deployment checklist

### 🔧 Configuration Files

- [x] web-waf/.env - MySQL, DVWA, ModSecurity vars
- [x] web-waf/docker-compose.yml - Service definitions
- [x] web-waf/Dockerfile - Custom DVWA + ModSecurity build
- [x] web-waf/configs/modsecurity.conf - WAF rules
- [x] web-waf/configs/default.conf - Apache config
- [x] web-waf/configs/crs-setup.conf - OWASP CRS
- [x] suricata/.env - Network, interface, mode vars
- [x] suricata/docker-compose.yml - Service definition
- [x] suricata/configs/suricata.yaml - IDS/IPS config
- [x] suricata/rules/custom-rules.rules - Detection rules

### 🧪 Scripts & Tools

- [x] deploy.sh - Master orchestration
- [x] web-waf/scripts/test_sqli.sh - SQL injection tests
- [x] web-waf/scripts/test_xss.sh - XSS tests
- [x] web-waf/scripts/test_lfi.sh - LFI tests
- [x] web-waf/scripts/test_nmap.sh - Network scan tests
- [x] web-waf/scripts/analyze_logs.py - Log analysis tool

---

## 🎓 Key Features

### Web-WAF Stack
- ✅ DVWA (vulnerable web app)
- ✅ ModSecurity (Web Application Firewall)
- ✅ Apache 2.4 with PHP
- ✅ MySQL 5.7
- ✅ OWASP CRS rules (latest)
- ✅ Detection & Blocking modes
- ✅ Comprehensive audit logging

### Suricata Stack
- ✅ Network IDS (detection mode)
- ✅ Ready for IPS mode (with iptables rules)
- ✅ Custom detection rules for DVWA attacks
- ✅ EVE JSON logging
- ✅ Real-time alerts
- ✅ Performance optimized for 8GB RAM

### Integration
- ✅ Separate docker networks (secure)
- ✅ Log analysis correlation
- ✅ Both detect same attacks (for validation)

---

## 📊 Key Points to Remember

### IPs to Configure
| Component | File | Variable | Example |
|-----------|------|----------|---------|
| DVWA Access | web-waf/.env | DVWA_HOST | 192.168.1.100 |
| Network Monitoring | suricata/.env | HOME_NET | 172.20.0.0/16 |
| Interface | suricata/.env | NETWORK_INTERFACE | eth0 |
| Suricata Config | suricata/docker-compose.yml | -i flag | eth0 |
| Suricata Config | suricata/configs/suricata.yaml | interface + HOME_NET | eth0, 172.20.0.0/16 |

### Log Locations
```
ModSecurity    → web-waf/logs/modsec_audit/audit.log
Apache Access  → web-waf/logs/apache_access/access.log
Suricata Alerts → suricata/logs/eve.json
Statistics    → suricata/logs/stats.log
```

### Default Credentials
```
DVWA: admin/password
MySQL: dvwa/dvwa (user), root/root (admin)
```

### Port Mappings
```
DVWA/Apache: Port 80 (mapped to localhost:80)
MySQL: Port 3306 (mapped to localhost:3306)
Suricata: Network interface (no port mapping, sniffs all traffic)
```

---

## 🆘 Quick Troubleshooting

```bash
# If DVWA won't start
docker-compose -f web-waf/docker-compose.yml logs mysql-dvwa
docker-compose -f web-waf/docker-compose.yml restart

# If Suricata won't detect traffic
docker logs suricata-ids | grep -i interface
ip link show  # Verify interface name

# If ModSecurity not detecting
docker exec dvwa-app apache2ctl -M | grep security

# If port 80 in use
docker-compose -f web-waf/docker-compose.yml logs
netstat -tlnp | grep :80
```

---

## 📚 Documentation Reading Order

1. **First Time?** → README.md (main guide)
2. **How to configure IPs?** → README.md (section: CÁC ĐỊA CHỈ IP)
3. **Quick setup?** → QUICKREF.md
4. **File structure?** → STRUCTURE.md
5. **WAF questions?** → web-waf/README.md
6. **IDS questions?** → suricata/README.md

---

## ✨ Special Notes

### Two Independent Folders
- **web-waf/** = Web application protection stack
  - Can be deployed alone
  - Provides HTTP-level security
  
- **suricata/** = Network monitoring stack
  - Can be deployed alone
  - Provides network-level security
  
- **Together** = Defense-in-depth system

### Ready for Ubuntu Server
- All configs ready
- Just update IPs
- Deploy in 5 minutes
- No additional installation needed

### Git-Ready
- .gitignore configured
- Ready to push to GitHub
- Logs excluded automatically
- Configs tracked

---

## 🎉 You're Ready!

```
✅ Project structure complete
✅ All configs prepared
✅ All scripts written
✅ All documentation ready
✅ Just update IPs and deploy!
```

---

## 📞 Support Resources

### Inside the Package
- README.md - Comprehensive guide
- QUICKREF.md - Quick commands
- web-waf/README.md - WAF details
- suricata/README.md - IDS details

### External
- ModSecurity: https://modsecurity.org/
- Suricata: https://suricata.readthedocs.io/
- OWASP CRS: https://coreruleset.org/
- DVWA: https://github.com/digininja/DVWA

---

## 🚀 Next Steps

1. **Clone to Ubuntu Server**
   ```bash
   git clone <repo> ~/vulnapp && cd ~/vulnapp
   ```

2. **Configure IPs**
   ```bash
   nano web-waf/.env
   nano suricata/.env
   nano suricata/docker-compose.yml
   nano suricata/configs/suricata.yaml
   ```

3. **Deploy**
   ```bash
   bash deploy.sh
   ```

4. **Test**
   ```bash
   cd web-waf && bash scripts/test_sqli.sh
   ```

5. **Analyze**
   ```bash
   python3 web-waf/scripts/analyze_logs.py \
     --suricata suricata/logs/eve.json \
     --modsec web-waf/logs/modsec_audit/audit.log
   ```

---

**Everything is ready to go! 🎓**

**Happy defending! 🛡️**

---

Generated: March 4, 2026
VulnApp v1.0 - Complete Deployment Package
