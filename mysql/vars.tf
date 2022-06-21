variable "amis" {
  type = map(string)

  default = {
    "ubuntu-east2" = "ami-0aeb7c931a5a61206" 
  }
}

variable "key_name" {
  default = "aws-alexandre-ohio"
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