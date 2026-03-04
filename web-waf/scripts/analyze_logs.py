#!/usr/bin/env python3

import json
import sys
from collections import defaultdict
from datetime import datetime
import argparse

def analyze_suricata_logs(log_file):
    """Analyze Suricata EVE JSON logs"""
    alerts = defaultdict(int)
    sources = defaultdict(int)
    destinations = defaultdict(int)
    protocols = defaultdict(int)
    
    print("=" * 60)
    print("SURICATA EVE.JSON ANALYSIS")
    print("=" * 60)
    
    try:
        with open(log_file, 'r') as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    
                    # Alert analysis
                    if entry.get('event_type') == 'alert':
                        sig = entry.get('alert', {}).get('signature', 'Unknown')
                        alerts[sig] += 1
                        src = entry.get('src_ip', 'Unknown')
                        dst = entry.get('dest_ip', 'Unknown')
                        proto = entry.get('proto', 'Unknown')
                        
                        sources[src] += 1
                        destinations[dst] += 1
                        protocols[proto] += 1
                        
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        print(f"❌ File not found: {log_file}")
        return
    
    # Print results
    print("\n[+] TOP ALERTS:")
    for sig, count in sorted(alerts.items(), key=lambda x: -x[1])[:15]:
        print(f"    {count:4d}x - {sig}")
    
    print(f"\n[+] SOURCE IPs ({len(sources)}):")
    for src, count in sorted(sources.items(), key=lambda x: -x[1])[:10]:
        print(f"    {count:4d}x - {src}")
    
    print(f"\n[+] DESTINATION IPs ({len(destinations)}):")
    for dst, count in sorted(destinations.items(), key=lambda x: -x[1])[:10]:
        print(f"    {count:4d}x - {dst}")
    
    print(f"\n[+] PROTOCOLS:")
    for proto, count in sorted(protocols.items(), key=lambda x: -x[1]):
        print(f"    {count:4d}x - {proto}")
    
    print(f"\n[+] TOTAL ALERTS: {sum(alerts.values())}")

def analyze_modsec_logs(log_file):
    """Analyze ModSecurity audit logs"""
    detections = defaultdict(int)
    blocked = 0
    detected = 0
    
    print("\n" + "=" * 60)
    print("ModSecurity AUDIT LOG ANALYSIS")
    print("=" * 60)
    
    try:
        with open(log_file, 'r') as f:
            content = f.read()
            
            # Parse JSON lines if available
            for line in content.split('\n'):
                if not line.strip():
                    continue
                
                try:
                    entry = json.loads(line)
                    
                    if 'audit_data' in entry:
                        action = entry.get('action', '')
                        if action == 'blocked':
                            blocked += 1
                        detected += 1
                        
                        # Extract signature
                        rules = entry.get('audit_data', {}).get('matched_rules', [])
                        for rule in rules:
                            msg = rule.get('message', 'Unknown')
                            detections[msg] += 1
                            
                except json.JSONDecodeError:
                    # Try parsing as traditional ModSecurity audit log
                    if 'msg' in line:
                        import re
                        match = re.search(r"msg\s'([^']+)'", line)
                        if match:
                            msg = match.group(1)
                            detections[msg] += 1
                            if 'denied' in line.lower():
                                blocked += 1
                    
    except FileNotFoundError:
        print(f"❌ File not found: {log_file}")
        return
    
    print("\n[+] TOP DETECTIONS:")
    for msg, count in sorted(detections.items(), key=lambda x: -x[1])[:15]:
        print(f"    {count:4d}x - {msg}")
    
    print(f"\n[+] STATISTICS:")
    print(f"    Detected: {detected}")
    print(f"    Blocked:  {blocked}")
    print(f"    Unique Rules: {len(detections)}")

def compare_logs():
    """Compare WAF vs IDS effectiveness"""
    print("\n" + "=" * 60)
    print("WAF vs IDS COMPARISON")
    print("=" * 60)
    print("\n[i] Tips for analysis:")
    print("    1. WAF (ModSecurity) blocks at HTTP layer")
    print("    2. IDS (Suricata) detects at network layer")
    print("    3. Both should flag same attacks")
    print("    4. Check for false positives in ModSecurity")
    print("    5. Verify Suricata catches all malicious traffic")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze security logs")
    parser.add_argument('--suricata', type=str, help='Path to Suricata eve.json')
    parser.add_argument('--modsec', type=str, help='Path to ModSecurity audit log')
    parser.add_argument('--compare', action='store_true', help='Show comparison tips')
    
    args = parser.parse_args()
    
    if args.suricata:
        analyze_suricata_logs(args.suricata)
    
    if args.modsec:
        analyze_modsec_logs(args.modsec)
    
    if args.compare or not (args.suricata or args.modsec):
        compare_logs()
    
    print("\n" + "=" * 60)
    print("Analysis complete!")
    print("=" * 60)
