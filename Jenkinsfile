pipeline {
  agent any
  stages {
    stage('check') {
      steps {
        sh 'dd'
      }
    }

    stage('build') {
      steps {
        build 'jobname'
      }
    }

    stage('test') {
      steps {
        build 'job 2'
        bzt(params: '123', generatePerformanceTrend: true)
      }
    }

  }
}