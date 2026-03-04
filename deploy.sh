#!/bin/bash

# Complete deployment script for VulnApp
# ======================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VulnApp - Complete Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[*] Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not installed${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq not installed (recommended for log analysis)${NC}"
    echo -e "${YELLOW}   Install: sudo apt-get install jq${NC}"
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Check if running as root for IPS mode
if [[ "$1" == "ips" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ IPS mode requires root privileges${NC}"
        echo -e "${YELLOW}   Run: sudo bash deploy.sh ips${NC}"
        exit 1
    fi
fi

# Step 1: Deploy Web-WAF
echo -e "${BLUE}[Step 1/3] Deploying Web-WAF stack...${NC}"
cd web-waf

# Create log directories
mkdir -p logs/modsec_audit logs/apache_access

# Start services
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Web-WAF services started${NC}"
else
    echo -e "${RED}❌ Failed to start Web-WAF services${NC}"
    exit 1
fi

# Wait for services to be ready
echo -e "${YELLOW}[*] Waiting for services to be ready...${NC}"
sleep 10

# Health check
echo -e "${YELLOW}[*] Health check...${NC}"
if docker ps | grep -q dvwa-app; then
    echo -e "${GREEN}✓ DVWA container running${NC}"
fi

if docker ps | grep -q mysql-dvwa; then
    echo -e "${GREEN}✓ MySQL container running${NC}"
fi

# Get DVWA IP
DVWA_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa-app)
echo -e "${GREEN}✓ DVWA IP: $DVWA_IP${NC}"

cd ..

# Step 2: Deploy Suricata
echo ""
echo -e "${BLUE}[Step 2/3] Deploying Suricata IDS...${NC}"
cd suricata

# Create log directory
mkdir -p logs

# Start Suricata
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Suricata service started${NC}"
else
    echo -e "${RED}❌ Failed to start Suricata${NC}"
    exit 1
fi

sleep 5

if docker ps | grep -q suricata-ids; then
    echo -e "${GREEN}✓ Suricata container running${NC}"
fi

cd ..

# Step 3: Configuration Modes
echo ""
echo -e "${BLUE}[Step 3/3] Configuration...${NC}"

if [[ "$1" == "ips" ]]; then
    echo -e "${YELLOW}[*] Enabling IPS mode...${NC}"
    
    # Load nfqueue module
    modprobe nf_queue 2>/dev/null || true
    
    # Add iptables rules
    iptables -I INPUT 1 -j NFQUEUE --queue-num 0 2>/dev/null || true
    iptables -I FORWARD 1 -j NFQUEUE --queue-num 0 2>/dev/null || true
    
    # Update Suricata config
    sed -i 's/mode: idsmode/mode: ipsmode/' suricata/configs/suricata.yaml
    docker-compose -f suricata/docker-compose.yml restart suricata
    
    echo -e "${GREEN}✓ IPS mode enabled${NC}"
else
    echo -e "${YELLOW}[*] Operating in IDS mode (detection only)${NC}"
    echo -e "${YELLOW}   To switch to IPS mode: sudo bash deploy.sh ips${NC}"
fi

# Step 4: Print summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}[*] SERVICE INFORMATION:${NC}"
echo -e "    DVWA:  http://localhost/ (or http://$DVWA_IP/)"
echo -e "    MySQL: localhost:3306 (dvwa/dvwa)"
echo -e "    Suricata: Listening on network interface (eth0)"
echo ""
echo -e "${YELLOW}[*] IMPORTANT - CONFIGURATION IPs TO UPDATE:${NC}"
echo -e "    ${RED}⚠️  UPDATE THESE FOR UBUNTU SERVER:${NC}"
echo -e "    1. web-waf/.env:"
echo -e "       DVWA_HOST=<Ubuntu_Server_IP>"
echo -e ""
echo -e "    2. suricata/.env:"
echo -e "       HOME_NET=<Docker_Network_Range>"
echo -e ""
echo -e "    3. suricata/docker-compose.yml:"
echo -e "       command: suricata -c ... -i <INTERFACE>"
echo -e "       (Get interface: ip link show)"
echo ""
echo -e "${YELLOW}[*] LOG LOCATIONS:${NC}"
echo -e "    ModSecurity: $(pwd)/web-waf/logs/modsec_audit/"
echo -e "    Apache:      $(pwd)/web-waf/logs/apache_access/"
echo -e "    Suricata:    $(pwd)/suricata/logs/"
echo ""
echo -e "${YELLOW}[*] QUICK TESTS:${NC}"
echo -e "    SQL Injection: bash web-waf/scripts/test_sqli.sh"
echo -e "    XSS:           bash web-waf/scripts/test_xss.sh"
echo -e "    LFI:           bash web-waf/scripts/test_lfi.sh"
echo -e "    Nmap Scan:     bash web-waf/scripts/test_nmap.sh"
echo ""
echo -e "${YELLOW}[*] LOG ANALYSIS:${NC}"
echo -e "    python3 web-waf/scripts/analyze_logs.py \\"
echo -e "      --suricata suricata/logs/eve.json \\"
echo -e "      --modsec web-waf/logs/modsec_audit/audit.log"
echo ""
echo -e "${YELLOW}[*] MONITOR REAL-TIME:${NC}"
echo -e "    tail -f suricata/logs/eve.json | jq '.'${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
