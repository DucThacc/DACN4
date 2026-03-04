#!/bin/bash

# Test Network Scanning Detection
# ================================

# ⚠️ THAY ĐỔI: Đổi localhost thành IP của Ubuntu Server
TARGET="localhost"
LOG_DIR="../suricata/logs"

echo "=========================================="
echo "Network Scan Detection Test"
echo "=========================================="
echo ""

# Check if Nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "❌ Nmap not installed"
    echo "Install: sudo apt-get install nmap"
    exit 1
fi

echo "[*] Waiting for scan detection..."
echo ""

# Test 1: SYN Scan
echo "[*] Test 1: SYN Scan (-sS)"
sudo nmap -sS -p 80,3306,443 $TARGET 2>&1 | tail -10
echo ""
sleep 3

# Test 2: Version Detection
echo "[*] Test 2: Version Detection (-sV)"
sudo nmap -sV -p 80 $TARGET 2>&1 | tail -10
echo ""
sleep 3

# Test 3: Service Discovery
echo "[*] Test 3: Service Discovery (-A)"
sudo nmap -A -p 80,3306 $TARGET 2>&1 | tail -10
echo ""
sleep 3

# Test 4: UDP Scan
echo "[*] Test 4: UDP Scan (-sU)"
sudo nmap -sU -p 53 $TARGET 2>&1 | tail -10
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
echo ""
echo "Check Suricata eve.json for alerts:"
echo "  tail -f $LOG_DIR/eve.json | jq 'select(.alert.signature | contains(\"SCAN\") or contains(\"Nmap\"))'"
echo ""
echo "Count scan alerts:"
echo "  cat $LOG_DIR/eve.json | jq 'select(.event_type == \"alert\")' | jq -s 'length'"
