// Security groups
resource "aws_security_group" "web" {
  name        = "dev-ssum-web-sg"
  description = "accept all ports"
  vpc_id      = aws_vpc.vpc.id
  // 인바운드 규칙: 모든 트래픽 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  // 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "dev-ssum-web-sg"
  }
}

resource "aws_security_group" "was" {
  name        = "dev-ssum-was-sg"
  description = "accept all ports"
  vpc_id      = aws_vpc.vpc.id

  // 인바운드 규칙: 모든 트래픽 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  // 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "dev-ssum-was-sg"
  }
}

// EC2 Instance (ubuntu)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = "t2.micro"
  key_name                    = var.key
  vpc_security_group_ids      = [aws_security_group.web.id]
  subnet_id                   = aws_subnet.public[0].id
  availability_zone           = "ap-northeast-2a"
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              systemctl enable nginx
              EOF
  tags = {
    Name = "dev-ssum-pub-web"
  }
}

resource "aws_instance" "was" {
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = "t2.micro"
  key_name                    = var.key
  vpc_security_group_ids      = [aws_security_group.was.id]
  subnet_id                   = aws_subnet.private[0].id
  availability_zone           = "ap-northeast-2a"
  associate_public_ip_address = false
  user_data                   = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y tomcat9
              EOF
  tags = {
    Name = "dev-ssum-priv-was"
  }
}

// Target group (web)
resource "aws_lb_target_group" "web-tg" {
  name     = "dev-ssum-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

// Target group (was)
resource "aws_lb_target_group" "was-tg" {
  name     = "dev-ssum-was-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

// Target attach (web)
resource "aws_lb_target_group_attachment" "web-tg-attach" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

// Target attach (was)
resource "aws_lb_target_group_attachment" "was-tg-attach" {
  target_group_arn = aws_lb_target_group.was-tg.arn
  target_id        = aws_instance.was.id
  port             = 8080
}

// EX LoadBalancer (Application)
resource "aws_lb" "web-lb" {
  name               = "dev-ssum-ex-alb"
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
  security_groups = [aws_security_group.web.id]
}

# HTTP Listener for IN LB
resource "aws_lb_listener" "web-http" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }
}

// EX LoadBalancer (Application)
resource "aws_lb" "was-lb" {
  name               = "dev-ssum-in-alb"
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
  security_groups = [aws_security_group.web.id]
}

# HTTP Listener for IN LB
resource "aws_lb_listener" "was-http" {
  load_balancer_arn = aws_lb.was-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.was-tg.arn
  }
}

// RDS 
/* resource "aws_db_instance" "rds" {
  allocated_storage    = 10
  db_name              = "maincontents"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "brickmate"
  password             = "1q2w3e4r!"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
} */