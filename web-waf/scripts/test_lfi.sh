#!/bin/bash

# Test LFI Detection
# ==================

# ⚠️ THAY ĐỔI: Đổi localhost thành IP của Ubuntu Server
TARGET="http://localhost"
LOG_DIR="../suricata/logs"

echo "=========================================="
echo "LFI (Local File Inclusion) Detection Test"
echo "=========================================="
echo ""

# Test 1: Direct path traversal
echo "[*] Test 1: Direct path traversal"
curl -s "$TARGET/vulnerabilities/fi/?page=../../../../etc/passwd" -v 2>&1 | head -20
echo ""
sleep 2

# Test 2: Encoded path traversal
echo "[*] Test 2: Encoded path traversal (%2e%2e)"
curl -s "$TARGET/vulnerabilities/fi/?page=%2e%2e%2f%2e%2e%2fetc%2fpasswd" -v 2>&1 | head -20
echo ""
sleep 2

# Test 3: Windows path traversal
echo "[*] Test 3: Windows path traversal"
curl -s "$TARGET/vulnerabilities/fi/?page=..\\..\\windows\\system32\\drivers\\etc\\hosts" -v 2>&1 | head -20
echo ""
sleep 2

# Test 4: PHP wrapper (if applicable)
echo "[*] Test 4: PHP wrapper attack"
curl -s "$TARGET/vulnerabilities/fi/?page=php://filter/convert.base64-encode/resource=index.php" -v 2>&1 | head -20
echo ""
sleep 2

# Test 5: Log poisoning attempt
echo "[*] Test 5: Log file access"
curl -s "$TARGET/vulnerabilities/fi/?page=../../../../var/log/apache2/access.log" -v 2>&1 | head -20
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
echo ""
echo "Check ModSecurity audit log:"
echo "  tail -f ../web-waf/logs/modsec_audit/audit.log | grep -i 'traversal\\|lfi'"
echo ""
echo "Check Suricata eve.json:"
echo "  tail -f $LOG_DIR/eve.json | jq 'select(.alert.signature | contains(\"LFI\") or contains(\"Traversal\"))'"
