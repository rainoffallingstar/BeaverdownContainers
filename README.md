# BeaverdownContainers

[![](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beavermake.yml/badge.svg)](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beavermake.yml) [![](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverworker.yml/badge.svg)](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverworker.yml) 

[![](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverstudio.yml/badge.svg)](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverstudio.yml) [![](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverjupyter.yml/badge.svg)](https://github.com/rainoffallingstar/BeaverdownContainers/actions/workflows/beaverjupyter.yml)

Efficient Docker containers for enhancing Beaverdown2 workflow.

Designed for performance and ease of use, BeaverdownContainers streamlines bioinformatics and data analysis tasks.

## beavermake

A Manjaro-based container optimized for Snakemake, leveraging the base image from [DanySK/docker-manjaro-linux-with-yay](https://github.com/DanySK/docker-manjaro-linux-with-yay).

``` bash
docker pull fallingstar10/beavermake:latest

#or

dockerR::image_pull("fallingstar10/beavermake:latest")

#then run it
docker run -it --name beavermake fallingstar10/beavermake:latest
```

## beaverworker

Enhanced with essential bioinformatics tools, designed to complement beavermake.

``` bash
docker pull fallingstar10/beaverworker:latest

#or

dockerR::image_pull("fallingstar10/beaverworker:latest")

#then run it
docker run -it --name beaverworker fallingstar10/beaverworker:latest
```

## beaverstudio

An RStudio server integrated with beaverworker, offering a powerful environment for data analysis.

``` bash
docker pull fallingstar10/beaverstudio:latest

#or

dockerR::image_pull("fallingstar10/beaverstudio:latest")

#then run it
docker run -p 8787:8787 -p 8080:8080 --name beaverstudio fallingstar10/beaverstudio:latest
```

## beaverjupyter

An jupyterlab server integrated with beaverworker, offering a powerful environment for data analysis.

``` bash
docker pull fallingstar10/beaverjupyter:latest

#or

dockerR::image_pull("fallingstar10/beaverjupyter:latest")

#then run it
docker run -p 8889:8889  --name beaverjupyter fallingstar10/beaverjupyter:latest
```
