#!/bin/sh
#  shellcheck disable=SC2128,SC2230,SC1090
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/HariSekhon/DevOps-Python-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x

# Azure DevOps env var, chain to standard debug across all programs, scripts and repos
if [ "${SYSTEM_DEBUG:-}" = "true" ]; then
    export DEBUG=1
fi

# https://jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables
is_jenkins(){
    # also BUILD_ID, BUILD_NUMBER, BUILD_URL but less specific, caught in is_CI generic
    # JENKINS_URL is set in client side environment for various CLIs and scripts, can't rely on just that
    if [ -n "${JENKINS_URL:-}" ] &&
       [ -n "${EXECUTOR_NUMBER:-}" ] &&
       [ -n "${JOB_NAME:-}" ] &&
       [ -n "${BUILD_ID:-}" ] &&
       [ -n "${BUILD_URL:-}" ]; then
        return 0
    fi
    return 1
}

# https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
is_travis(){
    # also TRAVIS_JOB_ID
    if [ -n "${TRAVIS:-}" ]; then
        return 0
    fi
    return 1
}

# https://www.appveyor.com/docs/environment-variables/
is_appveyor(){
    # also CI but not really specific, caught in is_CI generic
    if [ -n "${APPVEYOR:-}" ]; then
        return 0
    fi
    return 1
}

# https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/
is_bitbucket_ci(){
    # also CI but not really specific, caught in is_CI generic
    if [ -n "${BITBUCKET_BUILD_NUMBER:-}" ]; then
        return 0
    fi
    return 1
}

# https://buddy.works/docs/pipelines/environment-variables#default-environment-variables
is_buddy_works_ci(){
    # also BUDDY but a bit too generic for my liking
    if [ -n "${BUDDY_PIPELINE_ID:-}" ]; then
        return 0
    fi
    return 1
}

# https://buildkite.com/docs/pipelines/environment-variables
is_buildkite(){
    # also CI but not really specific, caught in is_CI generic
    if [ -n "${BUILDKITE:-}" ]; then
        return 0
    fi
    return 1
}

# Concourse team refuse to add this variable like all the other normal CI systems
# so it relies on you having added it yourself (see .concourse.yml in any of my repos for example)
is_concourse(){
    if [ -n "${CONCOURSE:-}" ]; then
        return 0
    fi
    return 1
}

# https://circleci.com/docs/2.0/env-vars/#built-in-environment-variables
is_circle_ci(){
    # also CI but not really specific, caught in is_CI generic
    # also CIRCLE_JOB
    if [ -n "${CIRCLECI:-}" ]; then
        return 0
    fi
    return 1
}

# https://cirrus-ci.org/guide/writing-tasks/
is_cirrus_ci(){
    # also CI but not really specific, caught in is_CI generic
    if [ -n "${CIRRUS_CI:-}" ]; then
        return 0
    fi
    return 1
}

# https://codefresh.io/docs/docs/codefresh-yaml/variables/
is_codefresh(){
    # also CI but not really specific, caught in is_CI generic
    if [ -n "${CF_BUILD_ID:-}" ]; then
        return 0
    fi
    return 1
}

# https://documentation.codeship.com/basic/builds-and-configuration/set-environment-variables/#default-environment-variables
is_codeship(){
    # also CI and other generic CI_ env vars caught in is_CI generic
    # formerly codeship
    if [ "${CI_NAME:-}" = "CodeShip" ]; then
        return 0
    fi
    return 1
}

is_drone_io(){
    # also CI and other generic CI_ env vars caught in is_CI generic
    if [ -n "${DRONE:-}" ]; then
        return 0
    fi
    return 1
}

# https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
is_github_workflow(){
    if [ -n "${GITHUB_ACTIONS:-}" ] ||
       [ -n "${GITHUB_WORKFLOW:-}" ]; then
        return 0
    fi
    return 1
}

is_github_action(){
    is_github_workflow
}

# https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
is_gitlab_ci(){
    # also CI and other generic CI_ env vars caught in is_CI generic
    if [ -n "${GITLAB_CI:-}" ]; then
        return 0
    fi
    return 1
}

# https://docs.gocd.org/current/faq/dev_use_current_revision_in_build.html
is_gocd(){
    if [ -n "${GO_PIPELINE_NAME:-}" ]; then
        return 0
    fi
    return 1
}

# https://scrutinizer-ci.com/docs/build/environment-variables
is_scrutinizer_ci(){
    # also CI but specific to Scrutinizer, caught in is_CI generic
    if [ -n "${SCRUTINIZER:-}" ]; then
        return 0
    fi
    return 1
}

# incomplete documentation - CI code framework in this repo reveals a lot more env vars
# https://help.semmle.com/wiki/display/SD/Environment+variables
is_semmle(){
    if [ -n "${SEMMLE_PLATFORM:-}" ]; then
        return 0
    fi
    return 1
}

