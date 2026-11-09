data "aws_subnet" "this" {
  id = var.subnet_id
}

data "aws_security_group" "bastion" {
  name   = var.bastion_sg_name
  vpc_id = data.aws_subnet.this.vpc_id
}

# SSH from the bastion and from the Jenkins server only. Not from the whole
# Private-SG, which also contains the Git server and the app server.
resource "aws_security_group" "shopsphere" {
  name        = var.sg_name
  description = "ShopSphere minikube" # cannot be changed without replacing the group
  vpc_id      = data.aws_subnet.this.vpc_id

  ingress {
    description     = "SSH from the bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [data.aws_security_group.bastion.id]
  }

  ingress {
    description = "SSH from the Jenkins server (deploys)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "minikube" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.shopsphere.id]
  ebs_optimized          = true
  monitoring             = false

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_gb
    encrypted   = false
  }

  tags = {
    Name = var.name
  }

  lifecycle {
    # Minikube state lives on this host. Never replace or destroy it by accident.
    prevent_destroy = true
  }
}
