
provider "aws" {
  region     = "ap-south-1"
  profile    = "yashika"
}

 resource "aws_vpc" "vpc_task4" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "vpc_task4"
 }
}

resource "aws_subnet" "Public_subnet" {
  vpc_id     = aws_vpc.vpc_task4.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Public_subnet"
  }
 }

resource "aws_subnet" "Private_subnet" {
  vpc_id     = aws_vpc.vpc_task4.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Private_subnet"
  }
}

resource "aws_internet_gateway" "gw_task4" {
  vpc_id = aws_vpc.vpc_task4.id
  tags = {
    Name = "gw_task4"
  }
}

resource "aws_route_table" "rt_task4" {
  vpc_id = aws_vpc.vpc_task4.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_task4.id
  }
  tags = {
    Name = "rt_task4"
  }

}

resource "aws_route_table_association" "rt_asso" {
  subnet_id      = aws_subnet.Public_subnet.id
  route_table_id = aws_route_table.rt_task4.id

}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw_task4]
}

resource "aws_nat_gateway" "nat_gw_task4" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.Public_subnet.id
  tags = {
    Name = "nat_gw_task4"
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = aws_vpc.vpc_task4.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_task4.id
  }
  tags = {
    Name = "task4_rt"
  }
}

resource "aws_route_table_association" "nat_gw_asso" {
  subnet_id      = aws_subnet.Private_subnet.id
  route_table_id = aws_route_table.nat_route.id
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_task4.id

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }

}

resource "aws_instance" "mysql" {
  ami           = "ami-05cd98f1dad0314fd"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.allow_mysql.id ]
  subnet_id = aws_subnet.Private_subnet.id
  user_data = <<-EOF
        
        #!/bin/bash
        sudo docker run -dit -p 8080:3306 --name mysql -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_DATABASE=task-db -e MYSQL_USER=yashika -e MYSQL_PASSWORD=redhat mysql:5.7
  
  EOF

  tags = {
    Name = "allow_Mysql"
  }
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Allow tcp for inbound traffic"
  vpc_id      = aws_vpc.vpc_task4.id
  ingress {
    description = "TLS from VPC"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_wp"
  }
}

resource  "aws_instance"  "wordpress" {
  ami                          = "ami-05cd98f1dad0314fd"
  instance_type                = "t2.micro"
  availability_zone            = "ap-south-1a"
  subnet_id                    = aws_subnet.Public_subnet.id
  vpc_security_group_ids       = [ aws_security_group.wordpress_sg.id ]
  associate_public_ip_address  = "true"
  
  user_data = <<-EOF
        #!/bin/bash
        sudo docker run -dit -p 8081:80 --name wp wordpress:5.1.1-php7.3-apache
  EOF
    
  tags = {
    Name = "wordpress"  
  }
}
