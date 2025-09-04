#!/bin/bash

# New Relic Flex Data Sender Script
# This script helps you quickly send Flex data to New Relic

echo "========================================="
echo "  New Relic Flex Data Sender"
echo "========================================="
echo ""

# Load saved environment variables if they exist
if [[ -f "$HOME/.newrelic-flex-env" ]]; then
    source "$HOME/.newrelic-flex-env"
    echo -e "\033[32m✓\033[0m Loaded saved credentials from $HOME/.newrelic-flex-env"
fi

# Function to validate input
validate_input() {
    if [[ -z "$1" ]]; then
        echo "Error: This field cannot be empty!"
        return 1
    fi
    return 0
}

# Function to store environment variables
store_env_vars() {
    local env_file="$HOME/.newrelic-flex-env"
    echo "# New Relic Flex environment variables" > "$env_file"
    echo "export NEW_RELIC_ACCOUNT_ID='$ACCOUNT_ID'" >> "$env_file"
    echo "export NEW_RELIC_LICENSE_KEY='$LICENSE_KEY'" >> "$env_file"
    chmod 600 "$env_file"
    echo "✓ Credentials saved to $env_file for future use"
}

# Check for environment variables first
ACCOUNT_ID_FROM_ENV=false
LICENSE_KEY_FROM_ENV=false

if [[ -n "$NEW_RELIC_ACCOUNT_ID" ]]; then
    echo "✓ Using NEW_RELIC_ACCOUNT_ID from environment: $NEW_RELIC_ACCOUNT_ID"
    ACCOUNT_ID="$NEW_RELIC_ACCOUNT_ID"
    ACCOUNT_ID_FROM_ENV=true
else
    # Prompt for New Relic Account ID
    while true; do
        echo -n "Enter your New Relic Account ID: "
        read -r ACCOUNT_ID
        if validate_input "$ACCOUNT_ID"; then
            break
        fi
    done
    # Store for future use
    export NEW_RELIC_ACCOUNT_ID="$ACCOUNT_ID"
fi

if [[ -n "$NEW_RELIC_LICENSE_KEY" ]]; then
    echo "✓ Using NEW_RELIC_LICENSE_KEY from environment"
    # Sanitize the license key (remove any newlines or whitespace)
    LICENSE_KEY=$(echo "$NEW_RELIC_LICENSE_KEY" | tr -d '\n\r\t ' | sed 's/[^a-zA-Z0-9]//g')
    LICENSE_KEY_FROM_ENV=true
else
    # Prompt for New Relic License Key (hide input for security)
    while true; do
        echo -n "Enter your New Relic Ingest License Key: "
        read -rs LICENSE_KEY
        echo ""  # Add newline after hidden input
        # Sanitize the license key (remove any newlines or whitespace)
        LICENSE_KEY=$(echo "$LICENSE_KEY" | tr -d '\n\r\t ' | sed 's/[^a-zA-Z0-9]//g')
        if validate_input "$LICENSE_KEY"; then
            break
        fi
    done
    # Store for future use
    export NEW_RELIC_LICENSE_KEY="$LICENSE_KEY"
fi

# Store environment variables for future runs if they were just entered
if [[ "$ACCOUNT_ID_FROM_ENV" == false ]] || [[ "$LICENSE_KEY_FROM_ENV" == false ]]; then
    store_env_vars
fi

# Check if config path was provided as command line argument
if [[ -n "$1" ]]; then
    CONFIG_PATH="$1"
    echo "Using config file from command line: $CONFIG_PATH"
else
    # Prompt for config file path (with default)
    echo ""
    echo "Available Flex configurations:"
    echo "  1. 2-getting-started/http-json-example-multi.yml (Multi-JSON API)"
    echo "  2. 3-status-endpoints/status-twilio.yml (Twilio example)"
    echo "  3. 4-different-formats/csv-basic.yml (CSV example)" 
    echo "  4. 7-database-and-secrets/basic-db.yml (Database example)"
    echo "  5. Custom path"
    echo ""
    echo -n "Select configuration (1-5) or enter custom path [default: 7-database-and-secrets/basic-db.yml]: "
    read -r CONFIG_CHOICE

    case $CONFIG_CHOICE in
        1)
            CONFIG_PATH="2-getting-started/http-json-example-multi.yml"
            ;;
        2)
            CONFIG_PATH="3-status-endpoints/status-twilio.yml"
            ;;
        3)
            CONFIG_PATH="4-different-formats/csv-basic.yml"
            ;;
        4|"")
            CONFIG_PATH="7-database-and-secrets/basic-db.yml"
            ;;
        5)
            echo -n "Enter custom config path: "
            read -r CONFIG_PATH
            ;;
        *)
            CONFIG_PATH="$CONFIG_CHOICE"
            ;;
    esac
fi

# Validate config file exists
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Warning: Config file '$CONFIG_PATH' not found!"
    echo -n "Continue anyway? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Construct the New Relic insights URL
INSIGHTS_URL="https://insights-collector.newrelic.com/v1/accounts/${ACCOUNT_ID}/events"

# Create redacted license key for display (show first 4 and last 4 characters)
REDACTED_KEY="${LICENSE_KEY:0:4}...${LICENSE_KEY: -4}"

echo ""
echo "========================================="
echo "  Sending Data to New Relic..."
echo "========================================="
echo "Account ID: $ACCOUNT_ID"
echo "Config: $CONFIG_PATH"
echo ""
echo -e "\033[44m\033[97m Command: ./nri-flex -config_path $CONFIG_PATH -insights_url $INSIGHTS_URL -insights_api_key $REDACTED_KEY --pretty --verbose \033[0m"
echo ""
echo "Debug: License key length: ${#LICENSE_KEY}"
echo "Debug: License key hex dump (first 20 chars): $(echo -n "${LICENSE_KEY:0:20}" | hexdump -C)"

# Execute the Flex command (without --pretty --verbose to reduce noise)
./nri-flex -config_path "$CONFIG_PATH" \
    -insights_url "$INSIGHTS_URL" \
    -insights_api_key "${LICENSE_KEY}" --pretty

# Check exit status
if [[ $? -eq 0 ]]; then
    echo ""
    echo "========================================="
    echo "  ✅ Data sent successfully!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Go to your New Relic account"
    echo "2. Navigate to Query Builder or use the query bar"
    
else
    echo ""
    echo "========================================="
    echo "  ❌ Error sending data!"
    echo "========================================="
    echo ""
    echo "Common issues:"
    echo "- Check your Account ID and License Key"
    echo "- Ensure the config file exists and is valid"
    echo "- Verify network connectivity"
    echo "- Check if the database/services are running (for DB configs)"
fi
