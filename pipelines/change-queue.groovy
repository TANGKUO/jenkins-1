// change-queue.groovy - Jenkins Pipeline script for managing change queues
//
def main() {
    stage('loading queue state') {
        load_queue_state()
    }
    stage('running queue logic') {
        run_queue_action_py()
        currentBuild.displayName = get_build_display_name()
    }
    stage('saving artifacts') {
        archive 'exported-artifacts/**'
    }
    if(!fileExists('build_args.json')) {
        return
    }
    stage('triggering test job') {
        build_args = readJSON(file: 'build_args.json')
        build_args['wait'] = false
        build build_args
    }
}

def load_queue_state() {
    dir('exported-artifacts') { deleteDir() }
    step([
        $class: 'CopyArtifact',
        filter: 'exported-artifacts/JenkinsChangeQueue.dat',
        fingerprintArtifacts: true,
        projectName: env.JOB_NAME,
        selector: [$class: 'StatusBuildSelector', stable: false],
        optional: true,
    ])
}

def prepare_python_env() {
    sh """\
        #!/bin/bash -xe
        if [[ -e '/usr/bin/dnf' ]]; then
            sudo dnf install -y python-jinja2
        else
            sudo yum install -y python-jinja2
        fi
    """.stripIndent()
}

def run_queue_action_py() {
    withEnv(['PYTHONPATH=jenkins']) {
        prepare_python_env()
        sh """\
            #!/usr/bin/env python
            import sys

            from scripts.change_queue import JenkinsChangeQueue

            JenkinsChangeQueue.setup_logging()
            with JenkinsChangeQueue.persist_in_artifacts() as cq:
                cq.act_on_job_params(
                    '${params.QUEUE_ACTION}', '${params.ACTION_ARG}'
                )
        """.stripIndent()
    }
}

@NonCPS
def get_build_display_name() {
    def name_from_log = currentBuild.rawBuild.getLog(50).findResult {
        def match = (it =~ /Queue action: (.+)/)
        if(match.asBoolean()) {
            return match[0][1]
        }
    }
    if(name_from_log) {
        return "${currentBuild.id} ${name_from_log}"
    }
    return currentBuild.id
}

// We need to return 'this' so the actual pipeline job can invoke functions from
// this script
return this