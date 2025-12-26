FROM fallingstar10/beaverworker:latest

RUN pacman -Syy --noconfirm && \
    pacman -S --noconfirm jupyterlab && \
    pacman -Sc --noconfirm

ENV LANG=C.UTF-8

EXPOSE 8889

CMD ["jupyter-lab --no-browser --allow-root  --ip=* --port 8889"] 