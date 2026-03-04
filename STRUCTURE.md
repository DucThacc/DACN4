# Project Structure Documentation

## Directory Tree

```
VulnApp/
│
├── 📄 README.md                     ← START HERE - Main documentation
├── 📄 QUICKREF.md                   ← Quick reference card for common tasks
├── 📄 .gitignore                    ← Git ignore file
├── 📄 deploy.sh                     ← Master deployment script
│
│
├── 📁 web-waf/                      ← Web Application + WAF Stack
│   ├── 📄 README.md                 ← Web-WAF specific guide
│   ├── 📄 docker-compose.yml        ← Service definitions (MySQL + DVWA)
│   ├── 📄 Dockerfile                ← Custom DVWA image with ModSecurity
│   ├── 📄 .env                      ← Environment variables ⚠️ EDIT FOR UBUNTU IP
│   │
│   ├── 📁 configs/
│   │   └── 📁 modsecurity/
│   │       ├── 📄 modsecurity.conf  ← ModSecurity main configuration
│   │       ├── 📄 default.conf      ← Apache vhost configuration
│   │       └── 📄 crs-setup.conf    ← OWASP CRS setup
│   │
│   ├── 📁 logs/                     ← Auto-generated log directory
│   │   ├── 📁 modsec_audit/         ← ModSecurity audit logs
│   │   └── 📁 apache_access/        ← Apache access logs
│   │
│   └── 📁 scripts/
│       ├── 📄 test_sqli.sh          ← SQL Injection test script
│       ├── 📄 test_xss.sh           ← XSS test script
│       ├── 📄 test_lfi.sh           ← Local File Inclusion test script
│       ├── 📄 test_nmap.sh          ← Network scan test script
│       └── 🐍 analyze_logs.py       ← Log analysis Python script
│
│
├── 📁 suricata/                     ← Network IDS/IPS Stack
│   ├── 📄 README.md                 ← Suricata specific guide
│   ├── 📄 docker-compose.yml        ← Suricata service definition ⚠️ EDIT INTERFACE
│   ├── 📄 .env                      ← Environment variables ⚠️ EDIT FOR YOUR NETWORK
│   │
│   ├── 📁 configs/
│   │   └── 📄 suricata.yaml         ← Suricata main configuration ⚠️ EDIT FOR YOUR NETWORK
│   │
│   ├── 📁 rules/
│   │   └── 📄 custom-rules.rules    ← Custom detection rules for DVWA attacks
│   │
│   └── 📁 logs/                     ← Auto-generated log directory
│       ├── 📄 eve.json              ← Suricata alerts in JSON format
│       ├── 📄 stats.log             ← Runtime statistics
│       └── (other generated logs)
│
└── (End of structure)
```

---

## File Purposes & Edit Guidelines

### Root Level Files

| File | Purpose | Edit? |
|------|---------|-------|
| **README.md** | Comprehensive deployment & usage guide | ❌ No |
| **QUICKREF.md** | Quick reference commands | ❌ No |
| **.gitignore** | Git exclusions | ❌ No |
| **deploy.sh** | Main deployment automation script | ❌ No |

---

### web-waf/ Directory

