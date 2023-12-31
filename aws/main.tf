resource "aws_key_pair" "rplkey" {
  key_name = "rplkey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

# resource "aws_instance" "jumphost" {
#   ami = var.AMI
#   instance_type = "t2.micro"
#   key_name = aws_key_pair.rplkey.key_name
#   iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
#   associate_public_ip_address = true
#   security_groups = [ aws_security_group.rpl-security-group.id ]
#   subnet_id = aws_subnet.public-b.id
#   tags = {
#     Name = "Jumphost"
#   }
# }

# autoscaling launch config
resource "aws_launch_configuration" "custom-launch-config" {
  depends_on = [ aws_db_instance.db-rpl ]
  name = "custom-launch-config"
  image_id = var.AMI
  instance_type = "t2.micro"
  key_name = aws_key_pair.rplkey.key_name
  security_groups = [ aws_security_group.rpl-security-group.id ]
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx git mysql-client
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

sudo npm install pm2 -g

sudo git clone https://github.com/Arrizki16/high-availability-web-infrastructure.git /var/www/app/
mysql -u ${aws_db_instance.db-rpl.username} -p${var.RDS_PASS} -h ${aws_db_instance.db-rpl.address} < /var/www/app/aws/db.sql
# export AWS_ACCESS_KEY_ID="${var.AWS_ACCESS_KEY}"
# export AWS_SECRET_ACCESS_KEY="${var.AWS_SECRET_KEY}"

cd /var/www/app/src
sudo echo "DB_NAME="${var.RDS_NAME}"
DB_USER="${var.RDS_USER}"
DB_PASSWORD="${var.RDS_PASS}"
DB_HOST="${aws_db_instance.db-rpl.address}"
DB_PORT=3306

ACCESS_KEY="${var.AWS_ACCESS_KEY}"
SECRET_ACCESS_KEY="${var.AWS_SECRET_KEY}"
AWS_REGION="${var.AWS_REGION}"
AWS_BUCKET_NAME="${aws_s3_bucket.rpl-s3-bucket.id}"" > .env
sudo npm install
sudo pm2 start ecosystem.config.cjs

sudo echo "server {  
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" > /etc/nginx/sites-available/app.conf

sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
EOF
}

# autoscaling group
resource "aws_autoscaling_group" "custom-group-autoscaling" {
  name = "custom-group-autoscaling"
  vpc_zone_identifier = [aws_subnet.private-a.id]
  launch_configuration = aws_launch_configuration.custom-launch-config.name
  min_size = 1
  max_size = 10
  health_check_grace_period = 10
  health_check_type = "EC2"
  force_delete = true
  tag {
    key = "Name"
    value = "custom_ec2_instance"
    propagate_at_launch = true
  }
}

# load balance attachment
resource "aws_autoscaling_attachment" "elb-attachment" {
  autoscaling_group_name = aws_autoscaling_group.custom-group-autoscaling.name
  lb_target_group_arn = aws_lb_target_group.target-group.arn
}

# autoscaling config policy
resource "aws_autoscaling_policy" "custom-cpu-policy" {
  name = "custom-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.custom-group-autoscaling.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 120
  policy_type = "SimpleScaling"
}

# cloud watch monitoring
resource "aws_cloudwatch_metric_alarm" "custom-cpu-alarm" {
  alarm_name = "custom-cpu-alarm"
  alarm_description = "alarm once cpu usage increases"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 70

  dimensions = {
    "AutoScalingGroupName": aws_autoscaling_group.custom-group-autoscaling.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.custom-cpu-policy.arn]
}

# autodescaling policy
resource "aws_autoscaling_policy" "custom-cpu-policy-scaledown" {
  name = "custom-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.custom-group-autoscaling.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown = 120
  policy_type = "SimpleScaling"
}

# descaling cloud watch
resource "aws_cloudwatch_metric_alarm" "custom-cpu-alarm-scaledown" {
  alarm_name = "custom-cpu-alarm-scaledown"
  alarm_description = "alarm once cpu usage decreases"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 70

  dimensions = {
    "AutoScalingGroupName": aws_autoscaling_group.custom-group-autoscaling.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.custom-cpu-policy-scaledown.arn]
}