# CodeBuild를 위한 IAM 역할 생성
resource "aws_iam_role" "codebuild_role" {
  name = "wsi-codebuild-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodeBuild를 위한 IAM 정책 연결
resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-service-role-attachment"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CodeBuild 프로젝트 생성
resource "aws_codebuild_project" "wsi_build" {
  name         = "wsi-build"
  description  = "wsi-build"
  build_timeout = 5
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.wsi_repo.clone_url_http
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.bucket.bucket
    packaging = "ZIP"
    name          = "build.zip"
    namespace_type     = "NONE"
    encryption_disabled = true
  }


  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }
}