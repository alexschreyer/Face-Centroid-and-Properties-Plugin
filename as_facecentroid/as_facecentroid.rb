# =========================================
# Main file for Face Centroid
# Copyright Alexander C. Schreyer
# =========================================


require 'sketchup'


# =========================================


module AS_Extensions

  module AS_FaceCentroid


      # General variables
      @f_values = ''


      # =========================================


      def self.calculate_centroid (a_face)
      # Do the math and display the results - returns the centroid or false

          # Get all the vertices for the current face
          vertices = a_face.vertices

          if (vertices.length < 3)

              UI.messagebox "Invalid face detected. Can't calculate centroid for this face."
              return false

          elsif (a_face.vertices.length != a_face.outer_loop.vertices.length)

              UI.messagebox "Face with internal hole detected. Draw a single connecting line between each hole and the face perimeter before using this tool."
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

              # Get the unit label (base on area format because of face)
              unit = Sketchup.format_area(1)[/[a-zA-Z]+/]

              # Figure out the unit system
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

              # Now update values in model units
              @f_values =   "Face properties (in current model units):\n\n" +
                            "Centroid = " + sprintf( "[%.4f,%.4f,%.4f] (x,y,z %s from origin)" ,
                                centroid.x / mult , centroid.y / mult, centroid.z / mult, unit ) + "\n" +
                            "Area = " + sprintf( "%.4f %s^2" , area.abs / mult**2 , unit ) + "\n" +
                            "Perimeter = " + sprintf( "%.4f %s" , perim.abs / mult , unit ) + "\n" +
                            "Ix = " + sprintf( "%.4f %s^4" , i_x.abs / mult**4 , unit ) + "\n" +
                            "Iy = " + sprintf( "%.4f %s^4" , i_y.abs / mult**4 , unit ) + "\n" +
                            "Ixy = " + sprintf( "%.4f %s^4" , i_xy.abs / mult**4 , unit ) + "\n" +
                            "rx = " + sprintf( "%.4f %s" , rgyr_x.abs / mult , unit ) + "\n" +
                            "ry = " + sprintf( "%.4f %s" , rgyr_y.abs / mult , unit )

              # Send the centroid back as a 3D point
              return centroid

          end

      end # calculate_centroid


      # =========================================


      def self.get_centroid
      
          mod = Sketchup.active_model
          faces = mod.selection.grep(Sketchup::Face)

          if faces.empty?

              UI.messagebox "Select at least one ungrouped face to use this tool."
                  
          else if faces.length > 50 then

              UI.messagebox "You have #{faces.length} faces selected. For efficiency, this tool only works with max. 50 selected faces at a time. Reduce selection and restart."

          else
          
              drawres = UI.messagebox "Draw crosshairs at centroid locations?", MB_YESNO
              nonplane = 0

              # Do this for each face in the selection set seperately
              faces.each { |e|

                  # Skip non-flat surfaces
                  if !e.normal.parallel? [0,0,1]
                  
                      nonplane = nonplane + 1

                  else

                      # Calculate centroid
                      centroid = calculate_centroid(e)

                      # Draw information, a construction point and axis lines at centroid
                      if (centroid != false)
                      
                          mod.start_operation 'Draw centroid'
                          clayer = mod.layers.add('Centroids')
                          
                          # Get a size reference for lengths: 20% of diagonal
                          len = e.bounds.diagonal / 5
                      
                          # Draw text information
                          txt = mod.entities.add_text( @f_values, centroid, [0,0,len] )
                          txt.layer = clayer
                          
                          # Draw crosshairs
                          if drawres == 6

                              # Group construction geometry and create on own layer
                              group = mod.entities.add_group
                              group.layer = clayer
                              group.entities.add_cpoint(centroid)
                              group.entities.add_cline centroid.offset(X_AXIS, -len), centroid.offset(X_AXIS, len)
                              group.entities.add_cline centroid.offset(Y_AXIS, -len), centroid.offset(Y_AXIS, len)

                          end
                          
                          mod.commit_operation

                      end

                  end

              }
              
              end
              
              UI.messagebox "This tool only works on faces that are parallel to the ground (the red-green or x-y plane). Skipped #{nonplane.to_s} faces that were not parallel to the ground." if nonplane > 0

          end

      end # get_centroid


      # =========================================
      
      
      def self.show_url( title , url )
      # Show website either as a WebDialog or HtmlDialog

        if Sketchup.version.to_f < 17 then   # Use old dialog
          @dlg = UI::WebDialog.new( title , true ,
            title.gsub(/\s+/, "_") , 1000 , 600 , 100 , 100 , true);
          @dlg.navigation_buttons_enabled = false
          @dlg.set_url( url )
          @dlg.show      
        else   #Use new dialog
          @dlg = UI::HtmlDialog.new( { :dialog_title => title, :width => 1000, :height => 600,
            :style => UI::HtmlDialog::STYLE_DIALOG, :preferences_key => title.gsub(/\s+/, "_") } )
          @dlg.set_url( url )
          @dlg.show
          @dlg.center
        end  

      end  

      def self.show_help
      # Show the website as an About dialog

        show_url( "#{@exttitle} - Help" , 'https://alexschreyer.net/projects/centroid-and-area-properties-plugin-for-sketchup/' )

      end # show_help
    
    
      # =========================================    


      # Load plugin at startup and add menu items to context menu
      if !file_loaded?(__FILE__)
      
          # Add to the tools menu
          tmenu = UI.menu("Tools").add_submenu( @exttitle )
          tmenu.add_item("Get Face Properties") { self.get_centroid }
          tmenu.add_item("Help") { self.show_help }      

          # Add to the context menu
          UI.add_context_menu_handler do |menu|
              if( !Sketchup.active_model.selection.grep(Sketchup::Face).empty? )
                  menu.add_item("Get Face Properties") { self.get_centroid }
              end
          end

          # Let Ruby know we have loaded this file
          file_loaded(__FILE__)

      end # if

      # =========================================


  end # module AS_FaceCentroid

end # module AS_Extensions


# =========================================
