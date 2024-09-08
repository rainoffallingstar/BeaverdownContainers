# BeaverdownContainers

Efficient Docker containers for enhancing Beaverdown2 workflow.

Designed for performance and ease of use, BeaverdownContainers streamlines bioinformatics and data analysis tasks.


## beavermake

A Manjaro-based container optimized for Snakemake, leveraging the base image from [DanySK/docker-manjaro-linux-with-yay](https://github.com/DanySK/docker-manjaro-linux-with-yay).

``` bash
docker pull fallingstar10/beavermake:latest

#or

dockerR::image_pull("fallingstar10/beavermake:latest")

#then run it
docker run -it -name beavermake fallingstar10/beavermake:latest
```

## beaverworker

Enhanced with essential bioinformatics tools, designed to complement beavermake.

``` bash
docker pull fallingstar10/beaverworker:latest

#or

dockerR::image_pull("fallingstar10/beaverworker:latest")

#then run it
docker run -it -name beaverworker fallingstar10/beaverworker:latest
```

## beaverstudio

An RStudio server integrated with beaverworker, offering a powerful environment for data analysis.
``` bash
docker pull fallingstar10/beaverstudio:latest

#or

dockerR::image_pull("fallingstar10/beaverstudio:latest")

#then run it
docker run -p 8787:8787 -p 8080:8080 -name beaverstudio fallingstar10/beaverstudio:latest
```
