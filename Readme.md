# Code used for learning/testing purposes.

Code consist of three folders:
- contoso-easuts-dev: contains terraform code for deploying infrastructure to Azure.
- packer-deployments: contains packer code for deploying custom image to Azure via packer.
- helm-deployments: contains helm chart for nginx deployment.

## Pre-requirements
- Azure Cloud Subscription.
- Resource group named packer-images and service principal with contributor role to this resource group.