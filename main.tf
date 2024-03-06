terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region = "ca-central-1"
}

resource "tls_private_key" "Manos_4" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "Manos__key"
  public_key = tls_private_key.Manos_4.public_key_openssh
}

resource "local_file" "ssh_key_pair_file" {
  content         = tls_private_key.Manos_4.private_key_pem
  filename        = "${path.module}/Manos__key.pem"
  file_permission = var.file_access_mode
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTableTerraform"
  }
}
resource "aws_subnet" "public_subnet_terraform" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet_terraform.id
  route_table_id = aws_route_table.my_route_table.id
}
resource "aws_security_group" "SG_Terraform" {
  name        = "WebSecurityGroup"
  description = "Allow HTTP, SSH, and outbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_instance" "instance_EC2_terraform" {
  count         = 2 
  ami           = "ami-0c777892a9bc2e481"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_terraform.id

  key_name      = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.SG_Terraform.id]

  tags = {
    Name = "TerraformInstanceManos-${count.index}"
  }
}

output "public_ips" {
  value = jsonencode(aws_instance.instance_EC2_terraform[*].public_ip)
}
output "public_ip" {
  value = aws_instance.instance_EC2_terraform[*].public_ip
}
