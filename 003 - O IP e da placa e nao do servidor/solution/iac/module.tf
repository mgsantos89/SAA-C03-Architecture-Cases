module "security_group_APP" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"

  name        = "${var.prefixo_projeto}-app-sg"
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
      description = "HTTP access para o CLIENTE"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      referenced_security_group_id = module.security_group_cliente.security_group_id
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

module "security_group_cliente" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"

  name        = "${var.prefixo_projeto}-cliente-sg"
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

module "ec2_app_A" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name          = "case003-app-a"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true
  security_group_ids = [module.security_group_APP.security_group_id]  

  root_volume_size = 10

  # Script renderizado a partir do template. Não coloque segredos aqui:
  # o conteúdo fica salvo no state e visível na metadata da instância.
  user_data = templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    instance_name = "case003-app-a"
    environment   = var.environment
  })

  # Recria a instância quando o script mudar, garantindo que ele rode de novo.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório (padrão do módulo, declarado aqui para ficar explícito).
  metadata_http_tokens= "required"
  metadata_http_put_response_hop_limit = 1

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}

module "ec2_app_B" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name          = "case003-app-b"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true
  security_group_ids = [module.security_group_APP.security_group_id]

  root_volume_size = 10

  # Script renderizado a partir do template. Não coloque segredos aqui:
  # o conteúdo fica salvo no state e visível na metadata da instância.
  user_data = templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    instance_name = "case003-app-b"
    environment   = var.environment
  })

  # Recria a instância quando o script mudar, garantindo que ele rode de novo.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório (padrão do módulo, declarado aqui para ficar explícito).
  metadata_http_tokens= "required"
  metadata_http_put_response_hop_limit = 1

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}


module "ec2_cliente" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name          = "case003-cliente"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = "subnet-0488c49afc72f8ba8"

  associate_public_ip_address = true
  security_group_ids = [module.security_group_cliente.security_group_id]

  root_volume_size = 10

  # Script renderizado a partir do template. Não coloque segredos aqui:
  # o conteúdo fica salvo no state e visível na metadata da instância.
  user_data = templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    instance_name = "case003-cliente"
    environment   = var.environment
  })

  # Recria a instância quando o script mudar, garantindo que ele rode de novo.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório (padrão do módulo, declarado aqui para ficar explícito).
  metadata_http_tokens= "required"
  metadata_http_put_response_hop_limit = 1

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}


module "eni" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/ENI?ref=main"

  name        = "${var.prefixo_projeto}-eni-servico"
  description = "Secondary network interface for EC2"

  subnet_id = var.subnet_id

  # IP Custom do serviço: é este endereço que os 12 clientes usam.
  # Precisa estar dentro do CIDR da sub-rede (172.31.0.0/20) e livre.
  private_ips = ["172.31.10.100"]

  security_group_ids = [module.security_group_APP.security_group_id]

  #instance_id = module.ec2.instance_id
  #device_index = 1

  source_dest_check = true

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
