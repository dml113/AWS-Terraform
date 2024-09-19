# # Config Start (서울 2-2,대전 2-2)
# module "config_start" {
#     source = "./modules/config"
# }

# # Default VPC (충남 2-1,부산 2-3)
# module "default_vpc" {
#     source = "./modules/defaultvpc"
# }

# #################################################################

# # 충남 2-1 (README.md or Notion 참고 | [Cloud governance] )
# module "Chungnam_1" {
#     source = "./modules/01Chungnam/01"
#     region = "ap-northeast-2"
#     vpc_id = module.default_vpc.default_vpc_id
# }

# # 충남 2-2 (README.md or Notion 참고 | [CI/CD])
# module "Chungnam_2" {
#     source = "./modules/01Chungnam/02"
#     region = "us-west-1"
# }

# # 충남 2-3 (README.md or Notion 참고 | [Secure networking])
# module "Chungnam_3" {
#     source = "./modules/01Chungnam/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 제주 2-1 (README.md or Notion 참고 | [Serverless])
# module "Jeju_1" {
#     source = "./modules/02Jeju/01"
#     region = "ap-northeast-2"
# }

# # 제주 2-2 (README.md or Notion 참고 | [Cloud governance])
# module "Jeju_2" {
#     source = "./modules/02Jeju/02"
#     region = "ap-northeast-2"
# }

# # 제주 2-3 (README.md or Notion 참고 | [Secure networking])
# module "Jeju_3" {
#     source = "./modules/02Jeju/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 서울 2-1 (README.md or Notion 참고 | [CDN])
# module "Seoul_1" {
#     source = "./modules/03Seoul/01"
#     region = "us-east-1"
# }

# # 서울 2-2 (README.md or Notion 참고 | [Cloud governance])
# module "Seoul_2" {
#     source = "./modules/03Seoul/02"
#     region = "ap-northeast-2"
# }

# # 서울 2-3 (README.md or Notion 참고 | [IAM security])
# module "Seoul_3" {
#     source = "./modules/03Seoul/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 경북 2-1 (README.md or Notion 참고 | [CI/CD])
# module "Gyeongbuk_1" {
#     source = "./modules/04Gyeongbuk/01"
#     region = "ap-northeast-2"
# }

# # 경북 2-2 (README.md or Notion 참고 | [WAF])
# module "Gyeongbuk_2" {
#     source = "./modules/04Gyeongbuk/02"
#     region = "ap-northeast-2"
# }

# # 경북 2-3 (README.md or Notion 참고 | [Elastic stack])
# module "Gyeongbuk_3" {
#     source = "./modules/04Gyeongbuk/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 광주 2-1 (README.md or Notion 참고 | [Network architecture])
# module "Gwangju_1" {
#     source = "./modules/05Gwangju/01"
#     region = "ap-northeast-2"
# }

# # 광주 2-2 (README.md or Notion 참고 | [CI/CD])
# module "Gwangju_2" {
#     source = "./modules/05Gwangju/02"
#     region = "ap-northeast-2"
# }

# # 광주 2-3 (README.md or Notion 참고 | [EKS Observability])
# module "Gwangju_3" {
#     source = "./modules/05Gwangju/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 대전 2-1 (README.md or Notion 참고 | [Serverless])
# module "Daejeon_1" {
#     source = "./modules/06Daejeon/01"
#     region = "ap-northeast-2"
# }

# # 대전 2-2 (README.md or Notion 참고 | [Cloud governance])
# module "Daejeon_2" {
#     source = "./modules/06Daejeon/02"
#     region = "ap-northeast-2"
# }

# # 대전 2-3 (README.md or Notion 참고 | [EKS observability])
# module "Daejeon_3" {
#     source = "./modules/06Daejeon/03"
#     region = "ap-northeast-2"
# }

# #################################################################

# # 부산 2-1 (README.md or Notion 참고 | [IAM security])
# module "Busan_1" {
#     source = "./modules/07Busan/01"
#     region = "ap-northeast-2"
# }

# # 부산 2-2 (README.md or Notion 참고 | [Cloud governance])
# module "Busan_2" {
#     source = "./modules/07Busan/02"
#     region = "ap-northeast-2"
# }

# # 부산 2-3 (README.md or Notion 참고 | [CI/CD])
# module "Busan_3" {
#     source = "./modules/07Busan/03"
#     region = "ap-northeast-2"
#     vpc_id = module.default_vpc.default_vpc_id
#     vpc_subnet_a = module.default_vpc.default_vpc_subnet_a_id
# }