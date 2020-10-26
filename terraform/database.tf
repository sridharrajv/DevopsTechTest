# RDS Zone Infrastructure

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = var.name

  engine            = "mysql"
  engine_version    = "5.7.12"
  instance_class    = "db.t3.medium"
  allocated_storage = 5

  name     = "buffup"
  username = jsondecode(aws_secretsmanager_secret_version.db.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.db.secret_string)["password"]
  port     = "3306"

  vpc_security_group_ids = [module.security_group_db.this_security_group_id]

  multi_az = false

  # DB subnet group
  subnet_ids = module.vpc.database_subnets

  # DB option group
  major_engine_version = "5.7"

  # DB parameter group
  create_db_parameter_group   = true
  parameter_group_description = var.name
  family                      = "mysql5.7"
  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  //  # Snapshot
  backup_window             = "03:00-06:00"
  backup_retention_period   = 0
  copy_tags_to_snapshot     = true
  final_snapshot_identifier = format("%s-db-final", var.name)
  skip_final_snapshot       = true
  delete_automated_backups  = false

  # Maintenance
  maintenance_window          = "Sun:00:00-Sun:03:00"
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false

  tags = var.tags
}

# DB username/password

resource "aws_secretsmanager_secret" "db" {
  name = format("%s-db", var.name)

  recovery_window_in_days = 0 # Demo

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode(
  {
    username = format("demo_%s", random_password.username.result)
    password = random_password.password.result
  }
  )
}

resource "random_password" "username" {
  length  = 7
  number  = false
  special = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}