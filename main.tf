provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "express-ecs-cluster"
}

resource "aws_subnet" "ecs_subnet" {
  count = 1

  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"  
  availability_zone       = "us-east-1a"    

  map_public_ip_on_launch = true
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "express-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "express-container"
      image = "express-app:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        },
      ]
    },
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "express-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.ecs_subnet[0].id]
  }

  depends_on = [aws_ecs_task_definition.ecs_task_definition]
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "express-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"  
}
