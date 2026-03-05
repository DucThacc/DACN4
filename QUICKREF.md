# VulnApp - Quick Reference Card

**Note**: Script này tự động detect và chạy được với cả `docker-compose` (v1) và `docker compose` (v2) ✅

## 📋 Pre-Deployment Checklist

```bash
# 1. Copy to Ubuntu Server
scp -r vulnapp/ user@ubuntu-server:/home/user/

# 2. SSH into Ubuntu
ssh user@ubuntu-server

# 3. Navigate to project
cd ~/vulnapp

# 4. Check prerequisites
docker --version      # Should be 20.10+
docker-compose --version  # Should be 1.29+

# 5. Get system info
hostname -I           # Your Ubuntu Server IP
ip link show          # Network interface name
docker network inspect web-shield | grep Subnet
```

---

## ⚠️ IP Configuration (MUST DO BEFORE DEPLOY)

### Get Your Values
```bash
# 1. Ubuntu Server IP
ubuntu_ip=$(hostname -I | awk '{print $1}')
echo $ubuntu_ip

# 2. Network Interface
interface=$(ip route | grep default | awk '{print $5}')
echo $interface

# 3. Docker Network (after first run)
docker network inspect web-shield | jq '.IPAM.Config[0].Subnet'
docker_subnet=$(docker network inspect web-shield | jq -r '.IPAM.Config[0].Subnet')
echo $docker_subnet
```

### Update Configuration
```bash
# 1. web-waf/.env
sed -i "s/DVWA_HOST=localhost/DVWA_HOST=$ubuntu_ip/" web-waf/.env

# 2. suricata/.env
sed -i "s/HOME_NET=.*/HOME_NET=$docker_subnet/" suricata/.env
sed -i "s/NETWORK_INTERFACE=.*/NETWORK_INTERFACE=$interface/" suricata/.env
sed -i "s|command: suricata.*|command: suricata -c /etc/suricata/suricata.yaml -i $interface|" suricata/docker-compose.yml

# 3. suricata/configs/suricata.yaml
sed -i "s|HOME_NET:.*|HOME_NET: \"[$docker_subnet]\"|" suricata/configs/suricata.yaml
sed -i "s|interface: .*|interface: $interface|" suricata/configs/suricata.yaml
```

### Verify Changes
```bash
# Check web-waf/.env
grep DVWA_HOST web-waf/.env

# Check suricata/.env
grep HOME_NET suricata/.env
grep NETWORK_INTERFACE suricata/.env

# Check suricata/docker-compose.yml
grep "command: suricata" suricata/docker-compose.yml

# Check suricata.yaml
grep "HOME_NET:" suricata/configs/suricata.yaml | head -1
grep "interface: " suricata/configs/suricata.yaml | head -1
```

---

## 🚀 Deployment

### One-liner Deployment
```bash
bash deploy.sh
```

### Manual Step-by-Step
```bash
# 1. Web-WAF
cd web-waf
mkdir -p logs/{modsec_audit,apache_access}
docker-compose up -d
sleep 10
docker-compose ps

# 2. Suricata
cd ../suricata
mkdir -p logs
docker-compose up -d
sleep 5
docker-compose ps

# 3. Check all
cd ..
docker ps | grep -E "dvwa|mysql|suricata"
```

### Verify Deployment
```bash
# Check DVWA access
curl http://$ubuntu_ip/
# Should return DVWA HTML

# Check MySQL
docker logs mysql-dvwa | grep "ready for"

# Check Suricata
docker logs suricata-ids | head -20
```

---

## 🧪 Quick Testing

```bash
# SQL Injection
curl "http://$ubuntu_ip/vulnerabilities/sqli/?id=1' UNION SELECT 1--"

# XSS
curl "http://$ubuntu_ip/vulnerabilities/xss_r/?name=<script>alert(1)</script>"

# LFI
curl "http://$ubuntu_ip/vulnerabilities/fi/?page=../../../../etc/passwd"

# Check ModSecurity detected
tail -f web-waf/logs/modsec_audit/audit.log

# Check Suricata detected  
tail -f suricata/logs/eve.json | jq '.alert.signature'
```

---

## 🔄 Mode Switching

### Enable IPS (Blocking)
```bash
# 1. Setup iptables (ROOT)
sudo modprobe nf_queue
sudo iptables -I INPUT 1 -j NFQUEUE --queue-num 0
sudo iptables -I FORWARD 1 -j NFQUEUE --queue-num 0

# 2. Update config
sed -i 's/mode: idsmode/mode: ipsmode/' suricata/configs/suricata.yaml

# 3. Restart
cd suricata && docker-compose restart suricata

# 4. Verify
docker logs suricata-ids | grep -i "ips"
```

