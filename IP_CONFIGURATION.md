# ⚠️ IP CONFIGURATION POINTS - ALL LOCATIONS

**Đây là danh sách 🔴 TẤT CẢ 🔴 các chỗ bạn PHẢI thay đổi IP addresses trước khi deploy trên Ubuntu Server!**

---

## 📋 Master Checklist - Update theo thứ tự này

### **1️⃣ web-waf/.env**
```bash
File: web-waf/.env
────────────────────

Current:
  DVWA_HOST=localhost

Change to:
  DVWA_HOST=192.168.1.100    # ← Your Ubuntu Server IP

Command:
  sed -i "s/DVWA_HOST=localhost/DVWA_HOST=192.168.1.100/" web-waf/.env

✅ Status: [ ] Done
```

### **2️⃣ suricata/.env**
```bash
File: suricata/.env
──────────────────

Current:
  HOME_NET=172.20.0.0/16
  NETWORK_INTERFACE=eth0

Change to:
  HOME_NET=172.20.0.0/16     # Keep if this is your Docker subnet
  NETWORK_INTERFACE=eth0     # ← Your actual interface (eth0, ens0, ens33, etc)

Commands:
  # Check Docker subnet (run after first docker-compose):
  docker network inspect web-shield | jq '.IPAM.Config[0].Subnet'
  
  # Update interface:
  sed -i "s/NETWORK_INTERFACE=eth0/NETWORK_INTERFACE=ens0/" suricata/.env

✅ Status: [ ] Done
```

### **3️⃣ suricata/docker-compose.yml**
```yaml
File: suricata/docker-compose.yml
─────────────────────────────────

Current line ~35:
  command: suricata -c /etc/suricata/suricata.yaml -i eth0

Change to:
  command: suricata -c /etc/suricata/suricata.yaml -i ens0  # Your interface

Command:
  sed -i 's/-i eth0$/-i ens0/' suricata/docker-compose.yml

✅ Status: [ ] Done
```

### **4️⃣ suricata/configs/suricata.yaml**
```yaml
File: suricata/configs/suricata.yaml
────────────────────────────────────

Location 1 - Around line 30:
  vars:
    address-groups:
      HOME_NET: "[172.20.0.0/16]"

Keep or change to:
  HOME_NET: "[172.20.0.0/16]"  # ← Docker network subnet

Location 2 - Around line 95:
  af-packet:
    - interface: eth0

Change to:
  af-packet:
    - interface: ens0  # ← Your actual interface

Commands:
  sed -i 's/interface: eth0$/interface: ens0/' suricata/configs/suricata.yaml

✅ Status: [ ] Done
```

---

## 🔍 How to Find Your Values

### Command 1: Ubuntu Server IP
```bash
hostname -I

# Output example:
# 192.168.1.100 172.17.0.1

# ← Use 192.168.1.100 (not the Docker bridge 172.17.0.1)
```

### Command 2: Network Interface
```bash
ip link show

# Output example:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ← This one
# 3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP>

# Use "eth0" (could also be ens0, ens33, enp0s3, wlan0, etc)
# Look for the one marked BROADCAST, MULTICAST, UP, LOWER_UP
# (skip lo and docker0)
```

### Command 3: Docker Network Subnet
```bash
# After first deploy or when web-waf is running:
docker network inspect web-shield | jq '.IPAM.Config[0].Subnet'

# Output:
# "172.20.0.0/16"

# Use this value if HOME_NET is different
```

### Command 4: Container IPs
```bash
docker ps -q | xargs -I {} docker inspect \
  -f '{{.Name}} - {{.NetworkSettings.Networks.web-shield.IPAddress}}' {}

# Output:
# /mysql-dvwa - 172.20.0.2
# /dvwa-app - 172.20.0.3

# Useful for verification
```

---

## 📊 Example Configuration

**Let's say your Ubuntu Server has:**
- IP: 192.168.1.100
- Interface: eth0
- Docker subnet: 172.20.0.0/16

### Then update to:

```bash
# web-waf/.env
DVWA_HOST=192.168.1.100

# suricata/.env
HOME_NET=172.20.0.0/16
NETWORK_INTERFACE=eth0

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

## ✅ Automated Update Script

Save this as `configure.sh` in project root:

```bash
#!/bin/bash

echo "=== VulnApp IP Configuration ==="
echo ""

# Get values
ubuntu_ip=$(hostname -I | awk '{print $1}')
interface=$(ip route | grep default | awk '{print $5}')

