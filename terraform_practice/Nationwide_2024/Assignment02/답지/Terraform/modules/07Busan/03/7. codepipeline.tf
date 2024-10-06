# # S3 버킷 생성 (CodeBuild 아티팩트를 저장할 장소)
# resource "aws_s3_bucket" "wsi_bucket" {
#   bucket = "wsi-build-artifacts-bucket-${random_string.random_name.result}"

#   tags = {
#     Name = "wsi-build-artifacts-bucket-${random_string.random_name.result}"
#   }
# }

# CodePipeline 역할 생성
resource "aws_iam_role" "codepipeline_role" {
  name = "wsi-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodePipeline 역할에 AdministratorAccess 정책 첨부
resource "aws_iam_role_policy_attachment" "codepipeline_admin_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}



# CodePipeline 생성
resource "aws_codepipeline" "wsi_pipeline" {
  name     = "wsi-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.wsi_repo.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.wsi_build.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.wsi_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.wsi_app_deployment_group.deployment_group_name
      }
    }
  }
}

output "codepipeline_id" {
  value = aws_codepipeline.wsi_pipeline.id
}
