module "eip" {
source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EIP?ref=main"
#

  name = "${var.prefixo_projeto}-eip"
  
  #instance_id = 

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}

module "key_pair" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/KeyPair?ref=main"

  key_name         = "${var.prefixo_projeto}-key"
  private_key_path = "keys/${var.prefixo_projeto}.pem"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}


module "security_group" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"

  name        = "${var.prefixo_projeto}-sg"
  description = "Security Group for EC2"
  vpc_id      = var.vpc_id

  ingress_rules = {
    ssh = {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    http = {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

    egress_rules = {
      all_ipv4 = {
        description = "Allow all outbound IPv4"
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }

  }

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}


module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name          = var.instance_name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  security_group_ids = [module.security_group.security_group_id]
  key_name                    = module.key_pair.key_name
  associate_public_ip_address = true

  root_volume_size = 10

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
