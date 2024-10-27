{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images older than ${period_days} days to save storage space.",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": ${period_days}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
