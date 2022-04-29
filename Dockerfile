FROM archlinux:base AS base

RUN pacman -Syy --noconfirm && \
    pacman -S --noconfirm ffmpeg vapoursynth svt-av1 vapoursynth-plugin-lsmashsource fftw hwloc python-pip libass sudo mediainfo vulkan-icd-loader

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
    yay -S --noconfirm vapoursynth glslang vulkan-icd-loader vulkan-headers && \
    yay -S --noconfirm vapoursynth-plugin-deblock-git vapoursynth-plugin-fluxsmooth-git vapoursynth-plugin-fmtconv-git \
    vapoursynth-plugin-fvsfunc-git vapoursynth-plugin-vsutil-git vapoursynth-plugin-havsfunc-git \
    vapoursynth-plugin-muvsfunc-git vapoursynth-plugin-mvsfunc-git vapoursynth-plugin-mvtools-git vapoursynth-plugin-assrender-git \
    vapoursynth-plugin-f3kdb-git vapoursynth-plugin-nnedi3-git vapoursynth-plugin-edi_rpow2-git vapoursynth-plugin-znedi3-git \
    vapoursynth-plugin-nlm-git vapoursynth-plugin-waifu2x-ncnn-vulkan-git && \
    sudo mkdir -p /site-packages && sudo chown -R app /site-packages  && \
    find $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages -maxdepth 1 -name "*.py" -type f | xargs -i cp -f {} /site-packages/ && \
    find $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages -maxdepth 1 -name "vsutil" -type d | xargs -i cp -rf {} /site-packages/ 

FROM build AS build-svt-av1

RUN yay -Syy --noconfirm && \
    yay -S --noconfirm svt-av1-git

FROM base AS tmp

COPY --from=build-svt-av1 /usr/lib/libSvtAv1Enc.so.1 /build-tmp/
COPY --from=build-svt-av1 /usr/bin/SvtAv1EncApp /build-tmp/
COPY --from=build-plugins /site-packages /build-tmp/site-packages/
COPY --from=build-plugins /usr/lib/vapoursynth /build-tmp/vapoursynth/

FROM base AS image

COPY --from=tmp /build-tmp/ /build-tmp/

ENV JUPYTER_CONFIG_DIR=/jupyter/config \
    JUPYTER_DATA_DIR=/jupyter/data \
    JUPYTER_RUNTIME_DIR=/jupyter/runtime

RUN cp -rf /build-tmp/site-packages/* $(python -c "import os;print(os.path.dirname(os.__file__))")/site-packages/ && \
    cp -f /build-tmp/SvtAv1EncApp /usr/bin/SvtAv1EncApp && \
    cp -f /build-tmp/libSvtAv1Enc.so.1 /usr/lib/libSvtAv1Enc.so.1 && \
    cp -rf /build-tmp/vapoursynth/* /usr/lib/vapoursynth/ && \
    rm -rf /build-tmp && \
    pip install yuuno && \
    useradd -m -G wheel -s /bin/bash app && \
    sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers && \
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

USER app

EXPOSE 8888/tcp

VOLUME ["/videos"]
VOLUME ["/jupyter"]
WORKDIR /videos

CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
