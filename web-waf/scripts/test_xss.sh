#!/bin/bash

# Test XSS Detection
# ==================

# ⚠️ THAY ĐỔI: Đổi localhost thành IP của Ubuntu Server
TARGET="http://localhost"
LOG_DIR="../suricata/logs"

echo "=========================================="
echo "XSS Detection Test"
echo "=========================================="
echo ""

# Test 1: Script tag injection
echo "[*] Test 1: Script tag XSS"
curl -s "$TARGET/vulnerabilities/xss_r/?name=<script>alert('XSS')</script>" -v 2>&1 | head -20
echo ""
echo "[+] ModSecurity should detect script tag"
sleep 2

# Test 2: Event handler XSS
echo "[*] Test 2: Event handler XSS"
curl -s "$TARGET/vulnerabilities/xss_r/?name=<img src=x onerror=alert('XSS')>" -v 2>&1 | head -20
echo ""
sleep 2

# Test 3: JavaScript protocol
echo "[*] Test 3: JavaScript protocol XSS"
curl -s "$TARGET/vulnerabilities/xss_r/?name=<a href=\"javascript:alert('XSS')\">click</a>" -v 2>&1 | head -20
echo ""
sleep 2

# Test 4: SVG-based XSS
echo "[*] Test 4: SVG-based XSS"
curl -s "$TARGET/vulnerabilities/xss_r/?name=<svg/onload=alert('XSS')>" -v 2>&1 | head -20
echo ""
sleep 2

# Test 5: HTML entity encoding bypass
echo "[*] Test 5: HTML entity encoding bypass"
curl -s "$TARGET/vulnerabilities/xss_r/?name=%3Cscript%3Ealert('XSS')%3C/script%3E" -v 2>&1 | head -20
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
echo ""
echo "Check ModSecurity audit log:"
echo "  tail -f ../web-waf/logs/modsec_audit/audit.log"
echo ""
echo "Check Suricata eve.json:"
echo "  tail -f $LOG_DIR/eve.json | jq 'select(.alert.signature | contains(\"XSS\"))'"
