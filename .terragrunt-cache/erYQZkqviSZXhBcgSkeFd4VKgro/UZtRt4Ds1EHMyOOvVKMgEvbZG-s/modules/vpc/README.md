**VPC Module**

***Overview***
This module provisions a highly available VPC for the SmartCity IoT platform, spanning 3 Availability Zones containing:
- Public subnets for internet-facing resources (NAT gateways, load balancers)
- Private subnets for internal resources (application pods)
- Database subnets for RDS/Aurora (no internet access)
- NAT Gateways for private subnet outbound internet access
- Proper route tables and associations


