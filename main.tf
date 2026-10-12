10f97e41e6ce:/workspace# cat main.tf 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "aws-devops-vpc"
  }
}

# -------------------------
# Public Subnet
# -------------------------

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  tags = {
    Name = "aws-devops-public-subnet"
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws-devops-igw"
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws-devops-public-route-table"
  }
}

# -------------------------
# Internet Route
# -------------------------

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# -------------------------
# Route Table Association
# -------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "web" {
  name        = "aws-devops-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "aws-devops-web-sg"
  }
}

# -------------------------
# Security Group - SSH
# -------------------------

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# -------------------------
# Security Group - HTTP
# -------------------------

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# -------------------------
# Security Group - Egress
# -------------------------

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# -------------------------
# Ubuntu AMI
# -------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -------------------------
# EC2 Instance
# -------------------------

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "aws-devops-web-server"
  }
}
