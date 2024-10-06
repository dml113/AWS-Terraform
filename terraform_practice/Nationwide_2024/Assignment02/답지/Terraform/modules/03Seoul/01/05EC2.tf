resource "aws_iam_role" "example_role" {
    name = "wsi-role-bastion"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
    role       = aws_iam_role.example_role.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "seoul-ec2_instance_profile"
    role = aws_iam_role.example_role.name
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    key_name   = "bastion-key"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "Seoul_bastion.pem"
    content  = tls_private_key.key.private_key_pem
}

data "aws_ami" "amazon_linux" {
  most_recent = true 
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

resource "aws_instance" "wsi-bastion-instance" {
    subnet_id = aws_subnet.public-subnet-a.id
    vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 
    instance_type = "t3.small"
    key_name = aws_key_pair.keypair.key_name       
    depends_on = [ 
        aws_s3_bucket_object.upload_files
    ]
    tags = {
        Name = "wsi-bastion"
    }
}
