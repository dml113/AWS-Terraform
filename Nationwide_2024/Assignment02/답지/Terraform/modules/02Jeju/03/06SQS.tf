resource "aws_sqs_queue" "J_company_queue" {
  name                      = "J-company-sqs"  
}

resource "aws_sqs_queue_policy" "J_company_queue_policy" {
  queue_url = aws_sqs_queue.J_company_queue.id  

  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "example-ID",
    "Statement": [
      {
        "Sid": "example-statement-ID",
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": [
          "SQS:SendMessage"
        ],
        "Resource": "arn:aws:sqs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:J-company-sqs",
        "Condition": {
            "ArnLike": {
            "aws:SourceArn": "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup"
          },
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}
