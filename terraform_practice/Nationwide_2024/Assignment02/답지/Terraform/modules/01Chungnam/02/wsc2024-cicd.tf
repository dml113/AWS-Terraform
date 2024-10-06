resource "aws_codecommit_repository" "example" {
  repository_name = "wsc2024-cci"
}

# S3 버킷 이름에 사용할 랜덤 문자열 생성을 위한 리소스
resource "random_string" "random_name" {
  length  = 2
  special = false
  upper   = false
  number  = false 
}

# S3 버킷 설정
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-artifacts-${random_string.random_name.result}"
}

### 역할- Codebuild ###
resource "aws_iam_role" "codebuild_role" {
  name = "Chungnam_build-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role.json
}

### 정책-codebuild ###
data "aws_iam_policy_document" "codebuild_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
# policy-build
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# policy-ecr
resource "aws_iam_role_policy_attachment" "role_policy_attachment2" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "role_policy_attachment3" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# codecommnit
resource "aws_iam_role_policy_attachment" "CodeCommitFullAccess" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}
# codepipeline 
resource "aws_iam_role_policy_attachment" "CodePipeline_FullAccess" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
# policy-ecs
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
# policy-ecs-task 
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CodeBuild 프로젝트 설정
resource "aws_codebuild_project" "example" {
  name          = "wsc2024-cbd"
  service_role  = aws_iam_role.codebuild_role.arn
  description   = "CodeBuild project for wsc2024"
  build_timeout = 5

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.example.clone_url_http
    buildspec       = "buildspec.yml"
    git_clone_depth = 1
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:ListRepositories",
      "codecommit:BatchGetRepositories",
      "codecommit:GitPull",
      "codecommit:GitPush",
      "codecommit:UploadArchive",
      "codecommit:CancelUploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:ListBranches",
      "codecommit:ListPullRequests",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "Chungnam_codebuild-policy"
  description = "Policy for CodeBuild"
  policy      = data.aws_iam_policy_document.codebuild_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# CodePipeline IAM 역할 설정
resource "aws_iam_role" "codepipeline_role" {
  name               = "Chungnam_wsc2024-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_policy_document" {
  statement {
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:ListRepositories",
      "codecommit:BatchGetRepositories",
      "codecommit:GitPull",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "ecs:Describe*",
      "ecs:List*",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:UpdateService",
      "ecs:UpdateClusterSettings",
      "ecs:DescribeClusters",
      "ecs:PutAttributes",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateService",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:UpdateContainerInstancesState",
      "ecs:*",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "Chungnam_codepipeline-policy"
  description = "Policy for CodePipeline"
  policy      = data.aws_iam_policy_document.codepipeline_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# CodeDeploy IAM 역할 설정
resource "aws_iam_role" "codedeploy_role" {
  name               = "Chungnam_wsc2024-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role_policy.json
}

data "aws_iam_policy_document" "codedeploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codedeploy_policy_document" {
  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:UpdateService",
      "ecs:DescribeClusters",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateService",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:ListContainerInstances",
      "ecs:ListServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteService",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTaskDefinitions",
      "ecs:UpdateServiceSetting",
      "ecs:*",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codedeploy_policy" {
  name        = "Chungnam_codedeploy-policy"
  description = "Policy for CodeDeploy"
  policy      = data.aws_iam_policy_document.codedeploy_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

# 역할-pipe
resource "aws_iam_role" "pipe_role" {
  name = "Chungnam_pipe-role"
  assume_role_policy = data.aws_iam_policy_document.pipe_role.json
}
# 정책 - pipe
data "aws_iam_policy_document" "pipe_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    
    principals {
      type = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
# policy-pipeline
resource "aws_iam_role_policy_attachment" "AWSCodePipeline_FullAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# policy-commit 
resource "aws_iam_role_policy_attachment" "AWSCodeCommitFullAccess" {
  role = aws_iam_role.pipe_role.name 
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSCodeCommitReadOnly" {
  role = aws_iam_role.pipe_role.name 
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}
# policy-build
resource "aws_iam_role_policy_attachment" "AWSCodeBuildAdminAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}
# policy - CodeBuildReadOnlyAcces
resource "aws_iam_role_policy_attachment" "AWSCodeBuildReadOnlyAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildReadOnlyAccess"
}
# policy-ecs-task
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy1" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# policy-ecs-ecs
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess1" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
# policy-ecs-deploy
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
### pipeline ###
resource "aws_codepipeline" "codepipeline" {
  name     = "Chungnam_wsc2024-pipeline"
  role_arn = aws_iam_role.pipe_role.arn
 
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type = "S3"
  }

  stage {
    name = "Source"
 
    action {
      name = "Source"
      category = "Source"
      owner = "AWS" 
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["source_output"]
      namespace        = "CodeCommit"
 
      configuration = {
        RepositoryName = aws_codecommit_repository.example.id
        BranchName = "master"
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
        ProjectName = aws_codebuild_project.example.id
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name       = "Approval"
      category   = "Approval"
      owner      = "AWS"
      provider   = "Manual"
      version    = "1"
      configuration = {
        CustomData         = "new CommitID : #{CodeCommit.CommitId}"
        ExternalEntityLink = "https://us-west-1.console.aws.amazon.com/codesuite/codecommit/repositories/wsc2024-cci/commit/#{CodeCommit.CommitId}?region=us-west-1"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.example.name
        ServiceName = aws_ecs_service.example.name
        FileName = "imagedefinitions.json"
      }
    }
  }
}

# CodeDeploy 앱 설정
resource "aws_codedeploy_app" "example" {
  name             = "wsc2024-cdy"
  compute_platform = "ECS"
}

