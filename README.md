# Socat Manager

**Auto-manages `socat` port forwards from a config file by monitoring active listeners.**

This script checks for active TCP listeners on your system and automatically starts or stops `socat` processes based on a simple configuration file.  
It’s useful for exposing local services (e.g., from AWS SSM port forwarding) to other machines.

---

## Features
- **Automatic start** – Runs `socat` when a configured target is listening.
- **Automatic stop** – Stops `socat` when the target is no longer listening.
- **Per-mapping control** – Matches exact process + target address/port from config.
- **Logging** – Timestamped log messages with severity levels (`INFO`, `WARNING`, `ERROR`).
- **Cross-platform** – Works on Linux and macOS.
- **Non-loop execution** – Can be used in `watch`, `cron`, or run manually.

---

## Requirements
- `bash` (works with older Bash versions, no associative arrays used)
- [`socat`](http://www.dest-unreach.org/socat/)
- [`lsof`](https://linux.die.net/man/8/lsof)

---

## Installation
Clone this repository and make the script executable:
```bash
git clone https://github.com/kpatronas/socat-manager.git
cd socat-manager
chmod +x socat_manager.sh
```

---

## Usage
Run manually:
```bash
./socat_manager.sh my_config_file
```
If no config file is given, it defaults to `config` in the current directory.

Run every second with `watch`:
```bash
watch -n 1 ./socat_manager.sh config
```

Run periodically with `cron`:
```cron
* * * * * /path/to/socat_manager.sh /path/to/config
```

---

## Config File Format
Each line contains:
```
<ProcessName> <TargetIP:TargetPort> <ListenIP:ListenPort>
```
Example:
```
Spotify 127.0.0.1:7768 0:0:0:0:17768
MyApp 127.0.0.1:5432 0:0:0:0:15432
```
- **ProcessName** – Must match the process name from `lsof`.
- **TargetIP:TargetPort** – The address `socat` will connect to.
- **ListenIP:ListenPort** – The address `socat` will listen on.

---

## Example Output
```
2025-08-15 23:10:15 [INFO] Checking mapping: Spotify 127.0.0.1:7768 0:0:0:0:17768
2025-08-15 23:10:15 [INFO] Starting socat: TCP-LISTEN:17768,fork,reuseaddr TCP:127.0.0.1:7768
2025-08-15 23:12:01 [WARNING] Target not found: Spotify 127.0.0.1:7768
2025-08-15 23:12:01 [WARNING] Stopping socat on 17768 (target 127.0.0.1:7768 not found)
```

---

## Exit Codes
- `0` – Completed without errors.
- `1` – Missing required dependency (`socat` or `lsof`) or missing config file.

