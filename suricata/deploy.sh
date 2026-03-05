#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODE="${1:-ids}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Suricata Deploy (IDS/IPS)${NC}"
echo -e "${BLUE}========================================${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not installed${NC}"
    exit 1
fi

if docker compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Using Docker Compose v2${NC}"
elif docker-compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ Using Docker Compose v1${NC}"
else
    echo -e "${RED}❌ Docker Compose not found${NC}"
    exit 1
fi

mkdir -p logs

$DOCKER_COMPOSE_CMD up -d

echo -e "${YELLOW}[*] Waiting service...${NC}"
sleep 5

if docker ps | grep -q suricata-ids; then
    echo -e "${GREEN}✓ Suricata container running${NC}"
fi

if [[ "$MODE" == "ips" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ IPS mode requires root privileges${NC}"
        echo -e "${YELLOW}   Run: sudo bash deploy.sh ips${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[*] Enabling IPS mode...${NC}"

    modprobe nf_queue 2>/dev/null || true
    iptables -I INPUT 1 -j NFQUEUE --queue-num 0 2>/dev/null || true
    iptables -I FORWARD 1 -j NFQUEUE --queue-num 0 2>/dev/null || true

    sed -i 's/mode: idsmode/mode: ipsmode/' configs/suricata.yaml
    $DOCKER_COMPOSE_CMD restart suricata

    echo -e "${GREEN}✓ IPS mode enabled${NC}"
else
    echo -e "${YELLOW}[*] Running in IDS mode${NC}"
fi

echo ""
echo -e "${GREEN}✓ Suricata deployment complete${NC}"
echo -e "    Logs: $(pwd)/logs/eve.json"
