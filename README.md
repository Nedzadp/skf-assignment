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
