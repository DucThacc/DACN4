# Suricata IDS/IPS Configuration Guide

## Overview
Folder này chứa Suricata - Network-based IDS/IPS cho phát hiện tấn công mạng

---

## ⚠️ IP Configuration Points

### 1️⃣ File: `.env`
```bash
# ĐỔI CÁC GIÁ TRỊ NÀY:

HOME_NET=172.20.0.0/16
# ↓ THÀNH Docker network subnet của bạn
# Lệnh kiểm tra: docker network inspect web-shield | grep Subnet

NETWORK_INTERFACE=eth0
# ↓ THÀNH interface thực tế của Ubuntu
# Lệnh kiểm tra: ip link show
```

### 2️⃣ File: `configs/suricata.yaml`
```yaml
vars:
  address-groups:
    HOME_NET: "[172.20.0.0/16]"
    # ↑ UPDATE THIS

af-packet:
  - interface: eth0
    # ↑ UPDATE THIS (eth0, ens0, ens33, etc)
```

### 3️⃣ File: `docker-compose.yml`
```yaml
command: suricata -c /etc/suricata/suricata.yaml -i eth0
#                                                    ^^^^
# ↑ UPDATE THIS - interface name
```

---

## 🔍 Finding Your Network Configuration

### Check Network Interface
```bash
# List all interfaces
ip link show

# Output example:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
#     ...
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500  ← This one
#     ...
# 3: docker0: ...

# Result: Use "eth0" (or whichever is active and not docker/lo)
```

### Check Docker Network Subnet
```bash
# List Docker networks
docker network ls

# Inspect bridge network
docker network inspect web-shield

# Find IPAM config:
# "IPAM": {
#   "Config": [
#     {
#       "Subnet": "172.20.0.0/16"  ← Use this
#     }
#   ]
# }
```

### Check Container IPs
```bash
# List container IPs
docker ps -q | xargs -I {} docker inspect -f '{{.Name}} - {{.NetworkSettings.Networks.web-shield.IPAddress}}' {}

# Output:
# /mysql-dvwa - 172.20.0.2
# /dvwa-app - 172.20.0.3
```

---

## 🚀 Quick Start

```bash
cd suricata

# Create log directory
mkdir -p logs

# Update config files (see above)
# 1. Edit .env - set HOME_NET and NETWORK_INTERFACE
# 2. Edit docker-compose.yml - set interface
# 3. Edit configs/suricata.yaml - set HOME_NET and interface

# Start Suricata
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker logs suricata-ids
tail -f logs/eve.json | jq '.'
```

---

## 🔐 IDS vs IPS Mode

### IDS Mode (Detection only)
```yaml
# File: configs/suricata.yaml
mode: idsmode  # ← Default
```

**Characteristics:**
- Non-blocking mode
- Only alerts/logs attacks
- No network interruption
- Good for learning

### IPS Mode (Blocking)
```yaml
mode: ipsmode  # ← Blocking mode
```

**Requirements:**
1. Root/sudo privileges
2. iptables/nfqueue setup
3. More configuration

---

## 🔄 Switching IDS → IPS Mode

### Step 1: Setup iptables (on Ubuntu Server)
```bash
# Load nf_queue module
sudo modprobe nf_queue

# Add rules to send traffic to Suricata
sudo iptables -I INPUT 1 -j NFQUEUE --queue-num 0
sudo iptables -I FORWARD 1 -j NFQUEUE --queue-num 0

# Verify
sudo iptables -L -n | grep NFQUEUE
```

### Step 2: Update Configuration
```bash
# Option A: Manual edit
nano configs/suricata.yaml
# Find: mode: idsmode
# Change to: mode: ipsmode

# Option B: Automated
sed -i 's/mode: idsmode/mode: ipsmode/' configs/suricata.yaml
```

### Step 3: Restart Suricata
```bash
docker-compose restart suricata

# Verify
docker logs suricata-ids | grep -i "ips"
```

