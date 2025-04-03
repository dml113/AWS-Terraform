[
  {
    "cpu": 256,
    "essential": true,
    "image": "nginx:latest",
    "memory": 256,
    "name": "nginx-container",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]