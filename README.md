# Audouin: A Redis HA Monitoring Stack

Monitoring a Redis HA cluster with Sentinel is complex. You need to track failovers, replication lag, quorum loss, and exporter health. audouin provides a complete, production-ready solution in a single docker compose up command. It is pre-configured with a secure setup wizard and a full set of alerts, so you can go from zero to a fully-monitored cluster in under 5 minutes.

Audouin is a complete, containerized monitoring stack for a Redis High-Availability (HA) cluster. It uses Prometheus, Grafana, and `redis_exporter` to provide metrics, dashboards, and automated alerting for a Redis Sentinel-managed failover environment.

This project is pre-configured to be:
* **Secure:** Passwords are not hard-coded and are managed in a `.env` file.
* **Automated:** A setup wizard prompts for secrets and creates all necessary files.
* **Manageable:** Grafana alerts are provisioned as "Infrastructure as Code" from simple YAML files.
* **Modular:** A built-in CLI (`grafana-alerts.sh`) makes managing alert rules simple.

## Requirements

* `docker`
* `docker-compose`
* A running Redis HA cluster (master, slaves, and sentinels) accessible to this host.
* Redis users with appropriate ACLs for monitoring (e.g., `gabriel` for Redis, `christopher` for Sentinel).

## Quick Start

1.  **Clone the Repository:**
    ```sh
    git clone [https://github.com/IsidoreLands/audouin.git](https://github.com/IsidoreLands/audouin.git)
    cd audouin
    ```

2.  **Run the Setup Wizard:**
    This script will create necessary directories and prompt you to enter your passwords. It securely generates a `.env` file for the stack.
    ```sh
    sudo bash setup.sh
    ```

3.  **Deploy the Stack:**
    ```sh
    sudo docker compose up -d
    ```

## Accessing Services

* **Grafana:** `http://localhost:3000` (or `http://<server-ip>:3000`)
* **Prometheus:** `http://localhost:9090` (or `http://<server-ip>:9090`)

## Managing Alerts

A simple CLI tool is included to manage your Grafana alert files.

1.  **Make it executable (one-time setup):**
    ```sh
    sudo chmod +x grafana-alerts.sh
    ```

2.  **(Optional) Create a global symlink:**
    ```sh
    sudo ln -s /home/isidore/projects/audouin/grafana-alerts.sh /usr/local/bin/alerts
    ```

3.  **Run the tool:**
    ```sh
    alerts
    ```
    This will give you a menu to list, view, create, or delete your alert provisioning files. Remember to restart Grafana after making changes:
    `sudo docker compose restart grafana`
