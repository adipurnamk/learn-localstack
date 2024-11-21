provider "aws" {  
  region                      = "us-east-1"  
  access_key                  = "test"  
  secret_key                  = "test"  
  skip_region_validation      = true  
  skip_credentials_validation  = true  
}  

# Terraform backend configuration  
terraform {  
  backend "s3" {  
    bucket   = "tf-state-bucket"  # Your bucket name  
    key      = "terraform.tfstate"  
    region   = "us-east-1"  
  }  
}   

# Create VPC  
resource "aws_vpc" "main" {  
  cidr_block = "10.0.0.0/16"  
}  

# Create public subnet  
resource "aws_subnet" "public" {  
  vpc_id            = aws_vpc.main.id  
  cidr_block        = "10.0.1.0/24"  
  map_public_ip_on_launch = true  
}  

# Create private subnet  
resource "aws_subnet" "private" {  
  vpc_id            = aws_vpc.main.id  
  cidr_block        = "10.0.2.0/24"  
}  

# Create NAT Gateway  
resource "aws_nat_gateway" "nat" {  
  allocation_id = aws_eip.nat.id  
  subnet_id    = aws_subnet.public.id  
}  

resource "aws_eip" "nat" {  
  vpc = true  
}  

resource "aws_launch_configuration" "app" {
  name          = "app-launch-configuration"
  image_id      = "ami-0c55b159cbfafe1f0"  # Replace with an Ubuntu AMI, for example, ami-0c55b159cbfafe1f0 is a common Ubuntu AMI
  instance_type = "t2.medium"

  # User data script to install Docker and run a Docker container
  user_data = <<-EOF
              #!/bin/bash
              # Update package index
              apt-get update -y

              # Install Docker
              apt-get install -y docker.io

              # Start Docker service
              systemctl start docker
              systemctl enable docker

              # Run a Docker container (modify the image and options as necessary)
              docker run -d --name my_nginx_app my_nginx_app:0.0.1
              EOF

  lifecycle {
    create_before_destroy = true
  }

  # Configure CloudWatch monitoring
  monitoring {
    enabled = true
  }
}  

# Auto Scaling Group  
resource "aws_autoscaling_group" "app" {  
  desired_capacity     = 2  
  min_size             = 2  
  max_size             = 5  
  vpc_zone_identifier = [aws_subnet.private.id]  
  launch_configuration = aws_launch_configuration.app.id  

  tag {  
    key                 = "Name"  
    value               = "MyInstance"  
    propagate_at_launch = true  
  }  
}  

# CloudWatch monitoring  
resource "aws_cloudwatch_metric_alarm" "cpu" {  
  alarm_name          = "CPU_Utilization_Alarm"  
  metric_name         = "CPUUtilization"  
  namespace           = "AWS/EC2"  
  statistic           = "Average"  
  period              = 300  
  evaluation_periods  = 1  
  threshold           = 45  
  comparison_operator = "GreaterThanOrEqualToThreshold"  
  dimensions = {  
    InstanceId = aws_autoscaling_group.app.instances[0] # autoscale unavailable in localstack free tier
  }  
  alarm_description = "Alarm when CPU exceeds 45%"  
}  