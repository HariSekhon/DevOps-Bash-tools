//
//  Author: Hari Sekhon
//  Date: 2022-01-25 19:26:05 +0000 (Tue, 25 Jan 2022)
//
//  vim:ts=4:sts=4:sw=4:noet
//
//  https://github.com/HariSekhon/DevOps-Bash-tools
//
//  License: see accompanying Hari Sekhon LICENSE file
//
//  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
//
//  https://www.linkedin.com/in/HariSekhon
//

// Lists all disabled Jenkins jobs

// Paste this into $JENKINS_URL/script
//
// Jenkins -> Manage Jenkins -> Script Console

jenkins.model.Jenkins.instance.items.findAll { it.isDisabled() }.each { println it.name }.size
