provider "aws" {
  region = var.region
}

# Create ECR repository
resource "aws_ecr_repository" "flask-repo" {
  name = var.app_name
}

# Create ECR repository lifecycle policy to keep only last 2 docker images
resource "aws_ecr_lifecycle_policy" "flask-repo-lifecycle" {
  repository = aws_ecr_repository.flask-repo.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# Fetch availability zones in current region
data "aws_availability_zones" "available" {}

# Create new VPC with cidr defined in variables
resource "aws_vpc" "flask-vpc" {
  cidr_block = var.vpc_cidr
  tags       = { "Name" : var.app_name }
}

# Create 3 public subnets and divide vpc cidr into 3 subnet cidrs and place them into different aws_availability_zone
resource "aws_subnet" "flask-vpc-public-subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.flask-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.flask-vpc.cidr_block, 3, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags                    = { "Name" : var.app_name }
}

# Create Internet Gateway
resource "aws_internet_gateway" "flask-igw" {
  vpc_id = aws_vpc.flask-vpc.id
  tags   = { "Name" : var.app_name }
}

# Create Route Table for public subnets
resource "aws_route_table" "flask-public-rt" {
  vpc_id = aws_vpc.flask-vpc.id
  tags   = { "Name" : var.app_name }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flask-igw.id
  }
}

# Associate the subnets with the public route table
resource "aws_route_table_association" "flask-public-rt-assoc" {
  count          = 3
  subnet_id      = aws_subnet.flask-vpc-public-subnet[count.index].id
  route_table_id = aws_route_table.flask-public-rt.id
}

# Create ECS Cluster
resource "aws_ecs_cluster" "flask-cluster" {
  name = "flask-ecs-cluster"
}

# Create ecs task execution role. Make sure the name is unique and not already exists.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "flask-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

# Create cloud watch log group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7
}

# Create task definition and use container definition from the file
resource "aws_ecs_task_definition" "flask-task" {
  family                   = "flask-task-definition"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name : var.app_name,
    image : "${aws_ecr_repository.flask-repo.repository_url}:latest",
    essential : true,
    portMappings : [
      {
        containerPort : 8082,
        hostPort : 8082
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.app_name}"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    }
  ])
}

# Security Group for ALB - Allows all incoming traffic
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.flask-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS - Allows only traffic from ALB to port 8082
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.flask-vpc.id

  ingress {
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ecs service
resource "aws_ecs_service" "flask-service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.flask-cluster.id
  task_definition = aws_ecs_task_definition.flask-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.flask-vpc-public-subnet[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.flask-app-tg.arn
    container_name   = var.app_name
    container_port   = 8082
  }

}

# Create Application load balancer
resource "aws_lb" "flask-alb" {
  name               = "flask-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.flask-vpc-public-subnet[*].id
}

# Target group to attach to listener
resource "aws_lb_target_group" "flask-app-tg" {
  name        = "flask-app-tg"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = aws_vpc.flask-vpc.id
  target_type = "ip"
}

# ALB listener on port 80 to forward request to target group
resource "aws_lb_listener" "flask-alb-listener" {
  load_balancer_arn = aws_lb.flask-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask-app-tg.arn
  }
}