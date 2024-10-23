# Alpine - from scratch

## Background

This image was an experiment on what is needed to create
an docker image from scratch and it was really easy.

## How it was made

This was made by downloading base filesystem from Alpine website, then
creating a docker file based on the scratch docker image and copy the base
files to the image and end with a CMD so the image can be used.

## Requirements

To run this image Docker needs to be installed.

## Usage

### Build image

Run the following command to build the image.

````shell
$ docker build -t alpine3.20-x86_64 .
````

### Run image

Once the image is build, you can run it using the command below.

````shell
$ docker run -it alpine3.20-x86_64
````
