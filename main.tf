/*
  MIT License

  Copyright (c) 2026 Sayan Nandan

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

  -----------------------------------------------------------------------------

  Terraform plan to automate deployment of Minecraft (ECS Fargate + EBS storage).

  1. Security group is created ("MinecraftContainerSG")
  2. ECS Task Definition is created ("MinecraftFamily")
  3. ECS Cluster is created ("MinecraftCluster")
  4. ECS Service is created ("MinecraftService")
  5. ECS Service container is created ("MinecraftContainer")

  Default specification of instance:
  - CPU: 2048 (2 vCPUs)
  - RAM: 4096 (4GB)
  - EBS volume size: 8GB
*/

# --- fetch defaults ---

# provider setup
provider "aws" {}

# region
data "aws_region" "current" {}

# role (NOTE: change as is appropriate)
data "aws_iam_role" "infra_role" {
  name = "LabRole"
}

# get vpc
data "aws_vpc" "default" {
  default = true
}

# get subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- init misc ---

# create security group
resource "aws_security_group" "sg" {
  name        = "MinecraftContainerSG"
  description = "Allow Minecraft connections"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "only allow incoming connections for Minecraft"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound connections"
  }
}

# enable logging
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/minecraft"
  retention_in_days = 30
}

# --- create cluster and deploy service ---

# create cluster
resource "aws_ecs_cluster" "cluster" {
  name = "MinecraftCluster"
}

# define task
resource "aws_ecs_task_definition" "service_def" {
  family                   = "MinecraftTaskFamily"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = data.aws_iam_role.infra_role.arn

  container_definitions = jsonencode([{
    name      = "MinecraftContainer"
    image     = "itzg/minecraft-server:latest"
    essential = true
    portMappings = [{
      containerPort = 25565
      hostPort      = 25565
    }]
    mountPoints = [{
      sourceVolume  = "ebs-volume"
      containerPath = "/data"
      readOnly      = false
    }]
    environment = [
      { name = "EULA", value = "TRUE" },
      { name = "MEMORY", value = "2G" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-stream-prefix" = "ecs"
        "awslogs-region"        = "${data.aws_region.current.region}"
      }
    }
  }])

  volume {
    name                = "ebs-volume"
    configure_at_launch = true
  }
}

# deploy
resource "aws_ecs_service" "service" {
  name                    = "MinecraftService"
  cluster                 = aws_ecs_cluster.cluster.id
  task_definition         = aws_ecs_task_definition.service_def.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_ecs_managed_tags = true
  wait_for_steady_state   = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }

  volume_configuration {
    name = "ebs-volume"
    managed_ebs_volume {
      role_arn         = data.aws_iam_role.infra_role.arn
      size_in_gb       = 8
      volume_type      = "gp3"
      encrypted        = true
      file_system_type = "ext4"
    }
  }
}

# get IP
data "aws_network_interface" "ecs_eni" {
  filter {
    name   = "tag:aws:ecs:serviceName"
    values = [aws_ecs_service.service.name]
  }
}
output "ecs_public_ip" {
  description = "The public IP address of your Minecraft instance"
  value       = data.aws_network_interface.ecs_eni.association[0].public_ip
}