| File | Purpose | Edit? | When |
|------|---------|-------|------|
| **README.md** | WAF-specific documentation | ❌ No | - |
| **docker-compose.yml** | Service configuration | ✅ Yes | To change port mappings |
| **Dockerfile** | DVWA image definition | ✅ Maybe | To customize image |
| **.env** | Environment variables | ⚠️ `MUST` | To set Ubuntu Server IP |
| **configs/modsecurity.conf** | WAF rules and logging | ✅ Yes | To customize rules/blocking |
| **configs/default.conf** | Apache vhost config | ✅ Maybe | For TLS/advanced setup |
| **configs/crs-setup.conf** | OWASP CRS parameters | ✅ Maybe | To tune paranoia level |
| **logs/** | Generated log files | 📖 Read | For analysis only |
| **scripts/test_*.sh** | Test automation | ⚠️ `MUST` | Update target IP |
| **scripts/analyze_logs.py** | Log analysis tool | ❌ No | - |

---

### suricata/ Directory

| File | Purpose | Edit? | When |
|------|---------|-------|------|
| **README.md** | Suricata-specific documentation | ❌ No | - |
| **docker-compose.yml** | Suricata service config | ⚠️ `MUST` | To set network interface |
| **.env** | Environment variables | ⚠️ `MUST` | To set HOME_NET and interface |
| **configs/suricata.yaml** | Main Suricata config | ⚠️ `MUST` | To set HOME_NET, interface, mode |
| **rules/custom-rules.rules** | Custom detection rules | ✅ Yes | To add/modify rules |
| **logs/eve.json** | Alert log (JSON) | 📖 Read | For analysis only |

---

## Configuration Checklist

### Before First Deployment

```
web-waf/
  ☐ .env - Update DVWA_HOST to Ubuntu IP
  ☐ scripts/test_*.sh - Update TARGET URL if needed
  ☐ docker-compose.yml - Verify port 80 is free

suricata/
  ☐ .env - Set HOME_NET and NETWORK_INTERFACE
  ☐ docker-compose.yml - Update interface name
  ☐ configs/suricata.yaml - Update HOME_NET and interface
```

---

## Log File Locations

### WAF Logs (ModSecurity)
```
web-waf/logs/modsec_audit/audit.log
  - Attack detections
  - Rule triggers
  - Alert messages
  Format: Text (or JSON if configured)
```

### Web Server Logs (Apache)
```
web-waf/logs/apache_access/access.log
  - HTTP requests
  - Response codes
  - Performance metrics
  Format: Apache Combined Log Format
```

### Network IDS Logs (Suricata)
```
suricata/logs/eve.json
  - Network alerts
  - Attack signatures matched
  - Flow information
  - HTTP/DNS/TLS details
  Format: JSON (one object per line)

suricata/logs/stats.log
  - Performance statistics
  - Packet counts
  - Alert counts
  Format: Text
```

---

## Network Communication Flow

```
┌─────────────┐
│ Attacker    │
│ (Kali/Host) │
└──────┬──────┘
       │ (HTTP requests with attacks)
       ▼
┌──────────────────────────────────────────────────┐
│      DOCKER HOST (Ubuntu Server)                 │
│                                                   │
│  ┌────────────────────────────────────────────┐ │
│  │ Suricata (Network IDS/IPS)                 │ │
│  │ - Sniffs all packets                        │ │
│  │ - Detects network attacks                   │ │
│  │ Logs → eve.json                             │ │
│  └────────────────────────────────────────────┘ │
│                   ▲                               │
│                   │ (all traffic passes through) │
│  ┌────────────────┴──────────────────────────┐  │
│  │ Docker Bridge Network (172.20.0.0/16)    │  │
│  │                                            │  │
│  │  ┌───────────────┐    ┌──────────────┐   │  │
│  │  │ Apache+        │    │   MySQL      │   │  │
│  │  │ ModSecurity    │◄──►│   Database   │   │  │
│  │  │ (WAF)          │    │              │   │  │
│  │  │ Port: 80       │    │ Port: 3306   │   │  │
│  │  │                │    │              │   │  │
│  │  │ DVWA Web App   │    │ dvwa/dvwa    │   │  │
│  │  │ (Detection)    │    │              │   │  │
│  │  │ Logs →         │    └──────────────┘   │  │
│  │  │ modsec_audit/  │                        │  │
│  │  │ audit.log      │                        │  │
│  │  └───────────────┘                        │  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                   │
└──────────────────────────────────────────────────┘
        ▲              ▲                  ▲
        │              │                  │
  HTTP Requests    Alerts        Analysis/Monitoring
```

---

## Volume Mounts

### web-waf Services

```yaml
dvwa:
  volumes:
    # Config (read-only from container)
    - ./configs/modsecurity/modsecurity.conf:/etc/apache2/mods-available/modsecurity.conf:ro
    - ./configs/modsecurity/crs-setup.conf:/usr/share/modsecurity-crs/crs-setup.conf:ro
    - ./configs/modsecurity/default.conf:/etc/apache2/sites-enabled/000-default.conf:ro
    
    # Logs (writable from container)
    - ./logs/modsec_audit:/var/log/modsec/:rw
    - ./logs/apache_access:/var/log/apache2/:rw

mysql:
  volumes:
    # Database persistence
    - mysql_data:/var/lib/mysql
```

### suricata Service

```yaml
suricata:
  volumes:
    # Config (read-only)
    - ./configs/suricata.yaml:/etc/suricata/suricata.yaml:ro
    
    # Rules (read-write for updates)
    - ./rules:/var/lib/suricata/rules:rw
    
    # Logs (writable)
    - ./logs:/var/log/suricata/:rw
```

---

## Environment Variables

### web-waf/.env
```
MYSQL_ROOT_PASSWORD=root           # MySQL admin password
MYSQL_DATABASE=dvwa                # Database name
MYSQL_USER=dvwa                    # Database user
MYSQL_PASSWORD=dvwa                # Database password
MYSQL_HOSTNAME=mysql               # Container name (DNS resolution)
DVWA_HOST=localhost                # ⚠️ Change to Ubuntu IP
MYSQL_HOST=mysql                   # ⚠️ Keep as is (Docker internal)
```

### suricata/.env
```
HOME_NET=172.20.0.0/16             # ⚠️ Docker network subnet
EXTERNAL_NET=!$HOME_NET            # Everything else
NETWORK_INTERFACE=eth0             # ⚠️ Your network interface
SURICATA_MODE=idsmode              # idsmode or ipsmode
```

---

## Performance Specifications

### Memory Allocation (8GB System)

```
OS/System        : ~2GB
├─ MySQL         : 256MB (max 512MB)
├─ DVWA+Apache   : 512MB (max 768MB)
├─ Suricata      : 768MB (max 1GB)
└─ Buffer/misc   : ~1GB
───────────────────────────
Total Usage     : ~3.5GB (Safe margin to 8GB)
```

---

## Quick Command Reference

```bash
# Deploy
bash deploy.sh                    # Full deployment
bash deploy.sh ips               # Deploy with IPS mode

# Status
docker-compose ps                # All containers
docker stats                      # Resource usage
docker logs <container>           # Container logs

# Testing
cd web-waf && bash scripts/test_sqli.sh
cd web-waf && bash scripts/test_xss.sh

# Logs
tail -f suricata/logs/eve.json | jq '.'
tail -f web-waf/logs/modsec_audit/audit.log

# Cleanup
docker-compose down               # Stop services
docker volume prune              # Remove unused volumes
docker system prune              # Clean everything (CAREFUL!)
```

---

## Modification Impact

### Low Risk (Safe to modify)
- ✅ Custom rules (custom-rules.rules)
- ✅ Test scripts (shell scripts)
- ✅ Log analysis scripts

### Medium Risk (May require restart)
- ⚠️ Configuration parameters
- ⚠️ ModSecurity rules
- ⚠️ Suricata parameters

### High Risk (Know what you're doing)
- 🔴 Dockerfile modifications
- 🔴 docker-compose.yml structure
- 🔴 Network configuration

---

**For detailed information, see:**
- Main README: [README.md](README.md)
- WAF Guide: [web-waf/README.md](web-waf/README.md)
- IDS Guide: [suricata/README.md](suricata/README.md)
- Quick Ref: [QUICKREF.md](QUICKREF.md)

---

**Last Updated**: March 2026
