////////////////////////////////////////////////////////////////////////////////////////////////////
////****MAIN SETTINGS****///////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

//quality
$fn = 32;

//0 - no lid
//1 - yes lid
lid = 1;
lid_size_ratio = 0.3;

//size of box in milimeters(openSCAD is unitless, so scale if needed)
body_size_x = 100;
body_size_y = 100;
body_size_z = 100;

wall_thickness = 2; //wall thickness in cm

roundness = 5; //roundness of the box

//0 - whole
//1 - horizontal
//2 - x aligned
//3 - y aligned
roundness_type = 0;

internal_sections_thickness = 2; //internal sections thickness

internal_sections = [ 
                    //relative        | angle        | length  |relative |
                    //coordinates     | around z     | of the  | height  |
                    //of the middle   | (by default  | section |         |
                    //of the section  | sections are |         |         |
                    //                | alligned     |         |         |
                    //                | with x)      |         |         |
                        [ [0.5, 0.5],   90,             200,        1 ],
                        [ [0.7, 0.7],   10 ,             10,       0.5 ]
                    ];

////////////////////////////////////////////////////////////////////////////////////////////////////
////****ADVANCED SETTINGS****///////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

//gap between body and lid
lid_gap = 0.5;

//box type 0 properties
body_roundness_reducer_multiplyer = 1;

////////////////////////////////////////////////////////////////////////////////////////////////////
////****PRE CALCULATION****/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
body_internal_size_x = body_size_x - wall_thickness*2;
body_internal_size_y = body_size_y - wall_thickness*2;
body_internal_size_z = body_size_z - wall_thickness;

main_body_internal_center = [body_internal_size_x/2.0,
                             body_internal_size_y/2.0,
                             body_internal_size_z/2.0];

lid_size_x = body_size_x + wall_thickness*2 + lid_gap;
lid_size_y = body_size_y + wall_thickness*2 + lid_gap;
lid_size_z = body_size_z*lid_size_ratio;

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

module inverse_rounded_cube(_x, _y, _z, _r){
    difference(){
        cube(_x*5, _y*5, _z*5, center = true);
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
            __section_width = internal_sections_thickness;
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
           rounded_cube(_x - wall_thickness*2, _y - wall_thickness*2, _z*1.1+roundness - wall_thickness*2, roundness);
        }
    }
}

//body
main_body_space() {
    cup(body_size_x, body_size_y, body_size_z);
}

lid_space(){
    if (lid==1){
        cup(lid_size_x, lid_size_y, lid_size_z);
    }
}

main_body_internal_space(){
    internal_sections(internal_sections);
}