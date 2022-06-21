variable "amis" {
  type = map(string)

  default = {
    "ubuntu" = "ami-09d56f8956ab235b3"
  }
}

variable "key_name" {
  default = "aws-alexandre"
}

variable "cdirs_acesso_remoto" {
  type = list(string)

  default = ["0.0.0.0/0"]
}

variable "password" {
  type = string

  default = "pass1234"

  sensitive = true
}