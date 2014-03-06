# Loader for as_facecentroid/as_facecentroid.rb

require 'sketchup'
require 'extensions'

as_facecentroid = SketchupExtension.new "Face Centroid", "as_facecentroid/as_facecentroid.rb"
as_facecentroid.copyright= 'Copyright 2008-2014 Alexander C. Schreyer'
as_facecentroid.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_facecentroid.version = '1.3'
as_facecentroid.description = "Tool to accurately calculate the centroid and other area properties (A,I,r) of a face."
Sketchup.register_extension as_facecentroid, true