echo "Detected values:"
echo "  Ubuntu IP: $ubuntu_ip"
echo "  Interface: $interface"
echo ""

# Wait for user confirmation
read -p "Apply these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Update web-waf/.env
sed -i "s/DVWA_HOST=.*/DVWA_HOST=$ubuntu_ip/" web-waf/.env
echo "✓ Updated web-waf/.env"

# Update suricata/.env
sed -i "s/NETWORK_INTERFACE=.*/NETWORK_INTERFACE=$interface/" suricata/.env
echo "✓ Updated suricata/.env"

# Update suricata/docker-compose.yml
sed -i "s/interface: eth0$/interface: $interface/" suricata/docker-compose.yml
echo "✓ Updated suricata/docker-compose.yml"

# Update suricata/configs/suricata.yaml
sed -i "s/interface: eth0$/interface: $interface/" suricata/configs/suricata.yaml
echo "✓ Updated suricata/configs/suricata.yaml"

echo ""
echo "Configuration complete!"
echo "You can now run: bash deploy.sh"
```

**Usage:**
```bash
chmod +x configure.sh
./configure.sh
bash deploy.sh
```

---

## 🚨 Verification Checklist

After updating all IPs, verify:

```bash
# Check web-waf/.env
echo "=== web-waf/.env ==="
grep DVWA_HOST web-waf/.env

# Check suricata/.env
echo "=== suricata/.env ==="
grep HOME_NET suricata/.env
grep NETWORK_INTERFACE suricata/.env

# Check suricata docker-compose
echo "=== suricata/docker-compose.yml ==="
grep "command: suricata" suricata/docker-compose.yml

# Check suricata.yaml
echo "=== suricata/configs/suricata.yaml ==="
grep "HOME_NET:" suricata/configs/suricata.yaml | head -1
grep "interface:" suricata/configs/suricata.yaml | head -1
```

---

## 🔴 Common Mistakes to Avoid

| Mistake | Problem | Solution |
|---------|---------|----------|
| Using Docker IP | Services unreachable from host | Use actual Ubuntu server IP (hostname -I) |
| Wrong interface | Suricata can't sniff | Use `ip link show` to find the right one |
| Forgetting docker0 | Rules won't work | Make sure HOME_NET is docker network, not docker0 |
| Editing during running | Changes don't apply | Stop containers first, then edit |
| Typos in subnet | Network not recognized | Double-check subnet format: X.X.X.0/24 |

---

## 📝 Quick Update Commands (Copy & Paste)

**Assuming:**
- Ubuntu IP: 192.168.1.100
- Interface: eth0
- Docker subnet: 172.20.0.0/16

```bash
# All in one:
sed -i "s/DVWA_HOST=.*/DVWA_HOST=192.168.1.100/" web-waf/.env && \
sed -i "s/NETWORK_INTERFACE=.*/NETWORK_INTERFACE=eth0/" suricata/.env && \
sed -i "s/interface: eth0$/interface: eth0/" suricata/docker-compose.yml && \
sed -i "s/interface: eth0$/interface: eth0/" suricata/configs/suricata.yaml && \
echo "✓ All configs updated!"
```

---

## 🎯 What Each IP Controls

### DVWA_HOST (web-waf/.env)
- **Effect**: Where you access the DVWA web application from
- **Value**: Ubuntu Server IP or localhost (if testing locally)
- **Example**: http://192.168.1.100/
- **Import**: No, this is just for reference/documentation

### HOME_NET (suricata/.env + suricata.yaml)
- **Effect**: Which networks Suricata considers "home" (internal)
- **Value**: Docker subnet where DVWA/MySQL run
- **Example**: 172.20.0.0/16
- **Important**: Must match your Docker network

### NETWORK_INTERFACE (suricata/.env + docker-compose.yml + suricata.yaml)
- **Effect**: Which physical interface Suricata sniffs on
- **Value**: Your network port name
- **Example**: eth0
- **Important**: Wrong interface = no traffic detection!

---

## 🚀 Ready to Deploy?

```
✅ Updated DVWA_HOST in web-waf/.env
✅ Updated HOME_NET in suricata/.env
✅ Updated NETWORK_INTERFACE in suricata/.env
✅ Updated interface in suricata/docker-compose.yml
✅ Updated HOME_NET and interface in suricata/configs/suricata.yaml

→ Run: bash deploy.sh
```

---

**Last Updated**: March 4, 2026
