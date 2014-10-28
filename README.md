Alpha
=============

A simple image website using the Sequelize ORM for MySQL and Redis for sessions.

![The Home View](https://www.dropbox.com/s/9cygmrd9imcm1fb/Screenshot%202014-10-28%2012.03.50.png?dl=1 "The homescreen")

### Description

This site has a simple Bootstrap themed UI to allow users to log in, upload photos, view their own uploads, and view everyone's uploaded photos and vote on them. The image and user metadata is stored in MySQL while the image ranking is accomplished by a Redis sorted set.

The server uses the ImageMagick library to resize uploaded photos, clean them, and convert them to the .jpeg format.

### Installation Instructions

Clone the repo and run `npm install` in the default directory.

After setting up Redis and MySQL on your machine (with the proper credentials in `configs/config.json`), 
you need to compile all the Coffeescript to run the script that builds the MySQL tables. 

First run `./scripts/build.sh` and then run `node ./bin/oneoff/init_db.js` until it says the initialization has finished.

Before you can upload or resize images, you will need to have ImageMagick installed and you will need to create the following directories: `./image/{thumbnail, optimized, original}`. I recommend setting up nginx to serve the image files. A simple example nginx config is below for serving the images and routing all other requests through the node server:

```
http {
  server {
    client_max_body_size 6M;
    
    location / {
      proxy_pass http://localhost:3000/;
    }

    location /image/thumbnail/ {
      root /Users/david/projects/alpha/;
    }

    location /image/optimized/ {
      root /Users/david/projects/alpha/;
    }
  }
}
```

`npm start` then starts the server.

