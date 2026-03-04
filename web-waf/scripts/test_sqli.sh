#!/bin/bash

# Test SQL Injection Detection
# ============================

# ⚠️ THAY ĐỔI: Đổi localhost thành IP của Ubuntu Server
TARGET="http://localhost"
LOG_DIR="../suricata/logs"

echo "=========================================="
echo "SQL Injection Detection Test"
echo "=========================================="
echo ""

# Test 1: UNION-based SQLi
echo "[*] Test 1: UNION-based SQL Injection"
curl -s "$TARGET/vulnerabilities/sqli/?id=1' UNION SELECT 1,2,3,4,5,6,7,8-- -" -v 2>&1 | head -20
echo ""
echo "[+] Check Suricata log:"
echo "    tail -f $LOG_DIR/eve.json | jq 'select(.alert.signature | contains(\"SQL\"))'"
sleep 2

# Test 2: OR-based SQLi
echo "[*] Test 2: OR-based SQL Injection"
curl -s "$TARGET/vulnerabilities/sqli/?id=1' OR '1'='1" -v 2>&1 | head -20
echo ""
sleep 2

# Test 3: Comment-based SQLi
echo "[*] Test 3: Comment-based SQL Injection"
curl -s "$TARGET/vulnerabilities/sqli/?id=1' --" -v 2>&1 | head -20
echo ""
sleep 2

# Test 4: Blind SQLi
echo "[*] Test 4: Blind SQL Injection"
curl -s "$TARGET/vulnerabilities/sqli/?id=1' AND SLEEP(5)-- -" -v 2>&1 | head -20
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
echo ""
echo "Check ModSecurity audit log:"
echo "  tail -f ../web-waf/logs/modsec_audit/audit.log"
echo ""
echo "Check Suricata eve.json:"
echo "  tail -f $LOG_DIR/eve.json | jq '.'"
