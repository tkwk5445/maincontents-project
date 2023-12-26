variable "vpc_cidr" {
  description = "The cidr of vpc"
  default     = "10.1.0.0/16"
}

variable "public_subnet" {
  description = "The public subnet of vpc"
  type        = list(any)
  default     = ["10.1.10.0/24", "10.1.20.0/24"]
}

variable "private_subnet" {
  description = "The private subnet of vpc"
  type        = list(any)
  default     = ["10.1.30.0/24", "10.1.40.0/24"]
}

variable "azs" {
  description = "The available zone of ap-northeast-2"
  type        = list(any)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "azs1" {
  type    = list(any)
  default = ["2a", "2c"]

}
variable "key" {
  default = "dev-ssum-key"
}
