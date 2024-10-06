resource "aws_secretsmanager_secret" "customer" {
  name = "customer"
  description = "An example secret created with Terraform"
}

resource "aws_secretsmanager_secret_version" "customer_version" {
  secret_id     = aws_secretsmanager_secret.customer.id
  secret_string = jsonencode({
    MYSQL_USER     = "admin"
    MYSQL_PASSWORD = "Skill53##"
    MYSQL_HOST     = "${aws_rds_cluster.wsi_aurora_mysql_cluster.endpoint}"
    MYSQL_PORT     = "3307"
    MYSQL_DBNAME   = "wsidata"
  })
}

resource "aws_secretsmanager_secret" "product" {
  name = "product"
  description = "An example secret created with Terraform"
}

resource "aws_secretsmanager_secret_version" "product_version" {
  secret_id     = aws_secretsmanager_secret.product.id
  secret_string = jsonencode({
    MYSQL_USER     = "admin"
    MYSQL_PASSWORD = "Skill53##"
    MYSQL_HOST     = "${aws_rds_cluster.wsi_aurora_mysql_cluster.endpoint}"
    MYSQL_PORT     = "3307"
    MYSQL_DBNAME   = "wsidata"
  })
}

resource "aws_secretsmanager_secret" "order" {
  name = "order"
  description = "An example secret created with Terraform"
}

resource "aws_secretsmanager_secret_version" "order_version" {
  secret_id     = aws_secretsmanager_secret.order.id
  secret_string = jsonencode({
    AWS_REGION     = "${var.region}"
  })
}