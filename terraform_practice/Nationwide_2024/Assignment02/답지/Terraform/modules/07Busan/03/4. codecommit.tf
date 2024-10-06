# CodeCommit 리포지토리 생성
resource "aws_codecommit_repository" "wsi_repo" {
  repository_name = "wsi-repo"
}