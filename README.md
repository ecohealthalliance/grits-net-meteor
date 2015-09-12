# grits-net-meteor
![Build Status](https://circleci.com/gh/ecohealthalliance/grits-net-meteor.svg?style=shield&circle-token=0bb5a68a6c2ff8aea6f0ae0c324a738362198f10)

A Meteor package for filtering grits transportation data and displaying on 
a Leaflet map.

## install

1. setup a meteor app, change dir, and remove starter files

  ```
  meteor create grits-net-wrapper
  cd grits-net-wrapper/
  rm grits-net-wrapper.*
  ```

2. create packages folder and change dir

  ``` 
  mkdir packages
  cd packages/
  ```

3. clone 'grits-net-meteor' and 'grits-net-mapper'

  ```
  git clone git@github.com:ecohealthalliance/grits-net-meteor.git
  git clone git@github.com:ecohealthalliance/grits-net-mapper.git
  ```

4. switch to 'Initialize-meteor-app' branch

  ```
  cd grits-net-meteor/
  git fetch origin
  git checkout -b Initialize-meteor-app origin/Initialize-meteor-app
  cd ..
  ```
  
5. switch to 'mapper-package-initialization' branch
  
  ```
  cd grits-net-mapper/
  git fetch origin
  git checkout -b mapper-package-initialization origin/mapper-package-initialization
  cd ..
  ```

6. add packages

  ```
  meteor add grits:grits-net-meteor
  meteor add grits:grits-net-mapper
  meteor remove autopublish
  ```
  
7. setup MONGO_URL environment variable

  ```
  export MONGO_URL=mongodb://localhost/grits
  ```

8. create main.html

  ```
  <head>
    <title>Leaflet</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" /> 
  </head>
  <body>
    	{{> map }}    
  </body>
  ```

## mongodb

NOTE: mongodb will need to be populated by the grits-net-consume script

## run
  
  ``` 
  meteor
  ```
