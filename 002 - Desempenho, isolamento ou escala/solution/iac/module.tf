
module "placement_group_hpc" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "case002-hpc"
  strategy = "cluster"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }

}

module "placement_group_critical" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "case002-critical"
  strategy = "spread"

  spread_level = "rack"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }

}

module "placement_group_kafka" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "case002-kafka"
  strategy = "partition"

  partition_count = 3

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

  associate_public_ip_address = true

  placement_group = module.placement_group_critical.placement_group_name

  root_volume_size = 10


  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}

