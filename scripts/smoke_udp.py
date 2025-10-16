#!/usr/bin/env python3

import socket
import sys


def send_snmp_get(udp_host, udp_port):
    # SNMP v2c Get Request packet for sysUpTime (1.3.6.1.2.1.1.3.0) with community 'public'
    pkt = bytes.fromhex(
        "301c02010004067075626c6963a00f02040000000102010002010030053003060a2b06010201010300"
    )

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2)

    try:
        sock.sendto(pkt, (udp_host, udp_port))
        data, _ = sock.recvfrom(4096)
        if data:
            return True
    except Exception as e:
        print(f"Error: {e}")
    return False


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <host> <port>")
        sys.exit(1)

    host = sys.argv[1]
    port = int(sys.argv[2])

    if send_snmp_get(host, port):
        print(f"SNMP GET request to {host}:{port} succeeded")
        sys.exit(0)
    else:
        print(f"SNMP GET request to {host}:{port} failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
