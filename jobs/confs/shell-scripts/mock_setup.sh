#!/bin/bash -xe
echo "shell-scripts/mock_setup.sh"

extra_packages() {
    # Add extra packages we need for mock_runner.sh
    if [[ -e '/usr/bin/dnf' ]]; then
        sudo dnf -y install python3-PyYAML PyYAML
    else
        sudo yum -y install python34-PyYAML PyYAML
    fi
}

docker_setup () {
    #Install docker engine and start the service
    sudo yum -y install docker
    sudo systemctl restart docker
    if [[ $? -ne 0 ]]; then
        echo "[DOCKER SETUP] Failed to start docker.service"
        return 1
    fi
    echo "[DOCKER SETUP] Docker service started"
    return 0
}


shopt -s nullglob

# cleanup and setup env
if [[  "$CLEAN_CACHE" == "true" ]]; then
    sudo rm -Rf /var/cache/mock
fi

failed=false

mock_dir="$WORKSPACE/mock"
# stop any processes running inside the chroot
chroots=("$WORKSPACE"/mock/*)
arch=$(uname -i)
echo "arch is $arch"
for chroot in "${chroots[@]}"; do
    echo "Cleaning up chroot $chroot"
    ### Generate the mock configuration
    pushd "$WORKSPACE"/jenkins/mock_configs
    mock_conf="${chroot##*/}"
    base_conf="${mock_conf%%$arch*}$arch"
    echo "base_conf is $base_conf"
    echo "#### Generating mock configuration"
    ./mock_genconfig \
        --name="$mock_conf" \
        --base="$base_conf.cfg" \
        --option="basedir=$WORKSPACE/mock/" \
        --try-proxy \
    > "$mock_conf.cfg"
    cat "$mock_conf.cfg"
    popd

    my_mock="/usr/bin/mock"
    my_mock+=" --configdir=$WORKSPACE/jenkins/mock_configs"
    my_mock+=" --root=$mock_conf"
    my_mock+=" --resultdir=$WORKSPACE"

    echo "Killing all mock orphan processes, if any."
    $my_mock \
        --orphanskill \
    || {
        echo "ERROR:  Failed to kill orphans on $chroot."
        failed=true
    }

    mounts=($(mount | awk '{print $3}' | grep "$chroot")) || :
    if [[ "$mounts" ]]; then
        echo "Found mounted dirs inside the chroot $chroot. Trying to umount."
    fi
    for mount in "${mounts[@]}"; do
        sudo umount --lazy "$mount" \
        || {
            echo "ERROR:  Failed to umount $mount."
            failed=true
        }
    done
done

extra_packages || failed=true
docker_setup || failed=true

# If we failed in any step, abort to avoid breaking the host
if $failed; then
    echo "Aborting."
    exit 1
fi

sudo rm -Rf mock mock-cache exported-artifacts
mkdir -p mock exported-artifacts
chgrp mock mock "$WORKSPACE" "$WORKSPACE"/exported-artifacts
chmod g+rws mock

# Make sure the cache has a newer timestamp than the config file or it will
# not be used
sudo touch /var/cache/mock/*/root_cache/cache.tar.gz 2>/dev/null || :
# Make sure yum caches are clean
sudo yum clean all
exit 0
