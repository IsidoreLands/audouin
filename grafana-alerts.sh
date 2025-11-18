#!/bin/bash

# --- Configuration ---
# Find the script's own directory and set the alert path relative to it
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ALERT_DIR="$SCRIPT_DIR/provisioning/alerting"

# The Prometheus Datasource UID.
# This must match the datasource provisioned in Grafana.
# We will use 'prometheus' as a stable UID.
DATASOURCE_UID="prometheus"

# --- Colors for UI ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Function: List Files ---
list_files() {
    echo -e "${YELLOW}--- Existing Alert Files ---${NC}"
    local files_found
    files_found=$(find "$ALERT_DIR" -maxdepth 1 -name "*.yaml" -exec basename {} \; | sort)
    
    if [ -z "$files_found" ]; then
        echo "No .yaml files found in $ALERT_DIR"
    else
        echo "$files_found"
    fi
    echo -e "${YELLOW}----------------------------${NC}"
}

# --- Function: View File ---
view_file() {
    list_files
    read -p "Enter filename to view (e.g., redis_ha_alerts.yaml): " filename
    
    if [ -z "$filename" ]; then return; fi
    
    local filepath="$ALERT_DIR/$filename"

    if [ ! -f "$filepath" ]; then
        echo -e "\n${RED}Error: File '$filename' not found.${NC}"
    else
        echo -e "\n${GREEN}--- Contents of $filename ---${NC}"
        cat -n "$filepath"
        echo -e "${GREEN}--------------------------------${NC}"
    fi
}

# --- Function: Create New File ---
new_file() {
    read -p "Enter new filename (must end in .yaml): " filename
    if [[ ! "$filename" =~ \.yaml$ ]]; then
        echo -e "\n${RED}Error: Filename must end with .yaml${NC}"
        return
    fi
    
    local filepath="$ALERT_DIR/$filename"
    if [ -f "$filepath" ]; then
        echo -e "\n${RED}Error: File '$filename' already exists.${NC}"
        return
    fi

    read -p "Enter a name for the new alert group (e.g., 'NewApp Monitoring'): " group_name
    
    local boilerplate
    boilerplate=$(cat <<EOF
apiVersion: 1

groups:
  - name: ${group_name:-MyNewGroup}
    folder: Monitoring
    interval: 1m
    rules:
      # TODO: Add your new rules below this line
EOF
)

    echo "Creating new file with boilerplate..."
    echo "$boilerplate" | sudo tee "$filepath" > /dev/null
    
    echo -e "\n${GREEN}Successfully created '$filename'.${NC} Opening for editing..."
    sleep 2
    sudo nano "$filepath"
}

# --- Function: Add a New Rule ---
add_rule_template() {
    echo -e "\n${YELLOW}--- New Rule Template ---${NC}"
    echo "Copy this template and paste it into your file."
    echo "Make sure to align its indentation under the 'rules:' list."
    echo ""
    
    local template
    template=$(cat <<'EOF'
      # --- Alert Title ---
      - uid: 'my_new_unique_uid' # TODO: Must be unique! (e.g., 'app_cpu_high')
        title: 'My New Alert'
        condition: C
        for: 5m
        data:
          - refId: A
            datasourceUid: '${DATASOURCE_UID}'
            relativeTimeRange:
              from: 600
              to: 0
            model:
              expr: 'up == 0' # TODO: Change this PromQL query
              instant: true
              refId: A
          - refId: C
            datasourceUid: '__expr__'
            relativeTimeRange:
              from: 0
              to: 0
            model:
              type: 'threshold'
              expression: 'A'
              conditions:
                - evaluator:
                    params: [0]
                    type: 'gt'
                  operator:
                    type: 'and'
                  query:
                    params: [C]
                  reducer:
                    params: []
                    type: 'last'
                  type: 'query'
        noDataState: NoData
        execErrState: Error
        annotations:
          summary: 'My new alert summary' # TODO: Change this
EOF
)
    echo "${template//'${DATASOURCE_UID}'/$DATASOURCE_UID}"
    echo -e "${YELLOW}-------------------------${NC}"
    
    list_files
    read -p "Which file do you want to add this rule to? " filename
    if [ -z "$filename" ]; then return; fi
    
    local filepath="$ALERT_DIR/$filename"
    if [ ! -f "$filepath" ]; then
        echo -e "\n${RED}Error: File '$filename' not found.${NC}"
    else
        echo -e "\nOpening '$filename'."
        echo "1. Paste the template (copied from above) under the 'rules:' list."
        echo "2. Make sure the indentation matches the other rules."
        echo "3. Change the 'uid', 'title', 'expr', and 'summary'."
        sleep 4
        sudo nano "$filepath"
    fi
}

# --- Function: Delete File ---
delete_file() {
    list_files
    read -p "Enter filename to DELETE (e.g., test.yaml): " filename
    
    if [ -z "$filename" ]; then return; fi
    
    local filepath="$ALERT_DIR/$filename"

    if [ ! -f "$filepath" ]; then
        echo -e "\n${RED}Error: File '$filename' not found.${NC}"
        return
    fi
    
    echo -e "\n${RED}You are about to permanently delete:${NC} $filepath"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sudo rm "$filepath"
        echo -e "\n${GREEN}Successfully deleted '$filename'.${NC}"
        echo "Remember to run 'sudo docker compose restart grafana' to apply changes."
    else
        echo "Delete canceled."
    fi
}

# --- Function: Main Menu ---
main_menu() {
    if [ ! -d "$ALERT_DIR" ]; then
        echo -e "${RED}Error: Alert directory not found at $ALERT_DIR${NC}"
        echo "This script must be run from the project's root directory."
        exit 1
    fi

    while true; do
        echo -e "\n${GREEN}--- Grafana Alert Manager CLI ---${NC}"
        echo "Monitoring Directory: ${YELLOW}$ALERT_DIR${NC}"
        echo ""
        echo "1. List Alert Files"
        echo "2. View an Alert File"
        echo "3. Create a New Alert File"
        echo "4. Add a New Rule (from template)"
        echo -e "${RED}5. Delete an Alert File${NC}"
        echo "6. Quit"
        echo ""
        read -p "Choose an option [1-6]: " choice
        
        case $choice in
            1) list_files ;;
            2) view_file ;;
            3) new_file ;;
            4) add_rule_template ;;
            5) delete_file ;;
            6) echo "Exiting."; break ;;
            *) echo -e "\n${RED}Invalid option. Please try again.${NC}" ;;
        esac
        
        if [[ "$choice" != "6" ]]; then
            echo ""
            read -p "Press Enter to return to menu..."
        fi
    done
}

# --- Run the Main Menu ---
main_menu
