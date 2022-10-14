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
      lifecycle {
        ignore_changes = [ami]
      }
}

resource "aws_instance" "DORA-worker-b" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      lifecycle {
        ignore_changes = [ami]
      }
}

resource "aws_instance" "DORA-worker-c" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      lifecycle {
        ignore_changes = [ami]
      }
}

resource "aws_instance" "DORA-worker-d" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      lifecycle {
        ignore_changes = [ami]
      }
}

resource "aws_instance" "DORA-worker-e" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.micro"
      lifecycle {
        ignore_changes = [ami]
      }
}

resource "aws_instance" "DORA-scheduler" {
      ami = data.aws_ami.ubuntu_latest.id
      instance_type = "t2.small"
      lifecycle {
        ignore_changes = [ami]
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



