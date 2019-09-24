//include <lib/simple_box.scad>;
//x();
//i = 10;

////****MAIN SETTINGS****///////////////////////////////////////////////////////////////////////////
//////////////////////////////

//quality
$fn = 32;

create_lid = 1;     //0 - don't create lid;   1 - create lid
create_body = 1;    //0 - don't create body; 1 - create body
create_latches = 0; //0 - don't create latches; 1 - create latches

body_size_x = 142; //size of box in milimeters(openSCAD is unitless, so scale if needed)
body_size_y = 72; //internal space of the box will be: size - wall_thickness*2
body_size_z = 72;

wall_thickness = 1; //wall thickness in mm


roundness = 0; //roundness of the box in mm

//0 - sphere
//1 - z axis cylinder
//2 - x axis cylinder
//3 - y axis cylinder
roundness_type = 0;


////////////////////////////////////////////////////////////////////////////////////////////////////
////****INTERNAL SECTIONS****///////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

internal_sections_thickness = 1; //internal sections thickness

internal_sections = [
                    //relative        | angle        | length  |relative | thicknes |
                    //coordinates     | around z     | of the  | height  | of the   |
                    //of the middle   | (by default  | section |         | section  |
                    //of the section  | sections are |         |         |          |
                    //                | alligned     |         |         |          |
                    //                | with x)      |         |         |          |
                      [ [0.5, 0.5],   0,             200,       1,         10],
                      [ [0.5, 0.5],   90,             200,      1,         5],
                      [ [0.5, 0.5],   45,             200,      1],
                    //  [ [0.7, 0.7],   10 ,             10,       0.5 ]
                    ];

////////////////////////////////////////////////////////////////////////////////////////////////////
////****ADVANCED SETTINGS****///////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

//z size of the lid in relation to the body
lid_size_ratio = 0.10;

//horizontal gap between body and lid in mm
lid_gap = 0.50;

//box type 0 properties
body_roundness_reducer_multiplyer = 1;

//latch dimensions
latch_height = 0.5;
latch_width = 2;

////////////////////////////////////////////////////////////////////////////////////////////////////
////****PRE CALCULATIONS****/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
body_internal_size_x = body_size_x - wall_thickness*2;
body_internal_size_y = body_size_y - wall_thickness*2;
body_internal_size_z = body_size_z - wall_thickness;

main_body_internal_center = [body_internal_size_x/2.0,
                             body_internal_size_y/2.0,
                             body_internal_size_z/2.0];
                             
lid_wall_height = body_size_z*lid_size_ratio;

lid_size_x = body_size_x + wall_thickness*2 + lid_gap;
lid_size_y = body_size_y + wall_thickness*2 + lid_gap;
lid_size_z = lid_wall_height + roundness + wall_thickness;

//latch
body_latch_z = body_size_z - (lid_wall_height)/2.0 + latch_width/4.0;
body_latch_x = (body_size_x- roundness*2)/2.0;
body_latch_y = (body_size_y- roundness*2)/2.0;

lid_latch_z = (roundness + wall_thickness) + (lid_wall_height)/2.0 + latch_width/4.0;
lid_latch_x = body_latch_x;
lid_latch_y = body_latch_y;
////////////////////////////////////////////////////////////////////////////////////////////////////
////****SPACES****//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

module main_body_space(){
    translate([wall_thickness+lid_gap, wall_thickness+lid_gap, 0]){
        children();
    }
}

module lid_space(){
    translate([(body_size_x)*1.5, 0, 0]){
        children();
    }
}

