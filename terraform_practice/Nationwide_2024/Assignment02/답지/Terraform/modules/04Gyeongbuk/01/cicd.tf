resource "aws_codecommit_repository" "example" {
  repository_name = "wsi-commit"
}

# S3 버킷 설정
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "wsi-codepipeline-artifacts"
}

### 역할- Codebuild ###
resource "aws_iam_role" "codebuild_role" {
  name = "build-role"
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
  name          = "wsi-build"
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
  name        = "codebuild-policy"
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
  name               = "wsc2024-codepipeline-role"
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
  name        = "codepipeline-policy"
  description = "Policy for CodePipeline"
  policy      = data.aws_iam_policy_document.codepipeline_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# CodeDeploy IAM 역할 설정
resource "aws_iam_role" "codedeploy_role" {
  name               = "wsc2024-codedeploy-role"
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
      "codedeploy:GetDeploymentConfig",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:SetRulePriorities",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codedeploy_policy" {
  name        = "codedeploy-policy"
  description = "Policy for CodeDeploy"
  policy      = data.aws_iam_policy_document.codedeploy_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

# ELB Full Access for CodeDeploy Role
resource "aws_iam_role_policy_attachment" "codedeploy_elb_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# 역할-pipe
resource "aws_iam_role" "pipe_role" {
  name = "pipe-role"
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
# Update CodeDeploy App
resource "aws_codedeploy_app" "example" {
  name             = "wsi-codedeploy"
  compute_platform = "ECS"
}

# Add CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "ecs" {
  app_name              = aws_codedeploy_app.example.name
  deployment_group_name = "wsi-codedeploy-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                              = "TERMINATE"
      termination_wait_time_in_minutes    = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.app.name
      }
      target_group {
        name = aws_lb_target_group.green.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }
    }
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "wsi-pipeline"
  role_arn = aws_iam_role.pipe_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
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
        RepositoryName = aws_codecommit_repository.example.id
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
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.example.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.example.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.ecs.deployment_group_name
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yml"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE_NAME"
      }
    }
  }
}