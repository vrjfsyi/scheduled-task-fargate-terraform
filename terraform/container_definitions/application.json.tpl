[
  {
    "name": "${container_name}",
    "image": "${image_registry}/${image_repository}:${image_tag}",
    "environment": [
      {
        "name": "ENVIRONMENT",
        "value": "${environment}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${awslogs_group}",
        "awslogs-region": "${awslogs_region}",
        "awslogs-stream-prefix": "${awslogs_stream_prefix}"
      }
    }
  }
]
