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

// XXX: WARNING: you can run into all sorts of state problems with the Milestone plugin preventing your builds from running due to a remnant reference to a higher build number - this also happens on job restores which start from build #1 again
//
//			[2022-08-02T16:14:46.501Z] Trying to pass milestone 0
//			[2022-08-02T16:14:46.501Z] Canceled since build #3814 already got here
//
//			https://issues.jenkins.io/browse/JENKINS-38641
//
//			one fix is of course to do
//
//				job.nextBuildNumber = 3815
//
//			but you'd either need to do that for only one specific job (see adjacent script jenkins_clear_build_history.groovy) or you'd need to set the build number to something higher than any of the jobs got to

jenkins.model.Jenkins.instance.items.findAll().each {
	println
	def jobName = it.name
	def job = Jenkins.instance.getItem(jobName)
	job.getBuilds().each { it.delete() }
	job.nextBuildNumber = 1
	job.save()
}
