resource "aws_instance" "bastion-instance" {
    subnet_id = aws_subnet.private_subnet_a.id
    vpc_security_group_ids = [aws_security_group.J-company-bastion.id]
    ami = "ami-0edc5427d49d09d2a"
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    instance_type = "t3.small"

    tags = {
        Name = "J-company-bastion"
    }
}