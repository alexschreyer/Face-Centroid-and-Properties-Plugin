=begin

Copyright 2008-2014, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/

Name :          Face Centroid

Version:        1.2
Date :          2/19/2014

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

Issues:         - For faces with internal openings it is necessary to draw connecting line between each
                  opening and the perimeter
                - Could implement translate so that this works on arbitrarily
                  oriented surfaces
                - Get angle of strong axis and draw it.

=end


# =========================================


require 'sketchup'


# =========================================


module AS_FaceCentroid


    # Get the active model
    @mod = Sketchup.active_model
  
    
    # =========================================
    
    
    def self.calculate_centroid (a_face)
    # Do the math and display the results - returns the centroid or false
    
        # Get all the vertices for the current face
        vertices = a_face.vertices
        
        if (vertices.length < 3)
        
            UI.messagebox "Awfully sorry. Can't calculate centroid.\nPlease select at least one valid face."
            return false
        
        elsif (a_face.vertices.length != a_face.outer_loop.vertices.length)
        
            UI.messagebox "For faces with internal holes it is necessary to draw a connecting line between each hole and the face perimeter before using this tool."
            return false
        
        else
        
            # First calculate centroid:
            
            # Loop the first vertex around and create a point for the centroid
            vertices[vertices.length] = vertices[0]
            centroid = Geom::Point3d.new
            a_sum = 0.0
            x_sum = 0.0
            y_sum = 0.0
            
            for i in (0...vertices.length-1)
            
                temp = vertices[i].position.x * vertices[i+1].position.y - vertices[i+1].position.x * vertices[i].position.y
                a_sum += temp
                x_sum += (vertices[i+1].position.x + vertices[i].position.x) * temp
                y_sum += (vertices[i+1].position.y + vertices[i].position.y) * temp
                
            end
            
            area = a_sum / 2
            centroid.x = x_sum / (3 * a_sum)
            centroid.y = y_sum / (3 * a_sum)
            centroid.z = vertices[0].position[2]
            
            # Now calculate moments:
            adjusted_points_x = []
            adjusted_points_y = []
            i_x = 0.0
            i_y = 0.0
            i_xy = 0.0
            
            # Get all the vertices for the current face and wrap the first one again
            for i in (0...vertices.length)
            
              adjusted_points_x[i] = vertices[i].position.x - centroid.x
              adjusted_points_y[i] = vertices[i].position.y - centroid.y
              
            end
            
            for i in (0...adjusted_points_x.length-1)
            
              j = i+1
              temp = 0.5 * (adjusted_points_x[i] * adjusted_points_y[j] - adjusted_points_x[j] * adjusted_points_y[i]);
              i_x += (adjusted_points_y[i] * adjusted_points_y[i] + adjusted_points_y[i] * adjusted_points_y[j] + adjusted_points_y[j] * adjusted_points_y[j]) / 6 * temp;
              i_y += (adjusted_points_x[i] * adjusted_points_x[i] + adjusted_points_x[i] * adjusted_points_x[j] + adjusted_points_x[j] * adjusted_points_x[j]) / 6 * temp;
              i_xy += (2 * adjusted_points_x[i] * adjusted_points_y[i] + adjusted_points_x[i] * adjusted_points_y[j] + adjusted_points_x[j] * adjusted_points_y[i] + 2 * adjusted_points_x[j] * adjusted_points_y[j]) / 12 * temp;
            
            end
            
            # Calculate Radii of gyration
            rgyr_x = Math.sqrt(i_x / area)
            rgyr_y = Math.sqrt(i_y / area)
            
            # Calculate perimeter
            perim = 0
            a_face.edges.each do |edge|
              perim += edge.length
            end
            
            # Figure out the unit system
            fa = Sketchup.format_area(area)
            unit = "Inches"
            mult = 1.0            
            if fa.include? "Meters"
               unit = "Meters"
               mult = 39.3700787
            elsif fa.include? "Centimeters"
               unit = "Centimeters"
               mult = 0.393700787  
            elsif fa.include? "Millimeters"
               unit = "Millimeters"
               mult = 0.0393700787 
            elsif fa.include? "Feet"
               unit = "Feet"
               mult = 12               
            end
            
            # Now display values in model units
            f_values =  "Face properties (in current model units):\n\n" +
                        "Centroid: " + sprintf( "%.4f, %.4f, %.4f (x,y,z %s from origin)" , 
                            centroid.x / mult , centroid.y / mult, centroid.z / mult, unit ) + "\n" +
                        "Area = " + sprintf( "%.4f %s^2" , area / mult**2 , unit ) + "\n" +
                        "Perimeter = " + sprintf( "%.4f %s" , perim / mult , unit ) + "\n" +
                        "Ix = " + sprintf( "%.4f %s^4" , i_x / mult**4 , unit ) + "\n" +
                        "Iy = " + sprintf( "%.4f %s^4" , i_y / mult**4 , unit ) + "\n" +
                        "Ixy = " + sprintf( "%.4f %s^4" , i_xy / mult**4 , unit ) + "\n" +
                        "rx = " + sprintf( "%.4f %s" , rgyr_x / mult , unit ) + "\n" +
                        "ry = " + sprintf( "%.4f %s" , rgyr_y / mult , unit ) + "\n\n" +
                        "Copy values now if needed!"
            UI.messagebox f_values, MB_MULTILINE, "Face Properties"
            
            # Send the centroid back as a 3D point
            return centroid 
        
        end
      
    end # calculate_centroid
    
    
    # =========================================
    
    
    def self.get_centroid
    
        # Get currently selected objects
        sel = @mod.selection
        vector = Geom::Vector3d.new
        
        if sel.empty?
        
            UI.messagebox 'Please select at least one face.'
            
        else
        
        # Do this for each face in the selection set seperately
        sel.each {|e|
        
            if e.is_a? Sketchup::Face
          
                # Flip upside-down face up first and don't use non-flat planes
                if e.normal.samedirection? [0,0,-1]
                    UI.messagebox "I need to flip this face (white side up) for a correct calculation."
                    e.reverse!
                elsif !e.normal.samedirection? [0,0,1]
                    UI.messagebox "Sorry, but the face must be parallel to the ground for this calculation."
                    break
                end
                
                # Calculate centroid
                centroid = calculate_centroid(e)
                
                # Draw a construction point and axis lines at centroid
                if (centroid != false) 
                  
                    click = UI.messagebox "Draw crosshair at centroid location?", MB_YESNO
                    if (click == 6) 
                
                        # Get a size reference for lengths: 20% of diagonal
                        len = e.bounds.diagonal / 5
                        
                        # Group construction geometry
                        @mod.start_operation 'Draw centroid'
                        group = @mod.entities.add_group
                        group.entities.add_cpoint(centroid)
                        group.entities.add_cline centroid.offset(X_AXIS, -len), centroid.offset(X_AXIS, len)
                        group.entities.add_cline centroid.offset(Y_AXIS, -len), centroid.offset(Y_AXIS, len)
                        @mod.commit_operation
                    
                    end
                    
                end
                
            end
          
        }
        
        end
    
    end # get_centroid
    
    
    # =========================================
    
    
    def self.contains_face
    # Check if face is in selection set and flat on the ground - for context menu
    
        contains = false
        @mod.selection.each {|e|
            contains = true if ((e.is_a? Sketchup::Face) and (e.normal.parallel? [0,0,1]))
        }
        return contains
      
    end # contains_face   
    
    
    # =========================================
    
    
    # Load plugin at startup and add menu items to context menu
    if !file_loaded?(__FILE__)
      
        # Add to the context menu
        UI.add_context_menu_handler do |menu|
            if( AS_FaceCentroid::contains_face )
                menu.add_item("Get Face Properties") { AS_FaceCentroid::get_centroid }
            end
        end
        
        # Let Ruby know we have loaded this file
        file_loaded(__FILE__)
    
    end # if
    
    # =========================================    
    
    
end # AS_FaceCentroid    
