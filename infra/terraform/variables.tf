variable "region" {
  description = "AWS region of the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Name tag of the Minikube host."
  type        = string
  default     = "shopsphere-minikube"
}

variable "sg_name" {
  description = "Name of the Minikube host's security group."
  type        = string
  default     = "shopsphere-sg"
}

variable "subnet_id" {
  description = "Public subnet of the Minikube host. Set in terraform.tfvars (not committed)."
  type        = string
}

variable "ami_id" {
  description = "AMI of the host. Set in terraform.tfvars (not committed)."
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair. Set in terraform.tfvars (not committed)."
  type        = string
}

variable "instance_type" {
  description = "Instance type. 2 vCPU / 8 GiB is the minimum that ran the app and monitoring."
  type        = string
  default     = "m7i-flex.large"
}

variable "root_volume_gb" {
  description = "Size of the root gp3 volume in GiB."
  type        = number
  default     = 40
}

variable "bastion_sg_name" {
  description = "Security group of the bastion host, allowed to SSH in."
  type        = string
  default     = "Bastion-SG"
}

variable "jenkins_cidr" {
  description = "Jenkins server address (a /32), allowed to SSH in for deploys."
  type        = string
  default     = "10.0.2.160/32"
}
