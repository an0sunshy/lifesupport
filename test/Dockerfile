# Test rig for bootstrap.sh — Ubuntu 24.04 with systemd + sshd.
# Built on geerlingguy's well-tested ansible-target image which already
# bakes in the systemd-in-docker dance.
FROM geerlingguy/docker-ubuntu2404-ansible:latest

ENV DEBIAN_FRONTEND=noninteractive

# Minimal extras the bootstrap assumes are present (git, curl, ca-certs are
# usually in the base; openssh-server we need explicitly).
RUN apt-get update -qq && \
    apt-get install -y -qq openssh-server sudo git curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/sshd

# Test user — matches odin's setup (xiao with passwordless sudo so the test
# doesn't deadlock on a password prompt). Real hosts keep password sudo.
# Use uid 1000 so the bind-mounted SSH keys (owned by host's xiao=1000) are
# readable inside the container. The base image's ubuntu user already holds
# 1000, so drop it first.
RUN userdel -r ubuntu 2>/dev/null || true && \
    useradd -m -s /bin/bash -u 1000 -G sudo xiao && \
    echo 'xiao ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/xiao && \
    chmod 0440 /etc/sudoers.d/xiao && \
    install -d -o xiao -g xiao -m 0700 /home/xiao/.ssh

# authorized_keys is baked from a build-arg (passed in by run-test.sh as
# the contents of thor's id_ed25519.pub). The runtime mount of the private
# key happens via docker-compose volumes.
ARG AUTHORIZED_KEY=""
RUN if [ -n "$AUTHORIZED_KEY" ]; then \
      echo "$AUTHORIZED_KEY" > /home/xiao/.ssh/authorized_keys && \
      chown xiao:xiao /home/xiao/.ssh/authorized_keys && \
      chmod 0600 /home/xiao/.ssh/authorized_keys ; \
    fi

# Enable sshd via systemd — geerlingguy's base image runs `/usr/sbin/init`.
RUN systemctl enable ssh

EXPOSE 22

# Inherit ENTRYPOINT/CMD from base (systemd init).
