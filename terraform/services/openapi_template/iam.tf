################################################################################
# Role
################################################################################
# ECS用タスク実行ロール
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.service_group}-${local.name}-ECSTaskExec-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs-tasks.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

# ECS用タスクロール
resource "aws_iam_role" "ecs_task" {
  name = "${local.service_group}-${local.name}-ECSTask-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs-tasks.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.ecs_service_role.arn
  ]
}

# Codepipeline用ロール
resource "aws_iam_role" "codepipeline_role" {
  name = "${local.service_group}-${local.name}-CodePipeline-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codepipeline.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
    "arn:aws:iam::aws:policy/AWSCodeDeployDeployerAccess",
    "arn:aws:iam::aws:policy/service-role/AWSCodeStarServiceRole"
  ]
}

# Codebuild用ロール
resource "aws_iam_role" "codebuild" {
  name = "${local.service_group}-${local.name}-CodeBuild-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

# CodeDeploy用ロール
resource "aws_iam_role" "codedeploy" {
  name = "${local.service_group}-${local.name}-CodeDeploy-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codedeploy.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

# AutoScaling用ロール
resource "aws_iam_role" "autoscaling" {
  name = "${local.service_group}-${local.name}-AutoScaling-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "autoscaling.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AutoScalingFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  ]
}

################################################################################
# Policy
################################################################################
# ECS用サービス実行ポリシー
resource "aws_iam_policy" "ecs_service_role" {
  name = "${local.service_group}-${local.name}-ECS-${var.environment}"

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

# CodePipeline用ポリシー
resource "aws_iam_policy" "codepipeline_role" {
  name = "${local.service_group}-${local.name}-CodePipeline-${local.name}"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "codestar-connections:*"
          ],
          "Resource" : "*"
        },
      ]
    }
  )
}
