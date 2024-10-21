FROM mcr.microsoft.com/devcontainers/cpp:1-debian-12

ARG REINSTALL_CMAKE_VERSION_FROM_SOURCE="none"

# Optionally install the cmake for vcpkg
COPY ./reinstall-cmake.sh /tmp/

RUN if [ "${REINSTALL_CMAKE_VERSION_FROM_SOURCE}" != "none" ]; then \
        chmod +x /tmp/reinstall-cmake.sh && /tmp/reinstall-cmake.sh ${REINSTALL_CMAKE_VERSION_FROM_SOURCE}; \
    fi \
    && rm -f /tmp/reinstall-cmake.sh

# [Optional] Uncomment this section to install additional vcpkg ports.
RUN su vscode -c "${VCPKG_ROOT}/vcpkg install nlohmann-json"

# [Optional] Uncomment this section to install additional packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends apt-transport-https wget

RUN if ! [ -f /usr/local/share/keyring/devkitpro-pub.gpg ]; then \
        mkdir -p /usr/local/share/keyring/ \
        && wget -O /usr/local/share/keyring/devkitpro-pub.gpg https://apt.devkitpro.org/devkitpro-pub.gpg; \
    fi

RUN if ! [ -f /etc/apt/sources.list.d/devkitpro.list ]; then \
        echo "deb [signed-by=/usr/local/share/keyring/devkitpro-pub.gpg] https://apt.devkitpro.org stable main" > /etc/apt/sources.list.d/devkitpro.list; \
    fi

RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install devkitpro-pacman gcc-multilib libbluetooth-dev

RUN ln -s /proc/mounts /etc/mtab

RUN dkp-pacman -Syyu --noconfirm \
    && dkp-pacman --noconfirm -S wii-dev wii-sdl2 wii-sdl2_ttf

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITARM=/opt/devkitpro/devkitARM
ENV DEVKITPPC=/opt/devkitpro/devkitPPC