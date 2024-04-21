################################################################################
# Role
################################################################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "ECSTaskExecutionRole"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs-tasks.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role" "ecs_task" {
  name = "ECSTaskRole"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs-tasks.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.ecs_service_role.arn
  ]
}

resource "aws_iam_role" "eventbridge_scheduler" {
  name = "EventbridgeSchedulerRole"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "events.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.eventbridge_scheduler_role.arn
  ]
}

resource "aws_iam_role" "codebuild" {
  name = "CodeBuildRole"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.codebuild_role.arn
  ]
}

resource "aws_iam_role" "api_gateway" {
  name = "RestAPIGateway"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "apigateway.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
}

################################################################################
# Policy
################################################################################
resource "aws_iam_policy" "ecs_service_role" {
  name = "ECSServiceRolePolicy"

  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Sid"    = "ECSTaskManagement",
          "Effect" = "Allow",
          "Action" = [
            "ec2:AttachNetworkInterface",
            "ec2:CreateNetworkInterface",
            "ec2:CreateNetworkInterfacePermission",
            "ec2:DeleteNetworkInterface",
            "ec2:DeleteNetworkInterfacePermission",
            "ec2:Describe*",
            "ec2:DetachNetworkInterface",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:Describe*",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:RegisterTargets",
            "route53:ChangeResourceRecordSets",
            "route53:CreateHealthCheck",
            "route53:DeleteHealthCheck",
            "route53:Get*",
            "route53:List*",
            "route53:UpdateHealthCheck",
            "servicediscovery:DeregisterInstance",
            "servicediscovery:Get*",
            "servicediscovery:List*",
            "servicediscovery:RegisterInstance",
            "servicediscovery:UpdateInstanceCustomHealthStatus"
          ],
          "Resource" = "*"
        },
        {
          "Sid"    = "AutoScaling",
          "Effect" = "Allow",
          "Action" = [
            "autoscaling:Describe*"
          ],
          "Resource" = "*"
        },
        {
          "Sid"    = "AutoScalingManagement",
          "Effect" = "Allow",
          "Action" = [
            "autoscaling:DeletePolicy",
            "autoscaling:PutScalingPolicy",
            "autoscaling:SetInstanceProtection",
            "autoscaling:UpdateAutoScalingGroup",
            "autoscaling:PutLifecycleHook",
            "autoscaling:DeleteLifecycleHook",
            "autoscaling:CompleteLifecycleAction",
            "autoscaling:RecordLifecycleActionHeartbeat"
          ],
          "Resource" = "*",
          "Condition" = {
            "Null" = {
              "autoscaling:ResourceTag/AmazonECSManaged" = "false"
            }
          }
        },
        {
          "Sid"    = "AutoScalingPlanManagement",
          "Effect" = "Allow",
          "Action" = [
            "autoscaling-plans:CreateScalingPlan",
            "autoscaling-plans:DeleteScalingPlan",
            "autoscaling-plans:DescribeScalingPlans",
            "autoscaling-plans:DescribeScalingPlanResources"
          ],
          "Resource" = "*"
        },
        {
          "Sid"    = "EventBridge",
          "Effect" = "Allow",
          "Action" = [
            "events:DescribeRule",
            "events:ListTargetsByRule"
          ],
          "Resource" = "arn:aws:events:*:*:rule/ecs-managed-*"
        },
        {
          "Sid"    = "EventBridgeRuleManagement",
          "Effect" = "Allow",
          "Action" = [
            "events:PutRule",
            "events:PutTargets"
          ],
          "Resource" = "*",
          "Condition" = {
            "StringEquals" = {
              "events:ManagedBy" = "ecs.amazonaws.com"
            }
          }
        },
        {
          "Sid"    = "CWAlarmManagement",
          "Effect" = "Allow",
          "Action" = [
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:PutMetricAlarm"
          ],
          "Resource" = "arn:aws:cloudwatch:*:*:alarm:*"
        },
        {
          "Sid"    = "ECSTagging",
          "Effect" = "Allow",
          "Action" = [
            "ec2:CreateTags"
          ],
          "Resource" = "arn:aws:ec2:*:*:network-interface/*"
        },
        {
          "Sid"    = "CWLogGroupManagement",
          "Effect" = "Allow",
          "Action" = [
            "logs:CreateLogGroup",
            "logs:DescribeLogGroups",
            "logs:PutRetentionPolicy"
          ],
          "Resource" = "arn:aws:logs:*:*:log-group:/aws/ecs/*"
        },
        {
          "Sid"    = "CWLogStreamManagement",
          "Effect" = "Allow",
          "Action" = [
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" = "arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"
        },
        {
          "Sid"    = "ExecuteCommandSessionManagement",
          "Effect" = "Allow",
          "Action" = [
            "ssm:DescribeSessions"
          ],
          "Resource" = "*"
        },
        {
          "Sid"    = "ExecuteCommand",
          "Effect" = "Allow",
          "Action" = [
            "ssm:StartSession"
          ],
          "Resource" = [
            "arn:aws:ecs:*:*:task/*",
            "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand"
          ]
        },
        {
          "Sid"    = "CloudMapResourceCreation",
          "Effect" = "Allow",
          "Action" = [
            "servicediscovery:CreateHttpNamespace",
            "servicediscovery:CreateService"
          ],
          "Resource" = "*",
          "Condition" = {
            "ForAllValues:StringEquals" = {
              "aws:TagKeys" = [
                "AmazonECSManaged"
              ]
            }
          }
        },
        {
          "Sid"      = "CloudMapResourceTagging",
          "Effect"   = "Allow",
          "Action"   = "servicediscovery:TagResource",
          "Resource" = "*",
          "Condition" = {
            "StringLike" = {
              "aws:RequestTag/AmazonECSManaged" = "*"
            }
          }
        },
        {
          "Sid"    = "CloudMapResourceDeletion",
          "Effect" = "Allow",
          "Action" = [
            "servicediscovery:DeleteService"
          ],
          "Resource" = "*",
          "Condition" = {
            "Null" = {
              "aws:ResourceTag/AmazonECSManaged" = "false"
            }
          }
        },
        {
          "Sid"    = "CloudMapResourceDiscovery",
          "Effect" = "Allow",
          "Action" = [
            "servicediscovery:DiscoverInstances",
            "servicediscovery:DiscoverInstancesRevision"
          ],
          "Resource" = "*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "eventbridge_scheduler_role" {
  name = "EventbridgeSchedulerRole"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          Effect   = "Allow"
          Action   = "iam:PassRole"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "ecs:RunTask"
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "codebuild_role" {
  name = "CodebuildRole"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "logs:*"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

data "aws_iam_policy_document" "api_gateway" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["0.0.0.0/0"]
    }
  }
}

resource "aws_iam_role_policy" "api_gateway_log_policy" {
  name = "APIGatewayLogPolicy"
  role = aws_iam_role.api_gateway.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = aws_cloudwatch_log_group.api_gateway.arn
        }
      ]
    }
  )
}
