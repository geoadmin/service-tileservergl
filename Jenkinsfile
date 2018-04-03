#!/usr/bin/env groovy

final IMAGE_BASE_NAME = 'swisstopo/nginx-tileserver-gl'
final IMAGE_BASE_NAME_TILESERVERGL = 'swisstopo/tileserver-gl'

node(label: "jenkins-slave") {
  final deployGitBranch = env.BRANCH_NAME
  def IMAGE_TAG = "staging"

  final scmVars = checkout scm
  if (deployGitBranch != 'master') {
    IMAGE_TAG = scmVars.GIT_COMMIT
  }
  def COMPOSE_PROJECT_NAME = IMAGE_TAG

  try {
    withEnv(["IMAGE_TAG=${IMAGE_TAG}", "COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}"]) {
      stage("Build") {
        sh 'echo Starting to build images...'
        sh 'docker --version'
        sh 'docker-compose --version'
        sh 'make cleanall'
        sh 'make user'
        sh 'echo "export IMAGE_TAG=${IMAGE_TAG}" >> rc_user'
        sh 'make dockerbuild CI=true'
      }
      stage("Run") {
        sh 'echo Starting the containers...'
        sh 'docker-compose -p "${COMPOSE_PROJECT_NAME}" up -d'
        sh 'docker ps -a'
        sh 'sleep 5'
      }
      stage("Sanity") {
        sh 'NGINX_OK=$(docker ps -aq --filter status="running" --filter name="${COMPOSE_PROJECT_NAME}_nginx") && if [ -z "$NGINX_OK" ]; then exit 1; fi'
        sh 'TILESERVER_OK=$(docker ps -aq --filter status="running" --filter name="${COMPOSE_PROJECT_NAME}_tileserver") && if [ -z "$TILESERVER_OK" ]; then exit 1; fi'
      }
      if (deployGitBranch == 'master') {
        stage("Publish") {
          sh 'echo Publishing images to dev'
          withCredentials(
            [[$class: 'UsernamePasswordMultiBinding',
              credentialsId: 'iwibot-admin-user-dockerhub',
              usernameVariable: 'USERNAME',
              passwordVariable: 'PASSWORD']]
          ){
            sh 'docker login -u "$USERNAME" -p "$PASSWORD"'
            docker.image("${IMAGE_BASE_NAME}:${IMAGE_TAG}").push()
          }
        }
      }
      if (deployGitBranch == 'master') {
        stage("Deploy") {
          sh 'make rancherdeploydev'
        }
      }
    }
  } catch (e) {
    throw e
  }
  finally {
    withEnv(["IMAGE_TAG=${IMAGE_TAG}", "COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}"]) {
      stage("Clean") {
        sh 'docker-compose down -v || echo Skipping'
        sh "docker rmi ${IMAGE_BASE_NAME}:${IMAGE_TAG} || echo Skipping"
        sh "docker rmi ${IMAGE_BASE_NAME_TILESERVERGL}:staging || echo Skipping"
        sh 'git clean -dx --force'
        sh 'docker ps'
        sh 'docker ps --all --filter status=exited'
        sh 'echo All dockers have been purged'
      }
    }
  }
}
