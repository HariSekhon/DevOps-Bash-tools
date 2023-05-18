//
//  Author: Hari Sekhon
//  Date: 2021-04-08 19:16:17 +0100 (Thu, 08 Apr 2021)
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

// Paste this into $JENKINS_URL/script
//
// Jenkins -> Manage Jenkins -> Script Console

//jenkins.model.Jenkins.instance.items.findAll().each { println it.name } // return the whole array, don't want that, just return num
jenkins.model.Jenkins.instance.items.findAll().each { println it.displayName }.size
