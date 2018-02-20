#!/usr/bin/env groovy

final IMAGE_BASE_NAME = 'swisstopo/service-tileservergl'
final IMAGE_TAG = 'staging'

node(label: "jenkins-slave") {
  final deployGitBranch = env.BRANCH_NAME
  try {
    stage("Checkout") {
      sh 'echo Checking out code from github'
      checkout scm
    }
    stage("Build") {
      sh '''
        echo Starting the build...
      '''
    }
    stage("Run") {
      sh '''
        echo Starting the containers...
      '''
    }
    stage("Sanity") {
      sh '''
        echo Checking sanity of the containers...
      '''
    }
    stage("Test") {
      sh '''
        echo Starting the tests...
      '''
    }
    stage("Publish") {
      if (deployGitBranch == 'master') {
        sh 'echo Publishing images to dev'
      } else {
        sh 'echo Skipping publishing to dev'
      }
    }
    stage("Deploy") {
      if (deployGitBranch == 'master') {
        sh 'echo Deploying images to dev'
      } else {
        sh 'echo Skipping deploy to dev'
      }
    }
  } catch (e) {
    throw e
  }
  finally {
    stage("Clean") {
      sh 'echo All dockers have been purged'
    }
  }
}
