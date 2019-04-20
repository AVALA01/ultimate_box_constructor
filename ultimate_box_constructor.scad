//////////////////////////////////////////////////////////
////****MAIN SETTINGS****/////////////////////////////////
//////////////////////////////////////////////////////////

//quality
$fn = 32;

//0 - no lid
//1 - yes lid
lid = 1;
lid_size_ratio = 0.3;

//size of box in milimeters(openSCAD is unitless, so scale if needed)
overall_size_x = 100;
overall_size_y = 100;
overall_size_z = 100;

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
                        [ [0.5, 0.5],   90,             200,       1 ],
                        [ [0.5, 0.5],   0 ,             200,       0.9 ]
                    ];

//////////////////////////////////////////////////////////////////
////****ADVANCED SETTINGS****/////////////////////////////////////
//////////////////////////////////////////////////////////////////

//gap between body and lid
lid_gap = 0.5;

//box type 0 properties
body_roundness_reducer_multiplyer = 1;

//////////////////////////////////////////////////////////////////
////****PRE CALCULATION****///////////////////////////////////////
//////////////////////////////////////////////////////////////////

body_size_x = overall_size_x;
body_size_y = overall_size_y;
body_size_z = lid ? overall_size_z - roundness*body_roundness_reducer_multiplyer : overall_size_z;

body_internal_size_x = body_size_x - roundness*2;
body_internal_size_y = body_size_y - roundness*2;
body_internal_size_z = body_size_z - wall_thickness;

body_internal_space = [0, 0, wall_thickness];

lid_size_x = overall_size_x + wall_thickness*2 + lid_gap;
lid_size_y = overall_size_y + wall_thickness*2 + lid_gap;
lid_size_z = overall_size_z*lid_size_ratio;

lid_shift = [(overall_size_x)*1.5, 0, 0];
//lid_shift = [0, 0, 0];

//////////////////////////////////////////////////////////////////
////****EXECUTION PART*****///////////////////////////////////////
//////////////////////////////////////////////////////////////////

//body cube with roundness
module rounded_cube(__x, __y, __z, __r){
    translate([0, 0, __r]){
        minkowski(){
            translate([0, 0, (__z*1.1+__r)/2]){
                    cube([__x - __r*2,
                  __y - __r*2,
                  __z*1.1+__r], center=true);
            }
            roundness_object();
        }
    }
}

module inverse_rounded_cube(__x, __y, __z, __r){
    difference(){
        cube(__x*4, __y*4, __z*4, center = true);
        rounded_cube(__x, __y, __z, __r);
    }
}

module top_cut(__x, __y, __z){
    translate([0, 0, __z]){
        _z_size = __z*2;

        translate ([0,0, (_z_size)/2]) cube([__x*3, __y*3, _z_size], center=true);
    }
}

module internal_sections(__internal_sections){
    for (s = __internal_sections){
        if (s[0] != undef){
            echo(body_internal_size_z);
            section_height = body_internal_size_z*s[3];
            section_width = internal_sections_thickness;
            section_length = s[2];
            difference(){
                translate(body_internal_space){
                    rotate(a = s[1], v = [0,0,1]){
                        translate([0, 0, section_height/2]) {
                            cube([section_length, section_width, section_height], center = true);
                        }
                    }
                }
                union(){
                    top_cut(body_size_x, body_size_y, body_size_z);
                    inverse_rounded_cube(body_size_x, body_size_y, body_size_z, roundness);
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

module cup(x, y, z, shift = [0, 0, 0]){
    translate(shift){
        difference(){
            difference(){
                rounded_cube(x, y, z, roundness);
                top_cut(x, y, z);
            }
            //inside cut
            translate([0, 0, wall_thickness]){
                translate([0, 0, roundness+(z*1.1+roundness - wall_thickness*2)/2]){
                    minkowski(){
                        cube([x - roundness*2 - wall_thickness*2,
                              y - roundness*2 - wall_thickness*2,
                              z*1.1+roundness - wall_thickness*2], center=true);
                        roundness_object();
                    }
                }
            }
        }
    }
}

//body
//cup(body_size_x, body_size_y, body_size_z);

//lid
//if (lid==1){
//    cup(lid_size_x, lid_size_y, lid_size_z, lid_shift);
//}

//internal sections
//internal_sections(internal_sections);

rounded_cube(100, 100, 100, 5);

//top_cut(body_size_x, body_size_y, body_size_z);