# LMDE6-LAMP

**LAMP Setup Script for Linux Mint LMDE 6 “Faye”**
This Bash script automates the installation and teardown of a full LAMP stack (Apache, MariaDB, PHP) plus common development tools on Linux Mint LMDE 6. It supports three modes via command‑line flags and is designed to be non‑interactive where possible.

---

## Features

* **Installation Mode** (default)

  * Installs Apache 2, MariaDB 10.11, PHP 8.2 (CLI + common extensions), Apache PHP module
  * Installs development tools: `unzip`, `git`, `curl`, `make`, `gcc`, `wget`, `gpg`
  * Installs Composer (PHP dependency manager)
  * Configures and restarts services

* **Secure MariaDB Configuration**

  * Prompts for and confirms a new root password
  * Drops anonymous users, removes test database, enforces `root`@`localhost` only
  * Optional creation of a non‑root “Symfony” database user & dedicated schema

* **Symfony CLI**

  * Installs the official Symfony CLI tool

* **Database GUI**

  * Adds DBeaver CE repository and installs DBeaver for graphical database management

* **Editor Choice**

  * Interactive prompt to install **VS Code** (Microsoft) or **VSCodium** (Telemetry‑free)
  * Automatically adds `alias code='codium'` when VSCodium is chosen

* **Uninstall Mode** (`-u` / `--uninstall`)

  * Removes packages, cleans up configs and logs, but preserves database/data directories

* **Purge‑Full Mode** (`-p` / `--purge-full`)

  * Complete removal of all packages, configurations, data directories, logs, binaries, and APT sources/keys

* **Strict Mode** (`-s` / `--strict`)

  * Enables `set -e` to abort on any command failure—ideal for automated CI pipelines

* **Quiet Mode** (`-q` / `--quiet`) *(todo)*

  * Planned: suppress non‑essential output for minimal terminal noise

---

## Usage

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/lamp-setup-lmde6.git
   cd lamp-setup-lmde6
   chmod +x setup-lamp.sh
   ```

2. **Run in default (install) mode**

   ```bash
   sudo ./setup-lamp.sh
   ```

3. **Uninstall only** (packages + minimal cleanup)

   ```bash
   sudo ./setup-lamp.sh -u
   ```

4. **Purge‑full** (everything, including data and configs)

   ```bash
   sudo ./setup-lamp.sh -p
   ```

5. **Strict error checking**

   ```bash
   sudo ./setup-lamp.sh -s
   ```

6. **Combine flags**

   ```bash
   sudo ./setup-lamp.sh -p -s    # purge‑full + strict
   sudo ./setup-lamp.sh -u -s    # uninstall + strict
   ```

---

## Flags

| Flag           | Alias | Description                                  |
| -------------- | ----- | -------------------------------------------- |
| `--uninstall`  | `-u`  | Remove installed packages and basic cleanup. |
| `--purge-full` | `-p`  | Full purge of packages, configs, data, logs. |
| `--strict`     | `-s`  | Abort on any command failure (`set -e`).     |
| `--quiet`      | `-q`  | *(TODO)* Suppress non‑essential output.      |

---

## Requirements

* Linux Mint LMDE 6 “Faye” (Debian Bookworm base)
* `bash`, `sudo`, APT package manager
* Internet connection for downloading packages and tools

---

## Contributing

Feel free to open issues or submit pull requests to:

* Add the `--quiet` mode
* Introduce non‑interactive defaults (CI mode)
* Extend PHP extensions selection

---

## License

This project is released under the MIT License.
