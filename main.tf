data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.us-east-1.s3"
}

resource "aws_vpc" "main" {
  cidr_block                           = "10.0.0.0/16"
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"
  tags = {
    "Name" = "main"
  }
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.main_rtb_private1.id, aws_route_table.main_rtb_private2.id]

  tags = {
    "Name" = "s3"
  }
}


# ----------- IGW ---------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "igw"
  }
}

# --------- SUBNETS -------------

resource "aws_subnet" "public1" {
  availability_zone                   = "us-east-1a"
  cidr_block                          = "10.0.0.0/20"
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    "Name" = "public1"
  }
  vpc_id = aws_vpc.main.id
}


resource "aws_subnet" "public2" {
  availability_zone                   = "us-east-1b"
  cidr_block                          = "10.0.16.0/20"
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    "Name" = "public2"
  }

  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "private1" {
  availability_zone                   = "us-east-1a"
  cidr_block                          = "10.0.128.0/20"
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    "Name" = "private1"
  }

  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "private2" {
  availability_zone                   = "us-east-1b"
  cidr_block                          = "10.0.144.0/20"
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    "Name" = "private2"
  }

  vpc_id = aws_vpc.main.id
}

# ---------- NAT EIP -----------

resource "aws_eip" "nat_eip" {
  domain               = "vpc"
  network_border_group = "us-east-1"
  public_ipv4_pool     = "amazon"
  tags = {
    "Name" = "nat-eip"
  }
}


# ----------- NAT ---------------

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "nat_gw"
  }

  depends_on = [aws_internet_gateway.igw]
}


# -------- ROUTES -------

resource "aws_route_table" "main_rtb_public" {
  tags = {
    "Name" = "main_rtb_public"
  }
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "main_rtb_public_igw" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.main_rtb_public.id
}

resource "aws_route_table" "main_rtb_private1" {
  tags = {
    "Name" = "main_rtb_private1"
  }
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "main_rtb_private1_nat" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  route_table_id         = aws_route_table.main_rtb_private1.id
}

resource "aws_route_table" "main_rtb_private2" {
  tags = {
    "Name" = "main_rtb_private2"
  }
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "main_rtb_private2_nat" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  route_table_id         = aws_route_table.main_rtb_private2.id
}

# ------ security groups ------------

resource "aws_security_group" "ingress_sg" {
  name        = "allow-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow-http"
  }
}

# Ingress rule to allow incoming HTTP traffic
resource "aws_security_group_rule" "allow_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ingress_sg.id
}

# Ingress rule to allow incoming HTTPS traffic
resource "aws_security_group_rule" "allow_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ingress_sg.id
}

# Egress rule to allow all outbound traffic
resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ingress_sg.id
}


# ----- EC2 Instances -----

# Fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# EC2 Instance in Private Subnet 1
resource "aws_instance" "host1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private1.id
  key_name      = "nuvei_key" # replace with your key pair name

  tags = {
    Name = "host1"
  }

  vpc_security_group_ids = [aws_security_group.ingress_sg.id]
}

# EC2 Instance in Private Subnet 2
resource "aws_instance" "host2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private2.id
  key_name      = "nuvei_key" # replace with your key pair name

  tags = {
    Name = "host2"
  }

  vpc_security_group_ids = [aws_security_group.ingress_sg.id]
}

# ----- Route 53 Hosted Zone -----

resource "aws_route53_zone" "nuvei_zone" {
  name = "nuvei-test.com" # placeholder domain
}

# ----- CNAME Record for ELB -----

resource "aws_route53_record" "elb_cname" {
  zone_id = aws_route53_zone.nuvei_zone.zone_id
  name    = "elb.nuvei-test.com" # assuming this naming convention but can be any name really
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.nuvei_lb.dns_name]
}

# ----- ACM Certificate ----------


resource "aws_acm_certificate" "nuvei_cert" {
  domain_name               = "nuvei-test.com"
  subject_alternative_names = ["elb.nuvei-test.com"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.nuvei_cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.nuvei_zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.nuvei_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# ----- Elastic Load Balancer (ELB) -----

# Create a load balancer
resource "aws_lb" "nuvei_lb" {
  name               = "nuvei-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false

  tags = {
    Name = "nuvei_lb"
  }
}

# ----- Target Group -----

# Create target group
resource "aws_lb_target_group" "nuvei_lb_tg" {
  name     = "nuvei-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }
}

# Register instances with target group
resource "aws_lb_target_group_attachment" "host1" {
  target_group_arn = aws_lb_target_group.nuvei_lb_tg.arn
  target_id        = aws_instance.host1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "host2" {
  target_group_arn = aws_lb_target_group.nuvei_lb_tg.arn
  target_id        = aws_instance.host2.id
  port             = 80
}

# ----- Listeners -----

# Listener for HTTP (port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nuvei_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nuvei_lb_tg.arn
  }
}

# Listener for HTTPS (port 443) - Requires a valid SSL certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nuvei_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nuvei_lb_tg.arn
  }
}

