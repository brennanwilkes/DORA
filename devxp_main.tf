terraform {
  backend "s3" {
      bucket = "terraform-state-boo6tzycmonxynn0k0ubavdhpd4s3ctpp2hzahewr6gy8"
      key = "terraform/state"
      region = "us-west-2"
  }
}

resource "aws_instance" "DORA-worker-a" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      tags {
        Name = "DORA-worker-a"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-worker-a_iam_role_instance_profile.name
      key_name = "DORA-worker-a_keyPair"
}

resource "aws_eip" "DORA-worker-a_eip" {
      vpc = true
      instance = aws_instance.DORA-worker-a.id
}

resource "tls_private_key" "DORA-worker-a_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-worker-a_keyPair" {
      public_key = tls_private_key.DORA-worker-a_keyPair_tls_key.public_key_openssh
      key_name = "DORA-worker-a_keyPair"
}

resource "local_sensitive_file" "DORA-worker-a_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-worker-a_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-worker-a_keyPair_tls_key.private_key_pem
}

resource "aws_instance" "DORA-worker-b" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      tags {
        Name = "DORA-worker-b"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-worker-b_iam_role_instance_profile.name
      key_name = "DORA-worker-b_keyPair"
}

resource "aws_eip" "DORA-worker-b_eip" {
      vpc = true
      instance = aws_instance.DORA-worker-b.id
}

resource "tls_private_key" "DORA-worker-b_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-worker-b_keyPair" {
      public_key = tls_private_key.DORA-worker-b_keyPair_tls_key.public_key_openssh
      key_name = "DORA-worker-b_keyPair"
}

resource "local_sensitive_file" "DORA-worker-b_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-worker-b_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-worker-b_keyPair_tls_key.private_key_pem
}

resource "aws_instance" "DORA-worker-c" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      tags {
        Name = "DORA-worker-c"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-worker-c_iam_role_instance_profile.name
      key_name = "DORA-worker-c_keyPair"
}

resource "aws_eip" "DORA-worker-c_eip" {
      vpc = true
      instance = aws_instance.DORA-worker-c.id
}

resource "tls_private_key" "DORA-worker-c_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-worker-c_keyPair" {
      public_key = tls_private_key.DORA-worker-c_keyPair_tls_key.public_key_openssh
      key_name = "DORA-worker-c_keyPair"
}

resource "local_sensitive_file" "DORA-worker-c_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-worker-c_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-worker-c_keyPair_tls_key.private_key_pem
}

resource "aws_instance" "DORA-worker-d" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      tags {
        Name = "DORA-worker-d"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-worker-d_iam_role_instance_profile.name
      key_name = "DORA-worker-d_keyPair"
}

resource "aws_eip" "DORA-worker-d_eip" {
      vpc = true
      instance = aws_instance.DORA-worker-d.id
}

resource "tls_private_key" "DORA-worker-d_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-worker-d_keyPair" {
      public_key = tls_private_key.DORA-worker-d_keyPair_tls_key.public_key_openssh
      key_name = "DORA-worker-d_keyPair"
}

resource "local_sensitive_file" "DORA-worker-d_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-worker-d_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-worker-d_keyPair_tls_key.private_key_pem
}

resource "aws_instance" "DORA-worker-e" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      tags {
        Name = "DORA-worker-e"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-worker-e_iam_role_instance_profile.name
      key_name = "DORA-worker-e_keyPair"
}

resource "aws_eip" "DORA-worker-e_eip" {
      vpc = true
      instance = aws_instance.DORA-worker-e.id
}

resource "tls_private_key" "DORA-worker-e_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-worker-e_keyPair" {
      public_key = tls_private_key.DORA-worker-e_keyPair_tls_key.public_key_openssh
      key_name = "DORA-worker-e_keyPair"
}

resource "local_sensitive_file" "DORA-worker-e_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-worker-e_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-worker-e_keyPair_tls_key.private_key_pem
}

resource "aws_instance" "DORA-scheduler" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.small"
      tags {
        Name = "DORA-scheduler"
      }
      lifecycle {
        ignore_changes = [ami]
      }
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      associate_public_ip_address = true
      vpc_security_group_ids = [aws_security_group.devxp_security_group.id]
      iam_instance_profile = aws_iam_instance_profile.DORA-scheduler_iam_role_instance_profile.name
      key_name = "DORA-scheduler_keyPair"
}

resource "aws_eip" "DORA-scheduler_eip" {
      vpc = true
      instance = aws_instance.DORA-scheduler.id
}

resource "tls_private_key" "DORA-scheduler_keyPair_tls_key" {
      algorithm = "RSA"
      rsa_bits = 4096
}

resource "aws_key_pair" "DORA-scheduler_keyPair" {
      public_key = tls_private_key.DORA-scheduler_keyPair_tls_key.public_key_openssh
      key_name = "DORA-scheduler_keyPair"
}

resource "local_sensitive_file" "DORA-scheduler_keyPair_pem_file" {
      filename = pathexpand("~/.ssh/DORA-scheduler_keyPair.pem")
      file_permission = "600"
      directory_permission = "700"
      content = tls_private_key.DORA-scheduler_keyPair_tls_key.private_key_pem
}

resource "aws_iam_instance_profile" "DORA-worker-a_iam_role_instance_profile" {
      name = "DORA-worker-a_iam_role_instance_profile"
      role = aws_iam_role.DORA-worker-a_iam_role.name
}

resource "aws_iam_instance_profile" "DORA-worker-b_iam_role_instance_profile" {
      name = "DORA-worker-b_iam_role_instance_profile"
      role = aws_iam_role.DORA-worker-b_iam_role.name
}

