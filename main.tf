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
  region = var.region
}

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key_pair"
  public_key = tls_private_key.key_pair.public_key_openssh

  tags = {
    Name = "key_pair"
  }
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/26"
  availability_zone = var.availability_zone

  tags = {
    Name = "subnet_public"
  }
}

resource "aws_subnet" "subnet_link" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = var.availability_zone

  tags = {
    Name = "subnet_link"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.128/26"
  availability_zone = var.availability_zone

  tags = {
    Name = "subnet_private"
  }
}

resource "aws_subnet" "subnet_vpc" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.192/26"
  availability_zone = var.availability_zone

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

resource "aws_network_interface" "eni_public" {
  subnet_id       = aws_subnet.subnet_public.id
  security_groups = [aws_security_group.security_group_app.id]

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


data "template_file" "init_mariadb" {
  template = file("./maria.sh.tpl")

  vars = {
    database_name = "${var.database_name}"
    database_user = "${var.database_user}"
    database_pass = "${var.database_pass}"
  }
}

resource "aws_instance" "ec2_instance_db" {
  ami               = var.ami
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.key_pair.key_name
  user_data         = data.template_file.init_mariadb.rendered

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
    database_name = "${var.database_name}"
    database_user = "${var.database_user}"
    database_pass = "${var.database_pass}"
    admin_user    = "${var.admin_user}"
    admin_pass    = "${var.admin_pass}"
  }
}


resource "aws_instance" "ec2_instance_app" {
  ami               = var.ami
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.key_pair.key_name
  user_data         = data.template_file.init_wordpress.rendered

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

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "route_table_private"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_private.id
}


resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = {
    "Name" = "s3_bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "publiic_access_block_for_wordpress" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "iam_policy_for_s3_user" {
  statement {
    sid = "1"

    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:PutBucketAcl",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "iam_policy" {
  name   = "iam_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_for_s3_user.json

}

resource "aws_iam_user" "iam_user" {
  name = "iam_user"
}

resource "aws_iam_policy_attachment" "iam_policy_attachment" {
  name       = "iam_policy_attachment"
  users      = [aws_iam_user.iam_user.name]
  policy_arn = aws_iam_policy.iam_policy.arn
}

resource "aws_iam_access_key" "iam_access_key" {
  user = aws_iam_user.iam_user.name
}

locals {
  s3_plugin_script = <<EOF
  '/.* Add any custom values.*/a define("AS3CF_SETTINGS", serialize( array(\n    "provider" => "aws",\n    "access-key-id" => "${aws_iam_access_key.iam_access_key.id}",\n    "secret-access-key" => "${aws_iam_access_key.iam_access_key.secret}",\n    "use-server-roles" => true,\n    "bucket" => "${var.bucket_name}",\n    "region" => "${var.region}",\n    "copy-to-s3" => true,\n    "enable-object-prefix" => true,\n    "object-prefix" => "wp-content/uploads/",\n    "use-yearmonth-folders" => true,\n    "object-versioning" => true,\n    "delivery-provider" => "storage",\n    "delivery-provider-name" => "${var.bucket_name}",\n    "serve-from-s3" => true,\n    "enable-delivery-domain" => false,\n    "delivery-domain" => "cdn.example.com",\n    "enable-signed-urls" => false,\n    "force-https" => false,\n    "remove-local-file" => false,\n) ) );' wp-config.php
  EOF
}

resource "null_resource" "wp_setup" {

  depends_on = [
    aws_instance.ec2_instance_app,
    aws_instance.ec2_instance_db,
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.key_pair.private_key_pem
    host        = aws_eip.elastic_ip_public.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "timeout 120 sh -c 'until nc -z $0 $1; do sleep 1; done' ${aws_instance.ec2_instance_db.private_ip} 3306",
      "sudo wp config create --dbname=${var.database_name} --dbuser=${var.database_user} --dbpass=${var.database_pass} --dbhost=${aws_instance.ec2_instance_db.private_ip} --path=/var/www/html --allow-root",
      "sudo chown -R ubuntu:www-data /var/www/html",
      "sudo chmod -R 774 /var/www/html",
      "sudo rm /var/www/html/index.html",
      "sudo systemctl restart apache2",

      "wp core install --url=${aws_eip.elastic_ip_public.public_ip} --title=wp101 --admin_user=${var.admin_user} --admin_password=${var.admin_pass} --admin_email=no@email.com --skip-email --path=/var/www/html",
      "cd /var/www/html",
      "sed -i ${local.s3_plugin_script}",
      "wp plugin install amazon-s3-and-cloudfront",
      "wp plugin activate amazon-s3-and-cloudfront",
    ]
  }
}
