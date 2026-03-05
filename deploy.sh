#!/bin/bash

# Root dispatcher script for VulnApp
# ==================================

set -e

# Colors
RED='\033[0;31m'
echo -e "${BLUE}VulnApp - Deployment Dispatcher${NC}"
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  bash deploy.sh web"
    echo -e "  bash deploy.sh suricata"
    echo -e "  bash deploy.sh suricata ips"
    echo -e ""
    echo -e "${YELLOW}Khuyến nghị chạy tách riêng để nhẹ hơn:${NC}"
    echo -e "  cd web-waf && bash deploy.sh"
    echo -e "  cd suricata && bash deploy.sh [ips]"
    echo -e ""
    echo -e "${YELLOW}Lưu ý:${NC} script gốc này chỉ điều hướng, không deploy cả 2 cùng lúc nữa."
}

TARGET="$1"
MODE="$2"

case "$TARGET" in
    web)
        exec bash web-waf/deploy.sh
        ;;
    suricata)
        if [[ "$MODE" == "ips" ]]; then
            exec bash suricata/deploy.sh ips
        fi
        exec bash suricata/deploy.sh
        ;;
    ""|-h|--help|help)
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid target: $TARGET${NC}"
        show_usage
        exit 1
        ;;
esac
echo -e "      --modsec web-waf/logs/modsec_audit/audit.log"
echo ""
echo -e "${YELLOW}[*] MONITOR REAL-TIME:${NC}"
echo -e "    tail -f suricata/logs/eve.json | jq '.'${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
