# SmartCity/create_infrastructure.sh 

#!/bin/bash
set -euo pipefail

# ==========================================================================================
# 1. CREATE S3 BUCKET FOR TERRAFORM STATE FILE
# ==========================================================================================
echo "=== Creating S3 Bucket ==="
BACKEND_MODULE_PATH="global/backend"
terraform -chdir="$BACKEND_MODULE_PATH" init
terraform -chdir="$BACKEND_MODULE_PATH" apply --auto-approve

# Extract values using -raw
BUCKET_NAME=$(terraform -chdir="$BACKEND_MODULE_PATH" output -raw bucket_name)
BUCKET_REGION=$(terraform -chdir="$BACKEND_MODULE_PATH" output -raw region)

echo "AWS bucket creation complete. Bucket: $BUCKET_NAME, Region: $BUCKET_REGION"


# ==========================================================================================
# 2. WAIT + CONFIRM FOR ENVIRONMENT CREATION
# ==========================================================================================
echo "Waiting 120 seconds for storage resources to fully propagate..."
sleep 120

read -p "Do you want to continue with environment (EKS/AKS) creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
fi