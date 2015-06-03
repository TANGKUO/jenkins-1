#!/bin/bash -xe
echo "shell-scripts/system_tests_generate_scenario.sh"

cat > ${WORKSPACE?}/scenario.json << \EOF_json
{
    "domains": {
        "engine": {
            "memory":4096,
            "nics": [
                {
                    "net": "testenv"
                }
            ],
            "disks": [
                {
                    "template_name": "centos7_engine",
                    "type": "template",
                    "name": "root",
                    "dev": "vda",
                    "format": "qcow2"
                }
            ],
            "metadata": {
                "ovirt-engine-password": "123",
                "ovirt-role": "engine",
                "ovirt-scripts": [
                    "/usr/share/ovirttestenv/setup_scripts/add_local_repo.sh",
                    "/usr/share/ovirttestenv/setup_scripts/setup_engine.sh"
                ]
            }
        },
        "storage-iscsi": {
            "memory":4096,
            "nics": [
                {
                    "net": "testenv"
                }
            ],
            "disks": [
                {
                    "template_name": "storage-iscsi",
                    "type": "template",
                    "name": "root",
                    "dev": "vda",
                    "format": "qcow2"
                },
                {
                    "size": "60G",
                    "type": "empty",
                    "name": "extra1",
                    "dev": "vdb",
                    "format": "raw"
                }
            ],
            "metadata": {
                "ovirt-scripts": [
                    "/usr/share/ovirttestenv/setup_scripts/setup_storage_iscsi.sh"
                ]
            }
        },
        "storage-nfs": {
            "memory":4096,
            "nics": [
                {
                    "net": "testenv"
                }
            ],
            "disks": [
                {
                    "template_name": "storage-nfs",
                    "type": "template",
                    "name": "root",
                    "dev": "vda",
                    "format": "qcow2"
                },
                {
                    "size": "60G",
                    "type": "empty",
                    "name": "extra1",
                    "dev": "vdb",
                    "format": "raw"
                },
                {
                    "template_name": "storage-nfs-export",
                    "type": "template",
                    "name": "export",
                    "dev": "vdc",
                    "format": "qcow2"
                }
            ],
            "metadata": {
                "ovirt-scripts": [
                    "/usr/share/ovirttestenv/setup_scripts/setup_storage_nfs.sh"
                ]
            }
        },
        "host0": {
            "memory":4096,
            "nics": [
                {
                    "net": "testenv"
                }
            ],
            "disks": [
                {
                    "template_name": "centos7_docker_host",
                    "type": "template",
                    "name": "root",
                    "dev": "vda",
                    "format": "qcow2"
                }
            ],
            "metadata": {
                "ovirt-capabilities": [
                    "snapshot-live-merge"
                ],
                "ovirt-role": "host",
                "ovirt-scripts": [
                    "/usr/share/ovirttestenv/setup_scripts/add_local_repo.sh",
                    "/usr/share/ovirttestenv/setup_scripts/setup_container_host.sh"
                ]
            }
        },
        "host1": {
            "memory":4096,
            "nics": [
                {
                    "net": "testenv"
                }
            ],
            "disks": [
                {
                    "template_name": "centos7_docker_host",
                    "type": "template",
                    "name": "root",
                    "dev": "vda",
                    "format": "qcow2"
                }
            ],
            "metadata": {
                "ovirt-capabilities": [
                    "snapshot-live-merge"
                ],
                "ovirt-role": "host",
                "ovirt-scripts": [
                    "/usr/share/ovirttestenv/setup_scripts/add_local_repo.sh",
                    "/usr/share/ovirttestenv/setup_scripts/setup_container_host.sh"
                ]
            }
        }
    },
    "nets": {
        "testenv": {
            "dhcp": {
                "start": 100,
                "end": 254
            },
            "management": true
        }
    }
}
EOF_json