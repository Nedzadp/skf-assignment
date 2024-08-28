# SKF assignment

## Prerequisites

To setup development environment follow these steps:
1. Install Python (3.12.5)
2. Use pip (package manager) to install necessary dependencies:
    1. ```pip install Flask```
    2. ```pip install elasticsearch```
    3. ```pip install python-dotenv```

## Project structure

```app.py``` is a main entry point of application. ```ui.py``` is implementation of request methods POST, GET on path /.
```.env``` defines env variables for Flask app and ```docker-compose.yml```.
```dependencies.txt``` is used by ```Dockerfile``` when building docker image to first install all necessary dependencies.

```3_architecture_task``` contains diagram and description of task 3. Architecture Task: from the assignemnt

```4_infrastructure``` folder contains terraform code.

```5_cicd``` contains explaination of task 5.

## Environment variables

Environment variables are defined in file ```.env```. This file contains information about elasticsearch server such as:
url, username and password.

## Running locally

To run locally we need docker engine and docker compose plugin installed.
In root folder of the project just execute:
```docker compose up -build -d```
This command will first build flask-app docker image from Dockerfile and also pull elasticsearch server docker image.
Then it will start two containers in network: ```app``` and ```elasticsearch```. Application should be accessible via:
```http://localhost:8082```