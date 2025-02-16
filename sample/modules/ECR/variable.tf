variable "repository_name" {
  description = "ECR 리포지토리 이름"
  type        = string
}

variable "image_tag_mutability" {
  description = "이미지 태그 변경 가능 여부 (MUTABLE/IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "encryption_type" {
  description = "암호화 타입 (KMS/AES256)"
  type        = string
  default     = "AES256"
}

variable "scan_on_push" {
  description = "푸시 시 이미지 스캔 여부"
  type        = bool
  default     = true
}