### Disable IPS (back to IDS)
```bash
sed -i 's/mode: ipsmode/mode: idsmode/' suricata/configs/suricata.yaml
docker-compose -f suricata/docker-compose.yml restart suricata
```

---

## 📊 Log Analysis

```bash
# Count all alerts
cat suricata/logs/eve.json | jq -s 'length'

# Top alerts
cat suricata/logs/eve.json | jq -r '.alert.signature' | sort | uniq -c | sort -rn | head -10

# SQL Injection alerts
cat suricata/logs/eve.json | jq 'select(.alert.signature | contains("SQL"))'

# Source IPs
cat suricata/logs/eve.json | jq -r '.src_ip' | sort | uniq -c | sort -rn

# ModSecurity detections
wc -l web-waf/logs/modsec_audit/audit.log
grep -c "msg" web-waf/logs/modsec_audit/audit.log

# Python analysis
python3 web-waf/scripts/analyze_logs.py \
  --suricata suricata/logs/eve.json \
  --modsec web-waf/logs/modsec_audit/audit.log
```

---

## 🎯 Common Tasks

### Switch ModSecurity to Blocking Mode
```bash
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' \
  web-waf/configs/modsecurity/modsecurity.conf
docker-compose -f web-waf/docker-compose.yml restart dvwa
```

### View Real-time Alerts
```bash
# Terminal 1: Suricata
tail -f suricata/logs/eve.json | jq '.'

# Terminal 2: ModSecurity
tail -f web-waf/logs/modsec_audit/audit.log

# Terminal 3: Monitor
docker stats
```

### Run Tests
```bash
cd web-waf
bash scripts/test_sqli.sh
bash scripts/test_xss.sh
bash scripts/test_lfi.sh
bash scripts/test_nmap.sh
```

### Clean Up & Restart
```bash
# Stop all
docker-compose -f web-waf/docker-compose.yml down
docker-compose -f suricata/docker-compose.yml down

# Remove volumes (data loss!)
docker volume prune -f

# Restart
bash deploy.sh
```

---

## 🆘 Troubleshooting

```bash
# Container logs
docker logs dvwa-app
docker logs mysql-dvwa
docker logs suricata-ids

# System logs
docker-compose logs

# Check if port in use
sudo netstat -tlnp | grep :80

# Container shell access
docker exec -it dvwa-app bash
docker exec -it suricata-ids bash

# Rebuild container
docker-compose -f web-waf/docker-compose.yml up -d --build
```

---

## 📁 Important Paths

```
Project Root: ~/vulnapp/
├── web-waf/
│   ├── docker-compose.yml
│   ├── .env          ⚠️ EDIT
│   ├── configs/modsecurity/modsecurity.conf
│   └── logs/         (Generated)
│
├── suricata/
│   ├── docker-compose.yml
│   ├── .env          ⚠️ EDIT
│   ├── configs/suricata.yaml  ⚠️ EDIT
│   ├── rules/custom-rules.rules
│   └── logs/eve.json (Generated)
│
└── deploy.sh
```

---

## 🔑 Credentials

```
DVWA:
  URL: http://<ubuntu_ip>/
  User: admin
  Pass: password

MySQL:
  Host: localhost (docker) or 172.20.0.2 (from host)
  User: dvwa
  Pass: dvwa
  DB: dvwa
```

---

## ⏱️ Expected Startup Times

```
1. Docker compose pull images  : ~2-3 min
2. Build DVWA image             : ~3-5 min
3. MySQL initialization         : ~1-2 min
4. DVWA startup                 : ~30 sec
5. Suricata startup             : ~10 sec
───────────────────────────────────
Total first run                 : ~10-15 min

Subsequent runs                 : ~30 sec
```

---

## 🎓 Learning Resources

```
ModSecurity & WAF:
  - Docs: https://modsecurity.org/
  - Rules: https://coreruleset.org/

Suricata IDS:
  - Docs: https://suricata.readthedocs.io/
  - Rules: https://github.com/oisf/suricata-rules

Web Security:
  - DVWA: https://github.com/digininja/DVWA
  - OWASP Top 10: https://owasp.org/www-project-top-ten/
```

---

## Quick Help
```bash
# Show this card
cat QUICKREF.md

# Show main README
cat README.md

# Show web-waf guide
cat web-waf/README.md

# Show suricata guide
cat suricata/README.md
```

---

**Save this file for quick reference!**

```bash
cp QUICKREF.md ~/QUICKREF.md
chmod +x ~/QUICKREF.md
```

---

**Last Updated**: March 2026