# https://docs.semaphoreci.com/ci-cd-environment/environment-variables/
is_semaphore_ci(){
    # too generic, might clash with something else in future
    #if [ -n "${SEMAPHORE:-}" ]; then
    if [ -n "${SEMAPHORE_PIPELINE_ID:-}" ]; then
        return 0
    fi
    return 1
}

# http://docs.shippable.com/ci/env-vars/#stdEnv
is_shippable_ci(){
    # also CI and CONTINUOUS_INTEGRATION but not really specific to Shippable, caught in is_CI generic
    # also $SHIPPABLE_JOB_ID / $SHIPPABLE_JOB_NUMBER
    if [ -n "${SHIPPABLE:-}" ]; then
        return 0
    fi
    return 1
}

# https://www.jetbrains.com/help/teamcity/predefined-build-parameters.html
is_teamcity_ci(){
    # also BUILD_NUMBER, but less specific, caught in is_CI generic
    if [ -n "${TEAMCITY_VERSION:-}" ]; then
        return 0
    fi
    return 1
}
is_teamcity(){ is_teamcity_ci; }

# same as Azure DevOps
# https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#build-variables
is_tfs_ci(){
    if [ -n "${TF_BUILD:-}" ]; then
        return 0
    fi
    return 1
}

# https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#build-variables
#
# docs aren't great, testing shows these env vars of interest:
#
# AGENT_NAME=Azure Pipelines 2
# POWERSHELL_DISTRIBUTION_CHANNEL=Azure-DevOps-ubuntu18
# SYSTEM_TASKDEFINITIONSURI=https://dev.azure.com/harisekhon/
# SYSTEM_TEAMFOUNDATIONCOLLECTIONURI=https://dev.azure.com/harisekhon/
# SYSTEM_TEAMFOUNDATIONSERVERURI=https://dev.azure.com/harisekhon/
# TF_BUILD=True
#
is_azure_devops(){
    if is_tfs_ci; then
        return 0
    fi
    return 1
}

is_CI(){
    if [ -n "${CI:-}" ] ||
       [ -n "${CI_NAME:-}" ] ||
       [ -n "${CONTINUOUS_INTEGRATION:-}" ] ||
       [ -n "${BUILD_ID:-}" ] ||
       [ -n "${BUILD_NUMBER:-}" ] ||
       [ -n "${BUILD_URL:-}" ] ||
       is_jenkins ||
       is_teamcity ||
       is_travis ||
       is_circle_ci ||
       is_github_workflow ||
       is_gitlab_ci ||
       is_azure_devops ||
       is_appveyor ||
       is_bitbucket_ci ||
       is_buildkite ||
       is_buddy_works_ci ||
       is_codeship ||
       is_codefresh ||
       is_concourse ||
       is_cirrus_ci ||
       is_drone_io ||
       is_gocd ||
       is_scrutinizer_ci ||
       is_semmle ||
       is_semaphore_ci ||
       is_shippable_ci ||
       is_tfs_ci; then
        return 0
    fi
    return 1
}

CI_name(){
    if [ -n "${CI_NAME:-}" ]; then
        echo "$CI_NAME"
    elif is_jenkins; then
        echo "Jenkins"
    elif is_teamcity; then
        echo "TeamCity"
    elif is_travis; then
        echo "Travis CI"
    elif is_circle_ci; then
        echo "Circle CI"
    elif is_github_workflow; then
        echo "GitHub Actions"
    elif is_gitlab_ci; then
        echo "Gitlab CI"
    elif is_azure_devops; then
        echo "Azure DevOps"
    elif is_appveyor; then
        echo "AppVeyor"
    elif is_bitbucket_ci; then
        echo "Bitbucket Pipelines"
    elif is_buildkite; then
        echo "BuildKite"
    elif is_buddy_works_ci; then
        echo "Buddy CI"
    elif is_codeship; then
        echo "CodeShip"
    elif is_codefresh; then
        echo "Codefresh"
    elif is_concourse; then
        echo "Concourse"
    elif is_cirrus_ci; then
        echo "Cirrus CI"
    elif is_drone_io; then
        echo "Drone CI"
    elif is_gocd; then
        echo "GoCD"
    elif is_scrutinizer_ci; then
        echo "Scrutinizer"
    elif is_semmle; then
        echo "Semmle"
    elif is_semaphore_ci; then
        echo "Semaphore CI"
    elif is_shippable_ci; then
        echo "Shippable"
    elif is_tfs_ci; then
        echo "TFS CI"
    elif is_CI; then
        echo "CI"
    else
        echo "Not a recognized CI system"
        return 1
    fi
}

if is_travis; then
    #export DOCKER_HOST="${DOCKER_HOST:-localhost}"
    export HOST="${HOST:-localhost}"
fi

if is_CI; then
    # used by Artifactory JFrog CLI to disable interactive prompts and progress bar - https://www.jfrog.com/confluence/display/CLI/JFrog+CLI#JFrogCLI-EnvironmentVariables
    export CI=true
fi
