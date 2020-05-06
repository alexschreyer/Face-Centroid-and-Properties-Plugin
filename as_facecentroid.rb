=begin

Copyright 2008-2020, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/centroid-and-area-properties-plugin-for-sketchup/

Name :          Face Centroid

Version:        1.4
Date :          5/6/2020

Description :   Draws a construction point at the centroid of a shape that lies flat
                on the X-Y plane (the ground). Also calculates
                area, perimeter, Moments of Inertia and radius of gyration of face
                (Ix, Iy, Ixy, rx, ry)

Usage :         1. Draw shapes on the X-Y (ground) plane and select at least
                one face, make sure the face points up!
                2. Select "Get Face Centroid" from the context menu
                3. A construction point will be placed at the centroid and
                the area properties will be displayed for each face
                PLEASE NOTE: Since SketchUp approximates curved shapes with
                polygons, this calculation will only be as good as the
                approximation. To increase accuracy, increase the number
                of polygons.

History:        1.0 (10/11/2008)
                - First version
                1.1 (unreleased)
                - Changed results box to WebDialog. Looks nicer and all values
                  can be copied at the same time.
                - Checks normal that face is coplanar to XY
                - Adds height so that centroid is shown at height of face
                1.2 (2/19/2014):
                - Removed the Tools menu item, now only context menu
                - Cleaned up code
                - Results uses multiline textbox for simplicity
                - Properties display now displays model units
                - Dialog for option to draw crosshairs
                1.3 (3/5/2014):
                - Added limit to only use 10 faces at a time
                - Removed the need for flipping of faces
                - No more @mod variable
                - Better unit handling
                1.4 (5/6/2020):
                - Code cleanup
                - Fixed loader code
                - Added menu items to Tool menu
                - Added Help link to site
                - Now draws face information as text
                - Face limit increased to 50 (due to new speed)
                - Adds text and crosshairs to new layer

Issues:         - For faces with internal openings it is necessary to draw connecting line between each
                  opening and the perimeter
                - Could implement translate so that this works on arbitrarily
                  oriented surfaces
                - Get angle of strong axis and draw it.

=end


# ========================


require 'sketchup.rb'
require 'extensions.rb'


# ========================


module AS_Extensions

  module AS_FaceCentroid
  
    @extversion           = "1.4"
    @exttitle             = "Face Centroid"
    @extname              = "as_facecentroid"
    
    @extdir = File.dirname(__FILE__)
    @extdir.force_encoding('UTF-8') if @extdir.respond_to?(:force_encoding)
    
    loader = File.join( @extdir , @extname , "as_facecentroid.rb" )
   
    extension             = SketchupExtension.new( @exttitle , loader )
    extension.copyright   = "Copyright 2008-#{Time.now.year} Alexander C. Schreyer"
    extension.creator     = "Alexander C. Schreyer, www.alexschreyer.net"
    extension.version     = @extversion
    extension.description = "Tool to accurately calculate the centroid and other area properties (A,I,r) of any polygonal face."
    
    Sketchup.register_extension( extension , true )
         
  end  # module AS_FaceCentroid
  
end  # module AS_Extensions


# ========================
