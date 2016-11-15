FROM ubuntu
MAINTAINER VCA Technology <developers@vcatechnology.com>

# Build-time metadata as defined at http://label-schema.org
ARG PROJECT_NAME
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="$PROJECT_NAME" \
      org.label-schema.description="A Linux Mint image that is updated daily" \
      org.label-schema.url="https://www.linuxmint.org/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vcatechnology/docker-linux-mint" \
      org.label-schema.vendor="VCA Technology" \
      org.label-schema.version=$VERSION \
      org.label-schema.license=MIT \
      org.label-schema.schema-version="1.0"

COPY official-package-repositories.list /etc/apt/sources.list.d/offical-package-repositories.list
RUN apt-get update
RUN apt-get --yes --allow-unauthenticated install linuxmint-keyring
RUN apt-get --yes --allow-unauthenticated install linux-kernel-generic
RUN apt-get --yes --allow-unauthenticated install mdm
RUN apt-get --yes -f --allow-unauthenticated install mint-meta-core deborphan
RUN apt-get clean && apt-get autoclean

# Make sure APT operations are non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Create install script
RUN touch                                                                 /usr/local/bin/vca-install-package \
 && chmod +x                                                              /usr/local/bin/vca-install-package \
 && echo '#! /bin/sh'                                                  >> /usr/local/bin/vca-install-package \
 && echo 'set -e'                                                      >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -q update'                                           >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -qy -o Dpkg::Options::="--force-confnew" install $@' >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -qy clean'                                           >> /usr/local/bin/vca-install-package

# Create uninstall script
RUN touch                                   /usr/local/bin/vca-uninstall-package \
 && chmod +x                                /usr/local/bin/vca-uninstall-package \
 && echo '#! /bin/sh'                    >> /usr/local/bin/vca-uninstall-package \
 && echo 'set -e'                        >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy remove --purge $@' >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy autoremove'        >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy clean'             >> /usr/local/bin/vca-uninstall-package

# Generate locales
RUN vca-install-package apt-utils \
 && vca-install-package locales language-pack-en \
 && echo "LANG=en_GB.UTF-8" > /etc/default/locale \
 && update-locale LANG=en_GB.UTF-8
ENV LANG=en_GB.UTF-8

# Set up the timezone
RUN vca-install-package tzdata \
 && echo "Europe/London" > /etc/timezone \
 && dpkg-reconfigure tzdata

# Update all packages
RUN apt-get -q update \
 && echo console-setup console-setup/charmap select UTF-8 | debconf-set-selections \
 && apt-get -qy -o Dpkg::Options::="--force-confnew" dist-upgrade \
 && apt-get -qy autoremove \
 && apt-get -q clean
