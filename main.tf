// ./main.tf
terraform {
 required_version = "~> 1.3"

 required_providers {
  aws = {
   source  = "hashicorp/aws"
   version = "~> 4.56"
  }
  docker = {
   source  = "kreuzwerker/docker"
   version = "~> 3.0"
  }
 }
}

locals {
 container_name = "softserve-demo-container"
 container_port = 8000 # ! Must be same EXPORE port from our Dockerfile
 example = "softserve-demo-ecr"
}

provider "aws" {
 region = "us-east-1" # Feel free to change this

 default_tags {
  tags = { example = local.example }
 }
}

# * Give Docker permission to pusher Docker images to AWS
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
data "aws_region" "this" {}
locals { ecr_address = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.this.name) }
provider "docker" {
 registry_auth {
  address  = local.ecr_address
  password = data.aws_ecr_authorization_token.this.password
  username = data.aws_ecr_authorization_token.this.user_name
 }
}

module "ecr" {
 source  = "terraform-aws-modules/ecr/aws"
 version = "~> 1.6.0"

 repository_force_delete = true
 repository_name = local.example
 repository_lifecycle_policy = jsonencode({
  rules = [{
   action = { type = "expire" }
   description = "Delete all images except a handful of the newest images"
   rulePriority = 1
   selection = {
    countNumber = 3
    countType = "imageCountMoreThan"
    tagStatus = "any"
   }
  }]
 })
}


data "aws_availability_zones" "available" { state = "available" }
module "vpc" {
 source = "terraform-aws-modules/vpc/aws"
 version = "~> 3.19.0"

 azs = slice(data.aws_availability_zones.available.names, 0, 2) # Span subnetworks across 2 avalibility zones
 cidr = "10.0.0.0/16"
 create_igw = true # Expose public subnetworks to the Internet
 enable_nat_gateway = true # Hide private subnetworks behind NAT Gateway
 private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
 public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
 single_nat_gateway = true
}

module "alb" {
 source  = "terraform-aws-modules/alb/aws"
 version = "~> 8.4.0"

 load_balancer_type = "application"
 security_groups = [module.vpc.default_security_group_id]
 subnets = module.vpc.public_subnets
 vpc_id = module.vpc.vpc_id

 security_group_rules = {
  ingress_all_http = {
   type        = "ingress"
   from_port   = 80
   to_port     = 80
   protocol    = "TCP"
   description = "Permit incoming HTTP requests from the internet"
   cidr_blocks = ["0.0.0.0/0"]
  }
  egress_all = {
   type        = "egress"
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   description = "Permit all outgoing requests to the internet"
   cidr_blocks = ["0.0.0.0/0"]
  }
 }

 http_tcp_listeners = [
  {
   # * Setup a listener on port 80 and forward all HTTP
   # * traffic to target_groups[0] defined below which
   # * will eventually point to our app.
   port               = 80
   protocol           = "HTTP"
   target_group_index = 0
  }
 ]

 target_groups = [
  {
   backend_port         = local.container_port
   backend_protocol     = "HTTP"
   target_type          = "ip"
  }
 ]
}

variable "DATADOG_API_KEY" {
  description = "Datadog API Key"
  default = "secret-text"
}

module "ecs" {
 source  = "terraform-aws-modules/ecs/aws"
 version = "~> 4.1.3"

 cluster_name = local.example

 # * Allocate 20% capacity to FARGATE and then split
 # * the remaining 80% capacity 50/50 between FARGATE
 # * and FARGATE_SPOT.
 fargate_capacity_providers = {
  FARGATE = {
   default_capacity_provider_strategy = {
    base   = 20
    weight = 50
   }
  }
  FARGATE_SPOT = {
   default_capacity_provider_strategy = {
    weight = 50
   }
  }
 }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([
    {
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "DD_API_KEY", value = var.DATADOG_API_KEY }, # Replace with your Datadog API key
      ],
      essential = true,
      image = format("%v.dkr.ecr.%v.amazonaws.com/softserve-demo-ecr:lastest", data.aws_caller_identity.this.account_id, data.aws_region.this.name),
      name = local.container_name,
      portMappings = [{ containerPort = local.container_port }],
    },
    {
      name = "datadog-agent",
      image = "datadog/agent:latest",
      essential = true,
      environment = [
        { name = "DD_API_KEY", value = var.DATADOG_API_KEY }, # Replace with your Datadog API key
        { name = "ECS_FARGATE", value = "true" },
        { name = "DD_APM_ENABLED", value = "true" }, # Enable APM if you have it
      ],
      # You can configure other Datadog agent settings here as needed
    },
  ])
  cpu = 256
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  family = "family-of-${local.example}-tasks"
  memory = 512
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}



resource "aws_ecs_service" "this" {
 cluster = module.ecs.cluster_id
 desired_count = 1
 launch_type = "FARGATE"
 name = "${local.example}-service"
 task_definition = resource.aws_ecs_task_definition.this.arn

 lifecycle {
  ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
 }

 load_balancer {
  container_name = local.container_name
  container_port = local.container_port
  target_group_arn = module.alb.target_group_arns[0]
 }

 network_configuration {
  security_groups = [module.vpc.default_security_group_id]
  subnets = module.vpc.private_subnets
 }
}

# * Output the URL of our Application Load Balancer so that we can connect to
# * our application running inside ECS once it is up and running.
output "url" { value = "http://${module.alb.lb_dns_name}" }


resource "aws_route53_zone" "primary" {
  name = "roman-demo.pp.ua"
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "main.roman-demo.pp.ua"
  type    = "CNAME"
  ttl     = 300
  records = [module.alb.lb_dns_name]
}