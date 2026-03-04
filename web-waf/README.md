# Web-WAF Configuration Guide

## Overview
Folder này chứa DVWA (Damn Vulnerable Web Application) + ModSecurity (WAF) + MySQL

---

## ⚠️ IP Configuration Points

### File: `.env`
```bash
# Thay đổi IP theo Ubuntu Server của bạn
DVWA_HOST=192.168.1.100    # ← IP của Ubuntu Server
MYSQL_HOST=mysql            # (Giữ nguyên - Docker internal)
```

### File: `docker-compose.yml`
```yaml
services:
  dvwa:
    ports:
      - "80:80"  # DVWA accessible on port 80
      
    # Nếu port 80 bị chiếm:
    # ports:
    #   - "8080:80"  # Access tại http://localhost:8080
```

---

## 🚀 Quick Start

```bash
cd web-waf

# Create log directories
mkdir -p logs/{modsec_audit,apache_access}

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View DVWA (get IP)
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa-app
# Access at: http://<IP>/
```

---

## 🔐 ModSecurity Configuration

### Detection vs Blocking

**File**: `configs/modsecurity/modsecurity.conf`

**Detection Mode (Default)**
```apache
SecRuleEngine DetectionOnly  # ← Logs attacks but doesn't block
```

**Blocking Mode**
```apache
SecRuleEngine On  # ← Blocks detected attacks (response 403)
```

### Enable Blocking
```bash
# Edit modsecurity.conf
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' \
  configs/modsecurity/modsecurity.conf

# Restart
docker-compose restart dvwa

# Check logs
tail -f logs/modsec_audit/audit.log
```

---

## 📊 Monitoring

### Real-time Logs
```bash
# ModSecurity audit log
tail -f logs/modsec_audit/audit.log

# Apache access log
tail -f logs/apache_access/access.log

# Container logs
docker-compose logs -f
```

### Statistics
```bash
# Count detections
wc -l logs/modsec_audit/audit.log

# Filter by attack type
grep -c "SQL Injection" logs/modsec_audit/audit.log
grep -c "XSS" logs/modsec_audit/audit.log

# Top rules triggered
grep "msg" logs/modsec_audit/audit.log | \
  sed "s/.*msg '//" | \
  sed "s/'.*$//" | \
  sort | uniq -c | sort -rn | head -10
```

---

## 🧪 Testing

### SQL Injection
```bash
# Detection mode (should appear in logs)
curl "http://localhost/vulnerabilities/sqli/?id=1' UNION SELECT 1--"

# Check detection
grep "SQL Injection" logs/modsec_audit/audit.log
```

### XSS
```bash
curl "http://localhost/vulnerabilities/xss_r/?name=<script>alert('XSS')</script>"
```

### Automated Tests
```bash
bash scripts/test_sqli.sh
bash scripts/test_xss.sh
bash scripts/test_lfi.sh
```

---

## 🔧 Customizing Rules

### Add Custom Rule
**File**: `configs/modsecurity/modsecurity.conf` (at the end)

```apache
# Example: Block requests with "drop database" in any parameter
SecRule ARGS "@rx drop\s+database" \
    "id:3001,phase:2,deny,status:403,\
    msg:'SQL Injection - DROP DATABASE Attempt',\
    tag:'attack/sqli'"
```

### Whitelist False Positives
```apache
# Example: Whitelist DVWA admin panel
SecRule REQUEST_URI "@beginsWith /vulnerabilities/admin/" \
    "id:3002,phase:1,pass,ctl:RuleEngine=Off"
```

Apply changes:
```bash
docker-compose restart dvwa
# Wait for Apache to restart
sleep 5
tail -f logs/modsec_audit/audit.log
```

---

## 📝 Advanced Configuration

### Paranoia Level
**File**: `configs/modsecurity/crs-setup.conf`

```apache
# Levels: 1 (lenient) to 4 (strict)
SecAction \
    "id:900000, \
    phase:1, \
    nolog, pass, \
    setvar:tx.paranoia_level=1"
```

