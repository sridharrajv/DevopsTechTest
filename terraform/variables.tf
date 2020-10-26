variable name {

  type = string

  default = "demo-sportsbuff"
}

variable "region" {

  type = string

  default = "eu-west-1"
}

variable "vpc_cidr" {

  type = string

  default = "10.9.0.0/16"
}

variable "private_subnets" {

  type = list(string)

  default = ["10.9.0.0/24", "10.9.1.0/24"]
}

variable "public_subnets" {

  type = list(string)

  default = ["10.9.10.0/24", "10.9.11.0/24"]
}

variable "database_subnets" {

  type = list(string)

  default = ["10.9.20.0/24", "10.9.21.0/24"]
}

variable "sshpubkey" {

  type = string
}

variable "instance_type" {

  type = string

  default = "t3.micro"
}

variable "ssh_ip_whitelist" {

  type = list(string)
}

variable "tags" {

  type = map(string)

  default = {
    env = "dev"
  }
}