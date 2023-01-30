/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.vault.name
}

output "aws_vault_iam_role_arn" {
  value = aws_iam_role.instance_role[0].arn
}