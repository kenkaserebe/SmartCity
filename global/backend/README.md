**AWS - Terraform State Backend**
This folder contains Terraform configuration to bootstrap an AWS S3 bucket for storing Terraform state files. It creates a secure, versioned, and encrypted S3 bucket with all public access blocked.

***Purpose***
When managing infrastructure with Terraform, a remote backend (like S3) is recommended to store state files. This bootstrap step creates the S3 bucket that will be used as the backend for your actual infrastructure deployments.

****Features****
- Creates an S3 bucket with a globally unique name (provided by you)
- Enables `bucket versioning` - recover from accidental deletions or corruption
- Enforces `server-side encryption` (AES-256) - protects sensitive data
- Blocks `all public access` - ensures bucket is private
- Uses local Terraform state for the bootstrap itself (no backend configuration)

***Usage***

****1. Configure variables****
Create a terraform.tfvars file (or use environment variables) with the required inputs:
```HCL
region      = "<AWS-region>
bucket_name = "your-unique-state-bucket-name"
```

Important: The bucket_name must be globally unique across all of AWS

****2. Initialize and apply****
```bash
terraform init
terraform plan      # review what will be created
terraform apply     # create the bucket
```

****3. Outputs****
After apply, Terraform will output:
```
bucket_name - "<name of the created bucket>"

bucket_arn - <ARN-of-the-bucket>
```
Use these values when configuring your other Terraform projects' backend:

```HCL
terraform {

    backend "s3" {
        bucket          = "your-unique-state-bucket-name"
        key             = "path/to/your/terraform.tfstate"
        region          = "<AWS-region>"
        encrypt         = true
        use_lockfile    = true         # Enables s3 native locking (Terraform 1.11+)
    }
}
```