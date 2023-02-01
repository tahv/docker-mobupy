# Figure out missing dependencies with this command:
# ldd /usr/autodesk/MotionBuilder2023/bin/linux_64/* 2> /dev/null | sed -nE 's/\s*(.+) => not found/\1/p' | sort --unique
FROM ubuntu:20.04

# Qt verbose mode:
# ENV QT_DEBUG_PLUGINS=1

# Zero interaction with apt, accepts default answer for all questions.
ENV DEBIAN_FRONTEND=noninteractive

# Download, extract and install Motionbuilder.
RUN apt-get update && apt-get install -y alien wget \
    && wget --quiet --no-check-certificate -O mobu.tgz https://efulfillment.autodesk.com/NetSWDLD/2023/MOBPRO/D46BD68F-3C1F-3488-87C1-862508E1E16D/ESD/Autodesk_MB_2023_ML_Linux64.tgz \
    && mkdir mobu \
    && tar -xvf mobu.tgz -C mobu \
    && cd mobu/Packages \
    && alien -cv MotionBuilder2023_64-2023-1.x86_64.rpm \
    # Ignore "command not found" error of post install script (licensing) and delete the
    # script to avoid additional errors later.
    && dpkg -i *.deb; if [ $? -eq 127 ]; then exit 0; fi \
    && rm /var/lib/dpkg/info/motionbuilder2023-64.postinst \
    && cd ../../ \
    # Cleanup installed dependencies
    && apt-get purge -y --auto-remove alien wget \
    && rm -rf /var/lib/apt/lists/* \
    # Free some space
    && rm -rf \
        mobu \
        mobu.tgz \
        /usr/autodesk/MotionBuilder2023/Tutorials \
        /usr/autodesk/MotionBuilder2023/LearningMovies \
        /usr/autodesk/MotionBuilder2023/PrevisMoves

# Install Motionbuilder dependencies
RUN apt-get update && apt-get install -y \
    # Qt5 library, contain all dependencies
    libqt5gui5 \
    # Fake X server, required to launch mobupy (because Qt is required)
    xvfb \
    # Other motionbuilder dependencies
    libopengl0 \
    libglu1-mesa \
    libxt6 \
    libpulse-mainloop-glib0 \
    libasound2 \
    libnss3 \
    libnspr4 \
    libcg \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# Motionbuilder depend on libicu, which is no longer available as a package.
RUN apt-get update && apt-get install -y alien wget \
    && wget --quiet -O libicu50.rpm http://mirror.centos.org/centos/7/os/x86_64/Packages/libicu-50.2-4.el7_7.x86_64.rpm \
    && alien -cv libicu50.rpm \
    && dpkg -i libicu*.deb \
    && ln -s /usr/lib64/libicuuc.so.50 /usr/lib/libicuuc.so.50 \
    && ln -s /usr/lib64/libicudata.so.50 /usr/lib/libicudata.so.50 \
    # Delete downloaded files
    && rm -f libicu50.rpm libicu*.deb \
    # Cleanup installed dependencies
    && apt-get purge -y --auto-remove alien wget \
    && rm -rf /var/lib/apt/lists/*

# Add mobupy to PATH
ENV MOBU_LOCATION=/usr/autodesk/MotionBuilder2023
ENV PATH=$MOBU_LOCATION/bin/linux_64:$PATH

# Init virtual framebuffer
ENV DISPLAY=:1
CMD Xvfb :1 -screen 0 640x480x8 & bash

