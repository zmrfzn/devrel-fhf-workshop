#!/bin/bash

# New Relic Flex Data Sender Script
# This script helps you quickly send Flex data to New Relic

echo "========================================="
echo "  New Relic Flex Data Sender"
echo "========================================="
echo ""

# Function to validate input
validate_input() {
    if [[ -z "$1" ]]; then
        echo "Error: This field cannot be empty!"
        return 1
    fi
    return 0
}

# Check for environment variables first
if [[ -n "$NEW_RELIC_ACCOUNT_ID" ]]; then
    echo "✓ Using NEW_RELIC_ACCOUNT_ID from environment: $NEW_RELIC_ACCOUNT_ID"
    ACCOUNT_ID="$NEW_RELIC_ACCOUNT_ID"
else
    # Prompt for New Relic Account ID
    while true; do
        echo -n "Enter your New Relic Account ID: "
        read -r ACCOUNT_ID
        if validate_input "$ACCOUNT_ID"; then
            break
        fi
    done
fi

if [[ -n "$NEW_RELIC_LICENSE_KEY" ]]; then
    echo "✓ Using NEW_RELIC_LICENSE_KEY from environment"
    LICENSE_KEY="$NEW_RELIC_LICENSE_KEY"
else
    # Prompt for New Relic License Key (hide input for security)
    while true; do
        echo -n "Enter your New Relic Ingest License Key: "
        read -rs LICENSE_KEY
        echo ""  # Add newline after hidden input
        if validate_input "$LICENSE_KEY"; then
            break
        fi
    done
fi

# Prompt for config file path (with default)
echo ""
echo "Available Flex configurations:"
echo "  1. 7-database-and-secrets/basic-db.yml (Database example)"
echo "  2. 4-different-formats/csv-basic.yml (CSV example)" 
echo "  3. 3-status-endpoints/status-twilio.yml (API example)"
echo "  4. Custom path"
echo ""
echo -n "Select configuration (1-4) or enter custom path [default: 7-database-and-secrets/basic-db.yml]: "
read -r CONFIG_CHOICE

case $CONFIG_CHOICE in
    1|"")
        CONFIG_PATH="7-database-and-secrets/basic-db.yml"
        ;;
    2)
        CONFIG_PATH="4-different-formats/csv-basic.yml"
        ;;
    3)
        CONFIG_PATH="3-status-endpoints/status-twilio.yml"
        ;;
    4)
        echo -n "Enter custom config path: "
        read -r CONFIG_PATH
        ;;
    *)
        CONFIG_PATH="$CONFIG_CHOICE"
        ;;
esac

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

echo ""
echo "========================================="
echo "  Sending Data to New Relic..."
echo "========================================="
echo "Account ID: $ACCOUNT_ID"
echo "Config: $CONFIG_PATH"
echo "URL: $INSIGHTS_URL"
echo ""

# Execute the Flex command
echo "Executing Flex command..."
./nri-flex -config_path "$CONFIG_PATH" --pretty --verbose \
    -insights_url "$INSIGHTS_URL" \
    -insights_api_key "$LICENSE_KEY"

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
