# Demo Web App

Demo terraform for EC2 & ASG, RDS, VPC, etc

To create infrastructure run:

```
deploy.sh
``
deploy.sh script build's docker images for server and dashboard images and pushes to dockerhub repo
and initiates terraform deloyment. Each terraform files explained below

Terraform Files:

* terraform.tf - terraform version and state file config
* datasource.tf - data sources for ami
* variables.tf - input variables
* main.tf - Set up log bucket and run sub-modules
* networks.tf - VPC and security groups
* load_balancer.tf - create application load balancer
* ec2.tf - EC2 launch template, autoscaling group and ALB attachment
* database.tf - create MySQL RDS instance

Other files:

* bucket_policy_loggong.json - template for bucket policy for load balancer logging
* user_data.sh - template for EC2 user data 

Missing configurations

* Monitoring and Alerting not configured - This can be configured in cloud watch with SNS topic to send alert notification 
for all required resources.
* Redis and ActiveMQ is not deployed
* Environment variables for other resources like database, activeMQ, ports, etcare configured properly in user-data script for docker