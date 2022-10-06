# Compute main.tf

resource "aws_instance" "home_app" {
  count = var.instance_count
  ami = var.ami_id
  instance_type = var.instance_type
  tags = {
    Name = "${var.instance_name}-${count.index+1}"
  }
  vpc_security_group_ids = [var.webServer_sg_id]
  subnet_id = var.subnet_ids[count.index]
  user_data = "${file(var.userData_path)}"

}

resource "aws_launch_template" "ekart_product_lt" {
  name = var.launch_template_name
  instance_type = var.instance_type
  image_id = var.ami_id
  user_data = filebase64(var.template_userData_path)
  vpc_security_group_ids = [var.webServer_sg_id]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "productsApp"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "products_asg" {
  name = var.asg_name
  vpc_zone_identifier = var.subnet_ids
  desired_capacity   = var.desired_instance_size
  max_size           = var.max_instance_size
  min_size           = var.min_instance_size
  target_group_arns = [var.tg_products_arn]
  launch_template {
    id = aws_launch_template.ekart_product_lt.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# resource "aws_autoscaling_attachment" "asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.products_asg.id
#   lb_target_group_arn = var.tg_products_arn
# }

resource "aws_lb_target_group_attachment" "tg_attach" {
  count = var.instance_count
  target_group_arn = var.tg_home_arn
  target_id = aws_instance.home_app[count.index].id
  port = 80
}