### Step 4: Test Blocking
```bash
# Trigger a known attack pattern
curl "http://localhost/?id=1' UNION SELECT 1--"

# Should be blocked/dropped
# Check logs:
docker logs suricata-ids | grep "DROP"
cat logs/eve.json | jq 'select(.event_type == "drop")'
```

### Step 5: Disable IPS Mode (if needed)
```bash
# Revert to IDS
sed -i 's/mode: ipsmode/mode: idsmode/' configs/suricata.yaml
docker-compose restart suricata

# Remove iptables rules (optional)
sudo iptables -D INPUT -j NFQUEUE --queue-num 0
sudo iptables -D FORWARD -j NFQUEUE --queue-num 0
```

---

## 📊 Monitoring & Analysis

### Real-time Alerts
```bash
# View all eve.json entries
tail -f logs/eve.json | jq '.'

# Filter by alert only
tail -f logs/eve.json | jq 'select(.event_type == "alert")'

# Count alerts
watch -n 1 'cat logs/eve.json | wc -l'
```

### Alert Analysis
```bash
# Top alert signatures
cat logs/eve.json | jq '.alert.signature' | sort | uniq -c | sort -rn

# Filter by attack type
cat logs/eve.json | jq 'select(.alert.signature | contains("SQL"))'
cat logs/eve.json | jq 'select(.alert.signature | contains("XSS"))'
cat logs/eve.json | jq 'select(.alert.signature | contains("SCAN"))'

# Source IPs
cat logs/eve.json | jq '.src_ip' | sort | uniq -c

# Destination IPs
cat logs/eve.json | jq '.dest_ip' | sort | uniq -c
```

### Statistics
```bash
# View stats.log
tail -f logs/stats.log

# Alert count
jq -s 'map(select(.event_type == "alert")) | length' logs/eve.json

# HTTP events
jq -s 'map(select(.event_type == "http")) | length' logs/eve.json

# File info events
jq -s 'map(select(.event_type == "fileinfo")) | length' logs/eve.json
```

---

## 🧪 Testing

### SQL Injection Detection
```bash
# Trigger alert
curl "http://localhost/?id=1' UNION SELECT 1--"

# Check log
cat logs/eve.json | jq 'select(.alert.signature | contains("SQL"))'
```

### XSS Detection
```bash
curl "http://localhost/?name=<script>alert('XSS')</script>"
cat logs/eve.json | jq 'select(.alert.signature | contains("XSS"))'
```

### Network Scan Detection
```bash
# From another machine (not localhost)
# On Ubuntu Server:
sudo nmap -p 80,3306 <Target_IP>

# Check logs (after ~30 seconds)
cat logs/eve.json | jq 'select(.alert.signature | contains("SCAN"))'
```

### Automated Tests
```bash
bash ../web-waf/scripts/test_sqli.sh
bash ../web-waf/scripts/test_xss.sh
bash ../web-waf/scripts/test_nmap.sh
```

---

## 📝 Custom Rules

### Location: `rules/custom-rules.rules`

### Rule Format
```
alert <protocol> <src_ip> <src_port> -> <dst_ip> <dst_port> (msg:"Description"; content:"..."; sid:XXXXX; rev:1;)
```

### Example: Detect "admin" in URL
```
alert http any any -> any any (msg:"Admin Panel Access Attempt"; \
  content:"/admin"; http_uri; classtype:suspicious-activity; sid:3100; rev:1;)
```

### Reload Rules
```bash
# Suricata auto-reloads, or restart
docker-compose restart suricata
```

### Disable Rules (if needed)
```bash
# In suricata.yaml, comment out rules file:
# rule-files:
#   - suricata.rules
#   # - custom-rules.rules  (disabled)
```

---

## 🔧 Performance Tuning

### For 8GB RAM

#### CPU Optimization
```yaml
# In configs/suricata.yaml
threading:
  workers:
    - worker_id: 1
      cpu-set: "0-1"  # Use cores 0-1 only
```

#### Memory Optimization
```yaml
flow:
  memcap: 268435456  # 256MB for flows
  prealloc-sessions: 40000

app-layer:
  protocols:
    http:
      memcap: 268435456  # 256MB for HTTP
```

