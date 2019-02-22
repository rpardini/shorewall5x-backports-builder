FROM ubuntu:xenial as ubuntuBuilder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y --no-install-recommends install devscripts build-essential lintian debhelper fakeroot lsb-release figlet po-debconf wget

WORKDIR /shorewall/build
RUN wget http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall/shorewall_5.2.2-1.dsc http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall/shorewall_5.2.2.orig.tar.gz http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall/shorewall_5.2.2-1.debian.tar.xz
RUN wget http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall-core/shorewall-core_5.2.2-1.dsc http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall-core/shorewall-core_5.2.2.orig.tar.gz http://archive.ubuntu.com/ubuntu/pool/universe/s/shorewall-core/shorewall-core_5.2.2-1.debian.tar.xz
RUN dpkg-source -x shorewall_5.2.2-1.dsc
RUN dpkg-source -x shorewall-core_5.2.2-1.dsc


# List contents
WORKDIR /shorewall/build
RUN rm *.tar.xz *.dsc

# Build shorewall first; xenial then bionic

# xenial
WORKDIR /shorewall/build/shorewall-5.2.2
COPY changelog/shorewall/xenial /shorewall/build/shorewall-5.2.2/debian/changelog
RUN debuild -S -us -uc

# bionic
WORKDIR /shorewall/build/shorewall-5.2.2
COPY changelog/shorewall/bionic /shorewall/build/shorewall-5.2.2/debian/changelog
RUN debuild -S -us -uc

# Then build shorewall-core; xenial then bionic

# xenial
WORKDIR /shorewall/build/shorewall-core-5.2.2
COPY changelog/shorewall-core/xenial /shorewall/build/shorewall-core-5.2.2/debian/changelog
RUN debuild -S -us -uc

# bionic
WORKDIR /shorewall/build/shorewall-core-5.2.2
COPY changelog/shorewall-core/bionic /shorewall/build/shorewall-core-5.2.2/debian/changelog
RUN debuild -S -us -uc

# List
WORKDIR /shorewall/build/
RUN ls -la


########################################################################################################################
## -- the final image produced from this Dockerfile just contains the produced source and binary packages.
##    it uses alpine:3.8 because that's light enough, and already downloaded for node:10-alpine
FROM alpine:3.8

COPY --from=ubuntuBuilder /shorewall/build/*_source* /sourcepkg/
COPY --from=ubuntuBuilder /shorewall/build/*.dsc /sourcepkg/
COPY --from=ubuntuBuilder /shorewall/build/*debian.tar.xz /sourcepkg/
COPY --from=ubuntuBuilder /shorewall/build/*.orig.tar.gz /sourcepkg/

# Hack: use volumes to "exfiltrate" the source files back to the host machine.
# This is just a marker directory to avoid mistakes when mounting volumes.
RUN mkdir -p /exfiltrate_to/empty

# Simple script to exfiltrate on run.
COPY docker/exfiltrate.sh /opt/exfiltrate.sh
CMD /opt/exfiltrate.sh
