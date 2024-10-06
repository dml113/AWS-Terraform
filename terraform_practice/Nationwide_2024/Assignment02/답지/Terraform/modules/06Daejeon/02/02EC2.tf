resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pair" {
  key_name   = "wsi-app-pair.pem"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "file" {
  filename        = "wsi-app-pair.pem"
  content         = tls_private_key.key.private_key_pem
}

resource "aws_security_group" "sg" {
  name        = "wsi-app-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "wsi-app-sg"
  }
}

resource "aws_security_group_rule" "ingress22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "ingress80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress22" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

data "aws_iam_policy_document" "document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "role" {
name               = "wsi-app-role"
  assume_role_policy = data.aws_iam_policy_document.document.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "wsi-app-role"
  role = aws_iam_role.role.name
}

resource "aws_instance" "instance" {
  security_groups             = [aws_security_group.sg.id]
  ami                         = "ami-0b8414ae0d8d8b4cc"
  subnet_id                   = aws_subnet.subnet_a.id
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.pair.key_name
  tags = {
    Name = "wsi-app-ec2"
  }
}