module main_body_internal_space(){
    main_body_space(){
        translate([wall_thickness, wall_thickness, wall_thickness]){
            children();
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////****MODULES****/////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

//creating latch
module latch(_position, _length, _orientation){
    translate(_position){
        rotate(a = _orientation, v = [0, 0, 1]){
            translate([-_length/2.0, 0, 0]){
                translate([0, 0, -latch_width/2.0]){
                    rotate(a = 180, v = [1,0,0]){
                        rotate(a = 90, v = [0,1,0]){
                            linear_extrude(height = _length) polygon([[0, 0], [latch_width, 0], [latch_width/2.0, latch_height]]);
                        }
                    }
                }
            }
        }
   }

}

//body cube with roundness
module rounded_cube(_x, _y, _z, _r){
    translate([_r, _r, _r]){
        minkowski(){
            cube([_x-_r*2,
                  _y-_r*2,
                  _z-_r*2]);
            roundness_object();
        }
    }
}

module inverse_rounded_cube(_x, _y, _z, _r, _multiplier = 15){
    difference(){
        cube(_x*_multiplier, _y*_multiplier, _z*_multiplier, center = true);
        rounded_cube(_x, _y, _z, _r);
    }
}

module top_cut(_x, _y, _z){
    translate([0, 0, _z]){
        __z_size = _z*2;
        translate ([0,0, (__z_size)/2]) cube([_x*3, _y*3, __z_size], center=true);
    }
}

module internal_sections(){
    for (__s = internal_sections){
        if (__s[0] != undef){
            __section_length = __s[2];
            __section_width = ( (__s[4]==undef) ?  internal_sections_thickness : __s[4]);
            __section_height = body_internal_size_z*__s[3];
            difference(){
                __section_center = [__section_length/2.0, __section_width/2.0];
                translate([body_internal_size_x*__s[0][0],
                           body_internal_size_y*__s[0][1],
                           0] - __section_center){
                    translate([__section_center.x, __section_center.y, __section_height/2.0]){
                        rotate(a = __s[1], v = [0,0,1]){
                            cube([__section_length, __section_width, __section_height], center = true);
                        }
                    }
                }
                union(){
                    top_cut(body_size_x, body_size_y, body_size_z);
                    inverse_rounded_cube(body_internal_size_x,
                                         body_internal_size_y,
                                         body_internal_size_z*1.1+roundness, roundness);
                }
            }
        }
    }
}

module roundness_object(){
    if (roundness_type == 0){
        sphere(roundness);
    }
    else if (roundness_type == 1){
        cylinder(h = roundness*2, r = roundness, center = true);
    }
    else if (roundness_type == 2){
        rotate(a = 90, v = [1,0,0]){
            cylinder(h = roundness*2, r = roundness, center = true);
        }
    }
    else if (roundness_type == 3){
        rotate(a = 90, v = [0,1,0]){
            cylinder(h = roundness*2, r = roundness, center = true);
        }
    }
}

module cup(_x, _y, _z){
    difference(){
        difference(){
           rounded_cube(_x, _y, _z*1.1+roundness, roundness);
           top_cut(_x, _y, _z);
        }
        //inside cut
        translate([wall_thickness, wall_thickness, wall_thickness]){
           rounded_cube(_x - wall_thickness*2, _y - wall_thickness*2, _z*1.1+roundness, roundness);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////****EXECUTION PART****/////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

if (create_body){
    //body
    main_body_space() {
        cup(body_size_x, body_size_y, body_size_z);
    }

    main_body_internal_space(){
        internal_sections(internal_sections);
    }

//body latches

//body 
//0,y/2 latch

    if (create_latches){
        
        main_body_space(){
            latch([0, body_size_y/2.0, body_latch_z], body_latch_x, 270);
        }
        
        //x/2,0 latch
        main_body_space(){
            latch([body_size_x/2.0, 0, body_latch_z], body_latch_x, 0);
        }

        //x/2,y latch
        main_body_space(){
            latch([body_size_x/2.0, body_size_y, body_latch_z], body_latch_x, 180);
        }

        //x,y/2 latch
        main_body_space(){
            latch([body_size_x, body_size_y/2.0, body_latch_z], body_latch_x, 90);
        }
        
    }
}

//lid
if (create_lid==1){
    
    lid_space(){
        cup(lid_size_x, lid_size_y, lid_size_z);
    }
    
    //lid latches
    if (create_latches){
        
        //0,y/2 latch
        lid_space(){
            latch([0 + wall_thickness, body_size_y/2.0, lid_latch_z], lid_latch_x, 90);
        }
        
        //x/2,0 latch
        lid_space(){
            latch([lid_size_x/2.0, wall_thickness, lid_latch_z], lid_latch_x, 180);
        }
        
        //x/2,y latch
        lid_space(){
            latch([lid_size_x/2.0, lid_size_y - wall_thickness, lid_latch_z], body_latch_x, 0);
        }
        
        //x,y/2 latch
        lid_space(){
            latch([lid_size_x - wall_thickness, lid_size_y/2.0, lid_latch_z], lid_latch_x, 270);
        }
    }
    
}