resource "aws_iam_instance_profile" "DORA-worker-c_iam_role_instance_profile" {
      name = "DORA-worker-c_iam_role_instance_profile"
      role = aws_iam_role.DORA-worker-c_iam_role.name
}

resource "aws_iam_instance_profile" "DORA-worker-d_iam_role_instance_profile" {
      name = "DORA-worker-d_iam_role_instance_profile"
      role = aws_iam_role.DORA-worker-d_iam_role.name
}

resource "aws_iam_instance_profile" "DORA-worker-e_iam_role_instance_profile" {
      name = "DORA-worker-e_iam_role_instance_profile"
      role = aws_iam_role.DORA-worker-e_iam_role.name
}

resource "aws_iam_instance_profile" "DORA-scheduler_iam_role_instance_profile" {
      name = "DORA-scheduler_iam_role_instance_profile"
      role = aws_iam_role.DORA-scheduler_iam_role.name
}

resource "aws_iam_role" "DORA-worker-a_iam_role" {
      name = "DORA-worker-a_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_iam_role" "DORA-worker-b_iam_role" {
      name = "DORA-worker-b_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_iam_role" "DORA-worker-c_iam_role" {
      name = "DORA-worker-c_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_iam_role" "DORA-worker-d_iam_role" {
      name = "DORA-worker-d_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_iam_role" "DORA-worker-e_iam_role" {
      name = "DORA-worker-e_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_iam_role" "DORA-scheduler_iam_role" {
      name = "DORA-scheduler_iam_role"
      assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}"
}

resource "aws_subnet" "devxp_vpc_subnet_public0" {
      vpc_id = aws_vpc.devxp_vpc.id
      cidr_block = "10.0.0.0/25"
      map_public_ip_on_launch = true
      availability_zone = "us-west-2a"
}

resource "aws_subnet" "devxp_vpc_subnet_public1" {
      vpc_id = aws_vpc.devxp_vpc.id
      cidr_block = "10.0.128.0/25"
      map_public_ip_on_launch = true
      availability_zone = "us-west-2b"
}

resource "aws_internet_gateway" "devxp_vpc_internetgateway" {
      vpc_id = aws_vpc.devxp_vpc.id
}

resource "aws_route_table" "devxp_vpc_routetable_pub" {
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.devxp_vpc_internetgateway.id
      }
      vpc_id = aws_vpc.devxp_vpc.id
}

resource "aws_route" "devxp_vpc_internet_route" {
      route_table_id = aws_route_table.devxp_vpc_routetable_pub.id
      destination_cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.devxp_vpc_internetgateway.id
}

resource "aws_route_table_association" "devxp_vpc_subnet_public_assoc" {
      subnet_id = aws_subnet.devxp_vpc_subnet_public0.id
      route_table_id = aws_route_table.devxp_vpc_routetable_pub.id
}

resource "aws_vpc" "devxp_vpc" {
      cidr_block = "10.0.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true
}

resource "aws_security_group" "devxp_security_group" {
      vpc_id = aws_vpc.devxp_vpc.id
      name = "devxp_security_group"
      ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
}

data "aws_ami" "ubuntu_latest" {
      most_recent = true
      owners = ["099720109477"]
      filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64*"]
      }
      filter {
        name = "virtualization-type"
        values = ["hvm"]
      }
}


output "DORA-worker-a_eip-public-ip" {
    value = aws_eip.DORA-worker-a_eip.public_ip
    sensitive = false
}

output "DORA-worker-a_keyPair-private_key" {
    value = tls_private_key.DORA-worker-a_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-worker-a-ssh_instructions" {
    value = "To access DORA-worker-a, use: ssh -i ~/.ssh/DORA-worker-a_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

output "DORA-worker-b_eip-public-ip" {
    value = aws_eip.DORA-worker-b_eip.public_ip
    sensitive = false
}

output "DORA-worker-b_keyPair-private_key" {
    value = tls_private_key.DORA-worker-b_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-worker-b-ssh_instructions" {
    value = "To access DORA-worker-b, use: ssh -i ~/.ssh/DORA-worker-b_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

output "DORA-worker-c_eip-public-ip" {
    value = aws_eip.DORA-worker-c_eip.public_ip
    sensitive = false
}

output "DORA-worker-c_keyPair-private_key" {
    value = tls_private_key.DORA-worker-c_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-worker-c-ssh_instructions" {
    value = "To access DORA-worker-c, use: ssh -i ~/.ssh/DORA-worker-c_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

output "DORA-worker-d_eip-public-ip" {
    value = aws_eip.DORA-worker-d_eip.public_ip
    sensitive = false
}

output "DORA-worker-d_keyPair-private_key" {
    value = tls_private_key.DORA-worker-d_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-worker-d-ssh_instructions" {
    value = "To access DORA-worker-d, use: ssh -i ~/.ssh/DORA-worker-d_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

output "DORA-worker-e_eip-public-ip" {
    value = aws_eip.DORA-worker-e_eip.public_ip
    sensitive = false
}

output "DORA-worker-e_keyPair-private_key" {
    value = tls_private_key.DORA-worker-e_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-worker-e-ssh_instructions" {
    value = "To access DORA-worker-e, use: ssh -i ~/.ssh/DORA-worker-e_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

output "DORA-scheduler_eip-public-ip" {
    value = aws_eip.DORA-scheduler_eip.public_ip
    sensitive = false
}

output "DORA-scheduler_keyPair-private_key" {
    value = tls_private_key.DORA-scheduler_keyPair_tls_key.private_key_pem
    sensitive = true
}

output "DORA-scheduler-ssh_instructions" {
    value = "To access DORA-scheduler, use: ssh -i ~/.ssh/DORA-scheduler_keyPair.pem ubuntu@<OUTPUTTED_IP)>"
    sensitive = false
}

