#!/bin/sh
## Variables
FULL_PATH=$(realpath $0)
DIR_PATH=$(dirname $FULL_PATH)
CREDENTIALS_PROPERTIES="$DIR_PATH/../config/credentials.properties"

## Functions
function generate_otp() {
    property_key=$1
    secret=$(cat $CREDENTIALS_PROPERTIES | grep $property_key | cut -d'=' -f2)
    local otp_value=$(oathtool --base32 --totp $secret)
    echo "$otp_value"
}

function create_lastexecution() {
    destiny=$1
    LAST_EXECUTION="$DIR_PATH/output/.$destiny.lastExecution"
    date > $LAST_EXECUTION
}

DESTINIY=$1
if [ $DESTINIY == "other" ]; then
    # Get base pass of other
    BASE_KEY=$(cat $CREDENTIALS_PROPERTIES | grep "OTHER_BASE_KEY" | cut -d'=' -f2)
    OTP=$(generate_otp "OTHER_OTP_SECRET")
    GEN_PASS="$BASE_KEY$OTP"
    echo $GEN_PASS | pbcopy
elif [ $DESTINIY == "aws" ]; then
    # Set the profile you want to use for MFA
    SOURCE_PROFILE="default"
    MFA_PROFILE="mfa"

    # Read the MFA device ARN from the credentials file
    MFA_DEVICE_ARN=$(aws configure get mfa_device_arn --profile $SOURCE_PROFILE)
    if [ -z "$MFA_DEVICE_ARN" ]; then
        echo "Error: MFA device ARN not found in the ~/.aws/credentials file for profile $SOURCE_PROFILE"
        exit 1
    fi
    OTP=$(generate_otp "AWS_OTP_SECRET")

    # Get the temporary credentials
    CREDENTIALS=$(aws sts get-session-token \
    --serial-number "$MFA_DEVICE_ARN" \
    --token-code "$OTP" \
    --profile "$SOURCE_PROFILE" \
    --output json 2>/dev/null)

    # Extract the credentials from the JSON response
    ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
    SECRET_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
    SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')
    EXPIRATION=$(echo "$CREDENTIALS" | jq -r '.Credentials.Expiration')

    # Check if the credentials are not empty
    if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] || [ -z "$SESSION_TOKEN" ]; then
        echo "Error: Failed to parse temporary credentials. Please try again."
        exit 1
    fi

    # Store the temporary credentials in the mfa profile
    aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$MFA_PROFILE"
    aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$MFA_PROFILE"
    aws configure set aws_session_token "$SESSION_TOKEN" --profile "$MFA_PROFILE"

    echo "Temporary credentials have been set for the '$MFA_PROFILE' profile. They will expire on $EXPIRATION."
    echo "Remember to set AWS_PROFILE=<ENV> if you dont want to specify --profile in all operations"
else
    echo "Not valid credentials destiny - $DESTINY"
    exit 1
fi

create_lastexecution $DESTINIY
