# --- Audouin Management ---
# This Makefile provides a simple CLI for the monitoring stack.

# Use sudo by default for all docker commands
COMPOSE = sudo docker compose

# We use the .env file for secrets. The --env-file flag is only
# needed if docker compose doesn't automatically find it.
# We'll include it for safety on commands that read variables.
ENV_FLAG = --env-file ./.env

.PHONY: help setup up down restart logs pull

help:
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  setup    : Run the interactive setup wizard to generate configs."
	@echo "  up       : Start all services in the background."
	@echo "  down     : Stop and remove all services."
	@echo "  restart  : Restart all services (e.g., after a config change)."
	@echo "  logs     : Follow the logs for all services."
	@echo "  pull     : Pull the latest Docker images for all services."
	@echo "  clean    : Remove the generated configs and .env file (DANGEROUS)."

setup:
	@echo "--- Running Audouin Setup Wizard ---"
	@sudo bash setup.sh

up:
	@echo "--- Starting Audouin Stack ---"
	@$(COMPOSE) $(ENV_FLAG) up -d

down:
	@echo "--- Stopping Audouin Stack ---"
	@$(COMPOSE) down

restart:
	@echo "--- Restarting Audouin Stack ---"
	@$(COMPOSE) restart

logs:
	@echo "--- Following Logs (Ctrl+C to exit) ---"
	@$(COMPOSE) logs -f

pull:
	@echo "--- Pulling Latest Docker Images ---"
	@$(COMPOSE) pull

clean:
	@echo "--- Cleaning up generated configs and secrets ---"
	@read -p "This will DELETE your .env, prometheus.yml, and grafana.ini. Are you sure? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		sudo rm -f .env prometheus/prometheus.yml configs/grafana.ini; \
		echo "Files cleaned."; \
	else \
		echo "Clean canceled."; \
	fi
