=begin

Copyright 2008-2014, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/centroid-and-area-properties-plugin-for-sketchup/

Name :          Face Centroid

Version:        1.3
Date :          3/5/2014

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


    # Use a counter for number of selected faces
    @count = 0
  
    
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
                        
            # Get the unit label
            unit = Sketchup.format_area(1)[/[a-zA-Z]+/]              
            
            # Figure out the unit system       
            # Get the inch conversion factor - not precise enough!!!
            # mult = 1 / ( Sketchup.format_length(1)[/([0-9]+)(.|,)([0-9]+)*/].to_f )
            if (['ft', 'feet', 'foot'].include? unit.downcase)
                mult = 12.0
            elsif (['m', 'meters', 'meter'].include? unit.downcase)
                mult = 1 / 2.54 * 100
            elsif (['cm', 'centimeters', 'centimeter'].include? unit.downcase)
                mult = 1 / 2.54
            elsif (['mm', 'millimeters', 'millimeter'].include? unit.downcase)
                mult = 1 / 25.4           
            else
                mult = 1.0
                unit = 'in'
            end                                  
            
            # Now display values in model units
            f_values =  "Face properties (in current model units):\n\n" +
                        "Centroid: " + sprintf( "%.4f, %.4f, %.4f (x,y,z %s from origin)" , 
                            centroid.x / mult , centroid.y / mult, centroid.z / mult, unit ) + "\n" +
                        "Area = " + sprintf( "%.4f %s^2" , area.abs / mult**2 , unit ) + "\n" +
                        "Perimeter = " + sprintf( "%.4f %s" , perim.abs / mult , unit ) + "\n" +
                        "Ix = " + sprintf( "%.4f %s^4" , i_x.abs / mult**4 , unit ) + "\n" +
                        "Iy = " + sprintf( "%.4f %s^4" , i_y.abs / mult**4 , unit ) + "\n" +
                        "Ixy = " + sprintf( "%.4f %s^4" , i_xy.abs / mult**4 , unit ) + "\n" +
                        "rx = " + sprintf( "%.4f %s" , rgyr_x.abs / mult , unit ) + "\n" +
                        "ry = " + sprintf( "%.4f %s" , rgyr_y.abs / mult , unit ) + "\n\n" +
                        "Copy values now if needed!"
            UI.messagebox f_values, MB_MULTILINE, "Face Properties"
            
            # Send the centroid back as a 3D point
            return centroid 
        
        end
      
    end # calculate_centroid
    
    
    # =========================================
    
    
    def self.get_centroid
    
        if @count > 10 then
        
            UI.messagebox "You have #{@count} faces selected. For efficiency, this tool only works with max. 10 selected faces at a time."
        
        else
    
            # Get currently selected objects
            mod = Sketchup.active_model
            sel = mod.selection
            vector = Geom::Vector3d.new
            
            if sel.empty?
            
                UI.messagebox 'Please select at least one face.'
                
            else
            
            # Do this for each face in the selection set seperately
            sel.each {|e|
            
                if e.is_a? Sketchup::Face

                    # Skip non-flat surfaces
                    if !e.normal.parallel? [0,0,1]
                    
                        UI.messagebox "Skipping a face that is not parallel to the ground."

                    else
                    
                        # Calculate centroid
                        centroid = calculate_centroid(e)
                        
                        # Draw a construction point and axis lines at centroid
                        if (centroid != false) 
                          
                            click = UI.messagebox "Draw crosshair at centroid location?", MB_YESNO
                            if (click == 6) 
                        
                                # Get a size reference for lengths: 20% of diagonal
                                len = e.bounds.diagonal / 5
                                
                                # Group construction geometry
                                mod.start_operation 'Draw centroid'
                                group = mod.entities.add_group
                                group.entities.add_cpoint(centroid)
                                group.entities.add_cline centroid.offset(X_AXIS, -len), centroid.offset(X_AXIS, len)
                                group.entities.add_cline centroid.offset(Y_AXIS, -len), centroid.offset(Y_AXIS, len)
                                mod.commit_operation
                            
                            end
                            
                        end
                    
                    end
                    
                end
              
            }
            
            end
            
        end
    
    end # get_centroid
    
    
    # =========================================
    
    
    def self.contains_face
    # Check if face is in selection set and flat on the ground - for context menu
    # Also returns number of selected faces
    
        contains = false
        @count = 0
        mod = Sketchup.active_model
        mod.selection.each {|e|
            if ((e.is_a? Sketchup::Face) and (e.normal.parallel? [0,0,1]))
                contains = true 
                @count = @count + 1
            end
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
