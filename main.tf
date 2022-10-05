terraform {
  required_providers {
    aws = {
      version = "~>4.32.0"
    }
    null = {
      version = "~> 3.1.1"
    }
    template = {
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #var later
}

resource "aws_key_pair" "key_pair_test" {
  key_name   = "key_pair_test"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGD/z0j+e/Hmvlu9nDnXejNZ6m1ftw4LM/q1za4lfJG2rLg2iJRS3RCDw4tONccxdJhDaNU7fCvP2WdQqMRCodFWckXmgTq438MhTKOXLfYVySOIQjemDG2M9mja7NPaVdlEgfsmIOxj4VlNVN3MaV8guakmv49WAlkwRIYI0o7CGWEcPGXF2vFVy+nFvxAGkGQYe2NaCHWMvo4NZQcwekg9e4elkDGRMfHglyH7nHounJC2Qarf2J81sS2jx8fRY7p9s6phGP2e/xnPnEYmpU17qbgvjqOj+tz1wW40WECIJswqCG5uTP7KfGdJMe1M95GVULNidVK57F/JxI380KtSNaHFH+sarlzwdMQZqCM0Cz5ue4ksnJnzAjjYFdiKRpgzUElP4C+KqAsveWXudWZZgQ+Z5zjNCW+pe/LHNVmlvObgdmWIHu1dXPpQIPA53AijiMkixFhzPp5p1lPMIeZSHA8Si15326E7XlzLJfV0l1v9ELy5bPHIV0KzqkogM= grniss@chol-macbook.local"

  # var later

  tags = {
    Name = "key_pair_test"
  }
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc1"
  }
}


# data "aws_availability_zone" "az" {
#   state = "available"
# }

resource "aws_subnet" "subnet_public" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/26"
  availability_zone = "us-east-1a"
  # var later

  tags = {
    Name = "subnet_public"
  }
}

resource "aws_subnet" "subnet_link" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = "us-east-1a"
  # var later

  tags = {
    Name = "subnet_link"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.128/26"
  availability_zone = "us-east-1a"
  # var later

  tags = {
    Name = "subnet_private"
  }
}

resource "aws_subnet" "subnet_vpc" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.192/26"
  availability_zone = "us-east-1a"
  # var later

  tags = {
    Name = "subnet_vpc"
  }
}


resource "aws_security_group" "security_group_app" {
  name        = "security_group_app"
  description = "security group for app"
  vpc_id      = aws_vpc.vpc1.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "security_group_app"
  }
}

resource "aws_security_group" "security_group_db" {
  name        = "security_group_db"
  description = "security group for db"
  vpc_id      = aws_vpc.vpc1.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_app.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "security_group_db"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_network_interface" "eni_public" {
  subnet_id       = aws_subnet.subnet_public.id
  security_groups = [aws_security_group.security_group_app.id]

  # attachment {
  #   instance     = aws_instance.ec2_instance_app.id
  #   device_index = 0
  # }
  tags = {
    Name = "eni_public"
  }
}

resource "aws_network_interface" "eni_link_public" {
  subnet_id       = aws_subnet.subnet_link.id
  security_groups = [aws_security_group.security_group_app.id]

  tags = {
    Name = "eni_link_public"
  }
}

resource "aws_network_interface" "eni_link_private" {
  subnet_id       = aws_subnet.subnet_link.id
  security_groups = [aws_security_group.security_group_db.id]

  tags = {
    Name = "eni_link_private"
  }
}

resource "aws_network_interface" "eni_private" {
  subnet_id       = aws_subnet.subnet_private.id
  security_groups = [aws_security_group.security_group_db.id]

  tags = {
    Name = "eni_private"
  }
}

resource "aws_instance" "ec2_instance_db" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = aws_key_pair.key_pair_test.key_name
  user_data         = file("./maria.sh")
  # var later

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni_private.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni_link_private.id
  }

  tags = {
    Name = "ec2_instance_db"
  }
}

data "template_file" "init_wordpress" {
  template = file("./wordpress.sh.tpl")

  vars = {
    private_ip_db = "${aws_instance.ec2_instance_db.private_ip}"
  }
}

resource "aws_instance" "ec2_instance_app" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = aws_key_pair.key_pair_test.key_name
  user_data         = data.template_file.init_wordpress.rendered

  # var later

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni_public.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni_link_public.id
  }

  tags = {
    Name = "ec2_instance_app"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "elastic_ip_public" {
  vpc = true

  network_interface = aws_network_interface.eni_public.id
  depends_on        = [aws_internet_gateway.igw, aws_instance.ec2_instance_app]

  tags = {
    Name = "elastic_ip_public"
  }
}

resource "aws_eip" "elastic_ip_nat" {
  vpc = true

  # network_interface = aws_network_interface.eni_nat.id
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "elastic_ip_nat"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip_nat.id
  subnet_id     = aws_subnet.subnet_vpc.id

  tags = {
    Name = "nat_gateway"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table_public"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table" "route_table_vpc" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table_vpc"
  }
}

resource "aws_route_table_association" "route_table_association_vpc" {
  subnet_id      = aws_subnet.subnet_vpc.id
  route_table_id = aws_route_table.route_table_vpc.id
}

resource "aws_route_table" "route_table_nat" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "route_table_nat"
  }
}

resource "aws_route_table_association" "route_table_association_nat" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_nat.id
}
