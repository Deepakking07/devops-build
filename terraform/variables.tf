variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP for SSH access"
  type        = string
}

variable "jenkins_ip_cidr" {
  description = "Jenkins server IP for SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
}