#### Buffer Tuning
```yaml
af-packet:
  - interface: eth0
    ring-size: 200000
    block-size: 32768
```

---

## 🛡️ Rule Tuning

### Remove False Positives
```yaml
# In suricata.yaml
# Disable problematic rules
# Or increase anomaly score threshold

vars:
  alproto_http_policy: default
```

### Increase Detection Level
```apache
# Higher paranoia in custom rules
# Add more specific patterns
```

---

## 🔀 Integration with ModSecurity

Both detect attacks at different layers:

**ModSecurity (Layer 7 - HTTP)**
- Analyzes HTTP payloads
- Understands HTTP semantics
- Can block immediately

**Suricata (Layer 3-4 - Network)**
- Sees all network traffic
- Detects scanning/reconnaissance
- Network-level blocking

### Correlation
```bash
# Find same attack in both logs
ATTACKER_IP="192.168.1.50"

# In Suricata
cat logs/eve.json | jq ".src_ip" | grep "$ATTACKER_IP"

# In ModSecurity  
grep "$ATTACKER_IP" ../web-waf/logs/modsec_audit/audit.log
```

---

## 📊 Logging Configuration

### Log Types in evt.json
```json
{
  "event_type": "alert",     // Attack detection
  "alert": {...},
  "src_ip": "...",
  "dest_ip": "...",
  "timestamp": "..."
}
```

### Log Rotation
```yaml
outputs:
  - eve-log:
      rotate: daily
      retention:
        count: 7  # Keep 7 days
        timestamp: true
```

### Disable Logging (if needed)
```yaml
# In suricata.yaml
outputs:
  - eve-log:
      enabled: no  # Disable JSON log
```

---

## 📂 File Structure

```
.
├── docker-compose.yml          ← Start here
├── .env                        ← Config variables (⚠️ Edit)
├── configs/
│   └── suricata.yaml           ← Main config (⚠️ Edit)
├── rules/
│   └── custom-rules.rules      ← Custom detection rules
├── logs/
│   ├── eve.json                ← Alert logs (JSON)
│   ├── stats.log               ← Statistics
│   └── ...
└── scripts/
    └── (analysis scripts)
```

---

## 🆘 Troubleshooting

### Suricata won't start
```bash
docker logs suricata-ids
docker-compose up -d --no-deps --build suricata
```

### No alerts generated
```bash
# Check if rules are loaded
docker exec suricata-ids suricata -c /etc/suricata/suricata.yaml -T -v

# Check eve.json being written
ls -lah logs/eve.json

# Verify network interface
docker logs suricata-ids | grep -i interface
```

### IPS mode not blocking
```bash
# Check iptables rules
sudo iptables -L -n | grep NFQUEUE

# Check nf_queue module loaded
lsmod | grep nf_queue

# Verify Suricata using IPS
docker logs suricata-ids | grep -i "ips"

# Check drop events
cat logs/eve.json | jq 'select(.event_type == "drop")'
```

### Memory/CPU too high
```bash
# Reduce worker CPUs
sed -i 's/cpu-set: "0-1"/cpu-set: "0"/' configs/suricata.yaml

# Reduce memory cap
sed -i 's/memcap: 268435456/memcap: 134217728/' configs/suricata.yaml

docker-compose restart suricata
```

### Can't detect traffic from external machine
```bash
# Verify interface is correct
ip link show

# Verify Suricata is sniffing
docker logs suricata-ids | grep packet

# Check iptables/firewall not blocking
sudo ufw status
```

---

## 📚 References

- [Suricata Documentation](https://suricata.readthedocs.io/)
- [Suricata Rules Format](https://suricata.readthedocs.io/en/latest/rules/)
- [EVE JSON Format](https://suricata.readthedocs.io/en/latest/output/eve-json-format.html)
- [Suricata IPS Mode](https://suricata.readthedocs.io/en/latest/setting-up-ips/)

---

**Last Updated**: March 2026
