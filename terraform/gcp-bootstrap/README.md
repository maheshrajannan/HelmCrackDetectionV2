# GCP Bootstrap Terraform

This Terraform configuration sets up the foundational GCP resources needed for the Crack Detection application, including:

1. Required GCP APIs
2. Service Account with necessary IAM roles
3. DNS Zone and Records
4. GCS Bucket for Terraform state

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

3. After applying, the output will show the Terraform state bucket name. Use this bucket name when initializing the main GCP configuration.

## Outputs

- `terraform_state_bucket`: The name of the GCS bucket that should be used for storing Terraform state in the main configuration.
