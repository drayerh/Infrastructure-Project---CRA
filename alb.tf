# Creating External LoadBalancer
resource "aws_lb" "external" {
  name                       = "ayerhvpc external alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.web_tier.id]
  subnets                    = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "web_tier" {
  name     = "my web tier target group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ayerhvpc.id
}

resource "aws_lb_target_group_attachment" "web_tier_1" {
  target_group_arn = aws_lb_target_group.web_tier.arn
  target_id        = aws_instance.web_tier_1.id
  port             = 80

  depends_on = [
    aws_instance.web_tier_1
  ]
}

resource "aws_lb_target_group_attachment" "web_tier_2" {
  target_group_arn = aws_lb_target_group.web_tier.arn
  target_id        = aws_instance.web_tier_2.id
  port             = 80

  depends_on = [
    aws_instance.web_tier_2
  ]
}

resource "aws_lb_listener" "listener1" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_elb.arn
  }
}


#Configuring Auto Scaling for Web Tier

#creating a placement group
resource "aws_placement_group" "web_tier" {
  name     = "web tier instances placement group"
  strategy = "cluster"
}

#creating an autoscaling group
resource "aws_autoscaling_group" "web_tier" {
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.web_tier.id
    version = "$Latest"
  }
}
  
#Creating launch template for Web Tier Auto Scaling Group
resource "aws_launch_template" "web_tier" {
  name_prefix   = "web_tier_launch_template"
  image_id      = "ami-0648ea225c13e0729"
  instance_type = "t2.micro"
}


#Creating an Auto Scaling Attachment for Web Servers
resource "aws_autoscaling_attachment" "web_tier" {
  autoscaling_group_name = aws_autoscaling_group.web_tier.id
  elb                    = aws_lb.external.id
}






#Creating an Internal Elastic Load Balancer

# Creating External LoadBalancer
resource "aws_lb" "internal" {
  name                       = "ayerhvpc internal alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.app_tier.id]
  subnets                    = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_tier" {
  name     = "my app tier target group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ayerhvpc.id
}

resource "aws_lb_target_group_attachment" "app_tier_1" {
  target_group_arn = aws_lb_target_group.app_tier.arn
  target_id        = aws_instance.app_tier_1.id
  port             = 80

  depends_on = [
    aws_instance.app_tier_1
  ]
}

resource "aws_lb_target_group_attachment" "app_tier_2" {
  target_group_arn = aws_lb_target_group.web_tier.arn
  target_id        = aws_instance.app_tier_2.id
  port             = 80

  depends_on = [
    aws_instance.web_tier_2
  ]
}

resource "aws_lb_listener" "listener2" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier.arn
  }
}


#Configuring Auto Scaling for App Tier

#creating a placement group
resource "aws_placement_group" "app_tier" {
  name     = "app tier instances placement group"
  strategy = "cluster"
}

#creating an autoscaling group
resource "aws_autoscaling_group" "app_tier" {
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }
}
  
  
#Creating launch template for App Tier Auto Scaling Group
resource "aws_launch_template" "app_tier" {
  name_prefix   = "app_tier_launch_template"
  image_id      = "ami-0648ea225c13e0729"
  instance_type = "t2.micro"
}


#Creating an Auto Scaling Attachment for App Servers
resource "aws_autoscaling_attachment" "app_tier" {
  autoscaling_group_name = aws_autoscaling_group.app_tier.id
  elb                    = aws_lb.internal.id
}
