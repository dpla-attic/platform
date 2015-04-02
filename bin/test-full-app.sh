#!/bin/bash
# 
# One-liner convenience script to ensure developers are running entire
# test suite the same way Travis CI is. (Referenced from .travis.yml)
# Brian 'Phunk' Gadoury <bgadoury@endpoint.com> 

#
if [ $TRAVIS == "true" ]
then
  echo "Note: \$TRAVIS is \"true\"; skipping scenarios etc. tagged \"@travis-exclude\""
fi
bundle exec rspec spec v1/spec && bundle exec rake cucumber
