#!/usr/bin/env groovy
//  vim:ts=4:sts=4:sw=4:et:filetype=groovy:syntax=groovy
//
//  Author: Hari Sekhon
//  Date: 2017-06-28 12:39:02 +0200 (Wed, 28 Jun 2017)
//
//  https://github.com/harisekhon/bash-tools
//
//  License: see accompanying Hari Sekhon LICENSE file
//
//  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
//
//  https://www.linkedin.com/in/harisekhon
//

// ========================================================================== //
//                        J e n k i n s   P i p e l i n e
// ========================================================================== //


// https://jenkins.io/doc/book/pipeline/syntax/


pipeline {
    // run pipeline any agent
    agent any
    // can't do this when running jenkins in docker itself, gets '.../script.sh: docker: not found'
//    agent {
//      docker {
//          image 'ubuntu:18.04'
//          args '-v $HOME/.m2:/root/.m2 -v $HOME/.cache/pip:/root/.cache/pip -v $HOME/.cpanm:/root/.cpanm -v $HOME/.sbt:/root/.sbt -v $HOME/.ivy2:/root/.ivy2 -v $HOME/.gradle:/root/.gradle'
//      }
//  }

    // need to specify at least one env var if enabling
    //environment {
    //  DEBUG = '1'
    //}

    options {
        // put timestamps in console logs
        timestamps()

        // timeout entire pipeline after 4 hours
        timeout(time: 4, unit: 'HOURS')

        //retry entire pipeline 3 times
        //retry(3)
    }

    triggers {
        cron('H 10 * * 1-5')
        pollSCM('H/2 * * * *')
    }

    stages {
        stage ('Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '', url: 'https://github.com/harisekhon/devops-bash-tools']]])
            }
        }

        stage('Build') {
            steps {
                echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
                echo 'Building...'
                timeout(time: 10, unit: 'MINUTES') {
                    retry(3) {
//                        sh 'apt update -q'
//                        sh 'apt install -qy make'
//                        sh 'make init'
                        sh """
                            setup/ci_bootstrap.sh &&
                            make init
                        """
                    }
                }
                timeout(time: 180, unit: 'MINUTES') {
                    sh 'make ci'
                }
            }
        }

        stage('Test') {
            options {
                retry(2)
            }
            steps {
                echo 'Testing...'
                timeout(time: 120, unit: 'MINUTES') {
                    sh 'make test'
                }
            }
        }

//        stage('Human gate') {
//            steps {
//                input "Proceed to deployment?"
//            }
//        }
//
//        stage('Deployment') {
//            steps {
//                echo 'Deploying...'
//                echo 'Nothing to deploy'
//            }
//        }

    }
    post {
        always {
            echo 'Always'
            //deleteDir() // clean up workspace

            // collect JUnit reports for Jenkins UI
            //junit 'build/reports/**/*.xml'
            // collect artifacts to Jenkins for analysis
            //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
        }
        success {
            echo 'SUCCESS!'
        }
        failure {
            echo 'FAILURE!'
        }
        unstable {
            echo 'UNSTABLE!'
        }
        changed {
            echo 'Pipeline state change! (success vs failure)'
        }
    }
}
