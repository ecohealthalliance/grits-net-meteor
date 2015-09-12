# grits-net-meteor
![Build Status](https://circleci.com/gh/ecohealthalliance/grits-net-meteor.svg?style=shield&circle-token=0bb5a68a6c2ff8aea6f0ae0c324a738362198f10)

A Meteor application initializing a Leaflet map and demonstrating 

## install

1. setup virtualenv

  ``` virtualenv grits-net-consume-env```

2. activate the virtual environment

  ``` source grits-net-consume-env/bin/activate```

3. install 3rd party libraries

  ``` pip install -r requirements.txt```

## test
  ``` nosetests ```

## run
  ``` python grits_consume.py test/data/Schedule_Weekly_Extract_Report.tsv ```
