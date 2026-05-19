terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
    }
  }
}

resource "spacelift_stack" "aws_playground_stack" {
  name = "AWS Playground"
  repository = "terraform-repo"
  branch = "master"
  project_root = "aws-playground"
  manage_state = true
}

resource "spacelift_aws_integration" "aws_link" {
  name = "aws-connection"
  role_arn = "arn:aws:iam::697790871057:role/spacelift-playground"
}

resource "spacelift_aws_integration_attachment" "link_attachment" {
  integration_id = spacelift_aws_integration.aws_link.id
  stack_id       = spacelift_stack.aws_playground_stack.id
  read           = true
  write          = true
}