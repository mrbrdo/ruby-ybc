#!/bin/bash
cd ../..
rake
cd spec/custom
ruby t.rb
