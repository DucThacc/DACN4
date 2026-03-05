#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Web-WAF Deploy (DVWA + ModSecurity + MySQL)${NC}"
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

mkdir -p logs/modsec_audit logs/apache_access

$DOCKER_COMPOSE_CMD up -d

echo -e "${YELLOW}[*] Waiting services...${NC}"
sleep 10

if docker ps | grep -q dvwa-app; then
    echo -e "${GREEN}✓ DVWA container running${NC}"
fi

if docker ps | grep -q mysql-dvwa; then
    echo -e "${GREEN}✓ MySQL container running${NC}"
fi

DVWA_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dvwa-app 2>/dev/null || true)

echo ""
echo -e "${GREEN}✓ Web-WAF deployment complete${NC}"
echo -e "    DVWA: http://localhost/ (or http://${DVWA_IP}/)"
echo -e "    Logs: $(pwd)/logs/modsec_audit/"
echo -e "    Logs: $(pwd)/logs/apache_access/"
