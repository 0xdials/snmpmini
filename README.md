# snmpmini: A Containerized SNMP Simulator (snmpsim)

This project packages [snmpsim](https://github.com/etingof/snmpsim) with [pysnmp](https://github.com/etingof/pysnmp) into a minimal container for easy SNMP device simulation, testing, and integration.

## Features

- Supports SNMPv1/v2c (default) and SNMPv3 USM (authPriv)
- Multiple agent endpoints in one process using `--args-from-file`
- Variation modules support (e.g., `numeric`, `notification`)
- Read-only or writable datasets with `.snmprec` data files
- Runs as a non-root user (UID 10001) for improved security
- Lightweight container based on `python:3.12-slim`
- Healthcheck using Python standard library UDP SNMP GET on localhost

## Quickstart

### Using the image from GHCR

Run the container. The default is SNMP v2.

```sh
docker run --rm -p 161:161/udp ghcr.io/yourorg/snmpmini:latest
```

Test with:

```sh
snmpwalk -v2c -c demo -ObentU 127.0.0.1:161
```

### Run SNMP v3

Run with explicit SNMP v3 flags:

```sh
docker run --rm -p 161:161/udp ghcr.io/yourorg/snmpmini:latest \
  --agent-udpv4-endpoint=0.0.0.0:161 \
  --data-dir=/data \
  --v3-user=snmpsim \
  --v3-auth-key=authpassword \
  --v3-priv-key=privpassword
```

Test with:

```sh
snmpwalk -v3 -u snmpsim -l authPriv -a MD5 -A authpassword -x DES -X privpassword 127.0.0.1:161
```

### Running multiple agents

```sh
make run-multi
```

- Uses config file `config/agents.txt` for multiple endpoints
- Each endpoint shares the same dataset mounted at `/data`

### Run SNMP v3 USM agent (authPriv example)

```sh
make run-v3
```

If you want to run SNMP v3 instead, you have to explicitly supply the v3 flags when running the container since the image itself defaults to v2. For example:

```sh
docker run <image> --v3-user=snmpsim --v3-auth-key=authpassword --v3-priv-key=privpassword
```

Same default user and keys as before, but now you get proper SNMP v3 handling. The container figures out based on the flags you pass whether to do v2 or v3.

### Use variation modules

To use variation modules, add `--variation-modules` flags when running the container. For example:

```sh
docker run --rm -p 161:161/udp \
  -v $(PWD)/datasets:/data:ro snmpsim:dev \
  --variation-modules=numeric,notification --data-dir=/data
```

---

### TL;DR

- Defaults to SNMP v2 unless you provide SNMP v3 flags.
- Map UDP port 161 (`-p 161:161/udp`) to access the service.
- One image, one codebase; no special setup.

Dataset lines can annotate modules, e.g., to generate a notification:  
`.1.3.6.1.6.3.1.1.4.1.0|<notification>|IF-MIB::linkDown`

### Record a live device

Use the included SNMPSim tool to record commands for later playback:

```sh
docker run --rm -it \
  -v $(PWD)/datasets:/data \
  snmpsim:dev \
  snmpsim-record-commands --agent-udpv4-endpoint=192.168.1.2:161 --output-file=/data/new.snmprec
```

- Add `--variation-modules=numeric` to generate varying values during recording.
- Copy recorded files to your datasets directory and sort for best results.

## Dataset `.snmprec` Format

- Each line has the format: `<OID>|<TYPE>|<VALUE>`
- Example:

  ```
  .1.3.6.1.2.1.1.3.0|67|12345
  ```

- Lines must be sorted lexicographically by OID.
- You can convert `snmpwalk` output to `.snmprec` format with:

  ```sh
  snmpwalk -v2c -c public -ObentU AGENT | awk '{printf "%s|%s|%s\n",$1,$2,$4}' | sort > demo.snmprec
  ```

- Use `<variation>` or `<notification>` in the TYPE column for dynamic values or traps.

## Makefile Targets

- `make build` – Build the Docker image `snmpsim:dev`
- `make run` – Run v2c agent on UDP port 161 with read-only dataset
- `make run-multi` – Run multi-agent responder using `config/agents.txt`
- `make run-v3` – Run v3 USM agent demo with authPriv
- `make logs` – Follow container logs
- `make stop` – Stop the container
- `make smoke` – Run a simple smoke test probing the agent with UDP
- `make clean` – Remove container and image

## Notes

- SNMPv1/v2c is enabled by default; v3 support requires extra flags.
- One responder process can bind multiple endpoints using the `--args-from-file` option.
- Multi-process setups are heavier but isolate caches.
- Container runs as non-root user (UID 10001). Mount `/data` read-only unless write access is needed.
- Common errors:
  - Always specify UDP for port: `-p 161:161/udp`
  - Do not use `python -m snmpsim`; use the provided console script entrypoint.
  - Dataset mount path must match (`/data`).
  - Use `127.0.0.1` to bind localhost; use `0.0.0.0` for all interfaces.
- You can exec into the container to list available variation modules:

  ```sh
  docker exec -it snmpmini snmpsim-command-responder --help
  ```

## Healthcheck

The container healthcheck uses Python’s stdlib to send a minimal SNMP v2c GET request for sysUpTime over UDP to `127.0.0.1:161` and validates any response.
