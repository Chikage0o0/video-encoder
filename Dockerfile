FROM archlinux:base-devel AS base

RUN pacman -Syy --noconfirm && \
    pacman -S --noconfirm ffmpeg vapoursynth svt-av1 vapoursynth-plugin-lsmashsource fftw hwloc ocl-icd vulkan-icd-loader

FROM archlinux:base-devel AS build

RUN pacman -Syy --noconfirm && \
    pacman -S --noconfirm --needed git go && \
    useradd -m -G wheel -s /bin/bash app && \
    sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers && \
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

USER app

RUN cd ~ && git clone https://aur.archlinux.org/yay.git && cd yay && \
    makepkg -sri --needed --noconfirm

FROM build AS build-plugins

RUN yay -Syy --noconfirm && \
    yay -S --noconfirm vapoursynth-plugin-deblock-git vapoursynth-plugin-fluxsmooth-git vapoursynth-plugin-fmtconv-git \
    vapoursynth-plugin-fvsfunc-git vapoursynth-plugin-vsutil-git vapoursynth-plugin-havsfunc-git \
    vapoursynth-plugin-muvsfunc-git vapoursynth-plugin-mvsfunc-git vapoursynth-plugin-mvtools-git vapoursynth-plugin-assrender-git \
    vapoursynth-plugin-f3kdb-git  && \
    sudo mkdir -p /site-packages && sudo chown -R app /site-packages  && \
    find $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages -maxdepth 1 -name "*.py" -type f | xargs -i cp -f {} /site-packages/ && \
    find $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages -maxdepth 1 -name "vsutil" -type d | xargs -i cp -rf {} /site-packages/

FROM base AS image

COPY --from=build-plugins /site-packages /site-packages
COPY --from=build-plugins /usr/lib/vapoursynth/* /usr/lib/vapoursynth/

RUN cp -rf /site-packages/* $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages && rm -rf /site-packages

VOLUME ["/videos"]
WORKDIR /videos

ENTRYPOINT [ "/bin/bash" ]