Higher levels = more detections but higher false positives

### Anomaly Scoring Threshold
```apache
SecAction \
    "id:900001, \
    phase:1, \
    setvar:tx.anomaly_score_threshold=5"
```

Block if score >= threshold

---

## 📂 File Structure

```
.
├── docker-compose.yml          ← Start here
├── Dockerfile                  ← Custom DVWA image
├── .env                        ← Environment (⚠️ Edit IP here)
├── configs/
│   └── modsecurity/
│       ├── modsecurity.conf    ← Main WAF config
│       ├── default.conf        ← Apache vhost
│       └── crs-setup.conf      ← OWASP CRS
├── logs/
│   ├── modsec_audit/           ← ModSecurity logs
│   └── apache_access/          ← Apache access logs
└── scripts/
    ├── test_sqli.sh
    ├── test_xss.sh
    ├── test_lfi.sh
    └── analyze_logs.py
```

---

## 🆘 Troubleshooting

### DVWA won't start
```bash
docker-compose logs dvwa-app
docker-compose ps
```

### MySQL connection failed
```bash
# Check MySQL is running
docker-compose ps mysql

# Check credentials
docker logs mysql-dvwa

# Restart stack
docker-compose restart
docker-compose logs
```

### ModSecurity not detecting
```bash
# Check rule engine is enabled
grep "SecRuleEngine" configs/modsecurity/modsecurity.conf

# Check audit log is being written
ls -lah logs/modsec_audit/

# Verify ModSecurity module loaded
docker exec dvwa-app apache2ctl -M | grep security
```

### High CPU/Memory usage
```bash
# Reduce logging detail
sed -i 's/SecAuditLogType Concurrent/SecAuditLogType Serial/' \
  configs/modsecurity/modsecurity.conf

# Disable full body logging
echo "SecAuditLogParts ABDEFHIJKZ" >> configs/modsecurity/modsecurity.conf

docker-compose restart dvwa
```

---

## 📊 Log Analysis

### ModSecurity Audit Log Format
```
Rule ID: [Rule number]
Message: [Detection message]
Phase: [Phase 1-5]
Status: [200/403/etc]
IP: [Source IP]
Request: [HTTP method and URI]
```

### Parse JSON from logs
```bash
# If using JSON format
cat logs/modsec_audit/audit.log | jq '.'

# Count by rule
cat logs/modsec_audit/audit.log | \
  jq '.audit_data.matched_rules[].message' | \
  sort | uniq -c | sort -rn
```

---

## 🔄 Integration with Suricata

ModSecurity works independently but coordinates with Suricata:

1. **ModSecurity (Layer 7)**: Blocks HTTP-based attacks
2. **Suricata (Layer 3-4)**: Detects network-level attacks

Both should flag same attacks for correlation analysis.

### Cross-check logs
```bash
# Find attacks detected by both
ATTACK_IP="192.168.1.50"
grep "$ATTACK_IP" logs/modsec_audit/audit.log
grep "$ATTACK_IP" ../suricata/logs/eve.json | jq '.src_ip'
```

---

## 📈 Performance Tuning

For 8GB RAM system:

### Reduce memory footprint
```bash
# Edit docker-compose.yml
dvwa:
  mem_limit: 256m  # Reduce from 512m
  memswap_limit: 256m
```

### Optimize ModSecurity
```apache
# In modsecurity.conf:
# Reduce request body limit
SecRequestBodyLimit 10485760  # 10MB instead of 100MB

# Disable audit log if not needed
SecAuditEngine Off
```

---

## 📚 References

- [ModSecurity Documentation](https://github.com/SpiderLabs/ModSecurity)
- [OWASP CRS](https://coreruleset.org/)
- [DVWA](https://github.com/digininja/DVWA)
- [Apache ModSecurity Rules](https://github.com/SpiderLabs/ModSecurity-Rules)

---

**Last Updated**: March 2026
