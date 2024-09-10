FROM fallingstar10/beaverworker:latest

RUN pacman -S --noconfirm jupyterlab &&\
    pacman -Sc --noconfirm

EXPOSE 8889

CMD ["jupyter-lab --no-browser --allow-root --port 8889"]

