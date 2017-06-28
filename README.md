# README

This repository allows you to build pjlib as a static library for android.

Currently supported en build library for:

| ABI  	        | SSL  	| OPUS 	|
|---	        |---	|---	|
| armeabi  	    |   X	|   X	|
| armeabu-v7a  	|   X	|   X	|
| arm64-v8a  	|   X	|   X	|
| x86  	        |   X	|   X	|
| x86_64  	    |   X	|   X	|
| mips64  	    |   X	|   X	|


## How To

To build a clean library the following commands are needed
    docker-compose build
    docker-compose run pjsip
Now you are in the docker container and now start with the following command
    cd home
    ./build.sh

Go get cup of coffee because this is gonna take a while :)

After the build is complete there is a pjsip.aar file in the root directory.

To use the new compiled Android library in your project you must do the following.
- Copy the aar file to the following directory in your android project.
    app/libs
- Open your build.gradle file in the app folder.
- In the dependencies part add the following line.
    compile(name: 'pjsip', ext: 'aar')

And now you Android application is ready to use PJSIP!