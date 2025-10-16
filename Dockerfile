FROM python:3.12-slim

RUN set -eux; \
    groupadd -g 10001 snmpuser && useradd -m -u 10001 -g 10001 snmpuser

ENV PATH="/usr/local/bin:${PATH}"

WORKDIR /app

RUN pip install --no-cache-dir snmpsim pysnmp pyasn1 pyasn1-modules

RUN mkdir -p /app/config /app/datasets /app/scripts && chown -R 10001:10001 /app

COPY --chown=10001:10001 datasets/demo.snmprec /app/datasets/demo.snmprec
COPY --chown=10001:10001 config/agents.txt /app/config/agents.txt
COPY --chown=10001:10001 scripts/smoke_udp.py /app/scripts/smoke_udp.py

RUN chmod 755 /app/scripts/smoke_udp.py

USER 10001

EXPOSE 161/udp

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD python3 -c "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(2); pkt=bytes.fromhex('301c02010004067075626c6963a00f02040000000102010002010030053003060a2b06010201010300'); s.sendto(pkt,('127.0.0.1',161)); \
    import sys; \
    try: data=s.recv(4096); sys.exit(0 if data else 1); \
    except Exception: sys.exit(1)"

ENTRYPOINT ["snmpsim-command-responder"]

CMD ["--agent-udpv4-endpoint=0.0.0.0:161", "--data-dir", "/data"]
