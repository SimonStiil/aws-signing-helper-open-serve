resource "aws_rolesanywhere_trust_anchor" "self_managed_ca_trust_anchor" {
  name    = "SelfManagedCATrustAnchor"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = file("../rootCACert.pem")
    }
  }
}
resource "aws_iam_role" "self_managed_ca_role" {
  name               = "SelfManagedCARole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "rolesanywhere.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
          "sts:SetSourceIdentity"
        ]
        Condition = {
          "ArnEquals" = {
            "aws:SourceArn" = aws_rolesanywhere_trust_anchor.self_managed_ca_trust_anchor.arn
          }
        }
      }
    ]
  })
  max_session_duration = 3600

}
resource "aws_iam_role_policy_attachment" "route53_attachment" {
  role       = aws_iam_role.self_managed_ca_role.name
  policy_arn = aws_iam_policy.route53_policy.arn
}
resource "aws_iam_policy" "route53_policy" {
  name        = "Route53Policy"
  description = "Policy to allow Route 53 actions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

resource "aws_rolesanywhere_profile" "self_managed_ca_profile" {
  name             = "SelfManagedCAProfile"
  duration_seconds = 900
  enabled          = true
  role_arns        = [aws_iam_role.self_managed_ca_role.arn]
}
