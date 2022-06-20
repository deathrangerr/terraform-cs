resource "aws_security_group" "allow_all" {
  name        = "allow_web-1"
  description = "Allow WEB inbound traffic"

  ingress = [
    {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false

    },
    {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "bullhit"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow_all"
  }
}

resource "aws_instance" "apache-cs" {
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "standard"
  }
  ami = var.ami
  availability_zone = "us-east-1a"
  instance_type = var.instance_type[0]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sed -i '$a /dev/nvme1n1   /webroot  ext4 defaults    1 2' /etc/fstab
                sudo mkdir /webroot
                sudo chmod 0777 /webroot
                sudo mkfs -t xfs -f /dev/nvme1n1
                sudo mount -t xfs -o nouuid /dev/nvme1n1 /webroot
                sudo apt install apache2 -y
                sudo sed -i 'd' /var/www/html/index.html
                sudo echo "Hello Cedit Saison World - running on Apache - on port 80" >> /var/www/html/index.html
                sudo rsync -av /var/www/html /webroot/
                sudo sed -i 's/denied/granted/g' /etc/apache2/apache2.conf
                sudo sed -i 's|/var/www/html|/webroot/html|g' /etc/apache2/sites-enabled/000-default.conf
                sudo sed -i 's|/var/www/html|/webroot/html|g' /etc/apache2/sites-available/default-ssl.conf
                sudo systemctl enable apache2
                sudo systemctl restart apache2
                sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                sudo systemctl restart sshd
                sudo service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:creditsaison@123" | sudo chpasswd
                EOF


  tags = {
    Name = "apache-cs"
         }
}

resource "aws_ebs_volume" "apache-cs" {
  availability_zone = "us-east-1a"
  size              = 1

  tags = {
    Name = "apache-cs"
  }
}

resource "aws_volume_attachment" "ebs_att_apache_cs" {
  device_name = "/dev/sdg"
  volume_id   = "${aws_ebs_volume.apache-cs.id}"
  instance_id = "${aws_instance.apache-cs.id}"
}

resource "aws_instance" "nginx-cs" {
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "standard"
  }
  ami = var.ami
  availability_zone = "us-east-1b"
  instance_type = var.instance_type[1]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sed -i '$a /dev/nvme1n1   /webroot  ext4 defaults    1 2' /etc/fstab
                sudo mkdir /webroot
                sudo chmod 0777 /webroot
                sudo mkfs -t xfs -f /dev/nvme1n1
                sudo mount -t xfs -o nouuid /dev/nvme1n1 /webroot
                sudo apt install nginx -y
                sudo sed -i 'd' /usr/share/nginx/html/index.html
                sudo echo "Hello Cedit Saison World - running on Nginx - on port 80" >> /usr/share/nginx/html/index.html
                sudo rsync -av /usr/share/nginx/html /webroot/
                sudo sed -i 's|/var/www/html|/webroot/html|g' /etc/nginx/sites-available/default
                sudo sed -i 's|/var/www/html|/webroot/html|g' /etc/nginx/sites-enabled/default
                sudo systemctl enable nginx
                sudo systemctl restart nginx
                sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                sudo systemctl restart sshd
                sudo service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:creditsaison@123" | sudo chpasswd
                EOF



  tags = {
    Name = "nginx-cs"
         }
}

resource "aws_ebs_volume" "nginx-cs" {
  availability_zone = "us-east-1b"
  size              = 1

  tags = {
    Name = "nginx-cs"
  }
}

resource "aws_volume_attachment" "ebs_att_nginx_cs" {
  device_name = "/dev/sdg"
  volume_id   = "${aws_ebs_volume.nginx-cs.id}"
  instance_id = "${aws_instance.nginx-cs.id}"
}





data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "subnet" {
    vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_lb-http" {
  name        = "allow_web-lb"
  description = "Allow WEB inbound traffic"
    ingress = [
    {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "http"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow_alb"
  }
}

resource "aws_lb_target_group" "target-group" {
    health_check {
        interval            = 10
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
    name          = "credit-saison-tg"
    port          = 80
    protocol      = "HTTP"
    target_type   = "instance"
    vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "application-lb" {
    name            = "credit-saison-alb"
    internal        = false
    ip_address_type     = "ipv4"
    load_balancer_type = "application"
    security_groups = [aws_security_group.allow_lb-http.id]
    subnets = data.aws_subnet_ids.subnet.ids
    tags = {
        Name = "credit-saison-alb"
    }
}

resource "aws_lb_listener" "alb-listener" {
    load_balancer_arn          = aws_lb.application-lb.arn
    port                       = 80
    protocol                   = "HTTP"
    default_action {
        target_group_arn         = aws_lb_target_group.target-group.arn
        type                     = "forward"
    }
}

resource "aws_lb_target_group_attachment" "nginx-cs" {
#    count = length(aws_instance.nginx-cs
    target_group_arn = aws_lb_target_group.target-group.arn
    target_id        = aws_instance.nginx-cs.id
}

resource "aws_lb_target_group_attachment" "apache-cs" {
#    count = length(aws_instance.nginx-cs
    target_group_arn = aws_lb_target_group.target-group.arn
    target_id        = aws_instance.apache-cs.id
}