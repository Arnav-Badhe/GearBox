$fn = 100;
/*
Permitted modules according to DIN 780:
0.05 0.06 0.08 0.10 0.12 0.16
0.20 0.25 0.3  0.4  0.5  0.6
0.7  0.8  0.9  1    1.25 1.5
2    2.5  3    4    5    6
8    10   12   16   20   25
32   40   50   60

*/


// General Variables
pi = 3.14159;
rad = 57.29578;
clearance = 0.05;   // clearance between teeth

/*  Converts Radians to Degrees */
function grad(pressure_angle) = pressure_angle*rad;

/*  Converts Degrees to Radians */
function radian(pressure_angle) = pressure_angle/rad;

/*  Converts 2D Polar Coordinates to Cartesian
    Format: radius, phi; phi = Angle to x-Axis on xy-Plane */
function polar_to_cartesian(polvect) = [
    polvect[0]*cos(polvect[1]),
    polvect[0]*sin(polvect[1])
];

/*  Circle Involutes-Function:
    Returns the Polar Coordinates of an Involute Circle
    r = Radius of the Base Circle
    rho = Rolling-angle in Degrees */
function ev(r,rho) = [
    r/cos(rho),
    grad(tan(rho)-radian(rho))
];

/*  Sphere-Involutes-Function
    Returns the Azimuth Angle of an Involute Sphere
    theta0 = Polar Angle of the Cone, where the Cutting Edge of the Large Sphere unrolls the Involute
    theta = Polar Angle for which the Azimuth Angle of the Involute is to be calculated */
function sphere_ev(theta0,theta) = 1/sin(theta0)*acos(cos(theta)/cos(theta0))-acos(tan(theta0)/tan(theta));

/*  Converts Spherical Coordinates to Cartesian
    Format: radius, theta, phi; theta = Angle to z-Axis, phi = Angle to x-Axis on xy-Plane */
function sphere_to_cartesian(vect) = [
    vect[0]*sin(vect[1])*cos(vect[2]),
    vect[0]*sin(vect[1])*sin(vect[2]),
    vect[0]*cos(vect[1])
];

/*  Check if a Number is even
    = 1, if so
    = 0, if the Number is not even */
function is_even(number) =
    (number == floor(number/2)*2) ? 1 : 0;

/*  greatest common Divisor
    according to Euclidean Algorithm.
    Sorting: a must be greater than b */
function ggt(a,b) =
    a%b == 0 ? b : ggt(b,a%b);

/*  Polar function with polar angle and two variables */
function spiral(a, r0, phi) =
    a*phi + r0;

/*  Copy and rotate a Body */
module copier(vect, number, distance, winkel){
    for(i = [0:number-1]){
        translate(v=vect*distance*i)
            rotate(a=i*winkel, v = [0,0,1])
                children(0);
    }
}
module bevel_herringbone_gear_pair(modul, gear_teeth, pinion_teeth, axis_angle=90, tooth_width, gear_bore, pinion_bore, pressure_angle = 20, helix_angle=10, together_built=true){

    r_gear = modul*gear_teeth/2;                           // Cone Radius of the Gear
    delta_gear = atan(sin(axis_angle)/(pinion_teeth/gear_teeth+cos(axis_angle)));   // Cone Angle of the Gear
    delta_pinion = atan(sin(axis_angle)/(gear_teeth/pinion_teeth+cos(axis_angle)));// Cone Angle of the Pinion
    rg = r_gear/sin(delta_gear);                              // Radius of the Large Sphere
    c = modul / 6;                                          // Tip Clearance
    df_pinion = pi*rg*delta_pinion/90 - 2 * (modul + c);    // Bevel Diameter on the Large Sphere
    rf_pinion = df_pinion / 2;                              // Root Cone Radius on the Large Sphere
    delta_f_pinion = rf_pinion/(pi*rg) * 180;               // Tip Cone Angle
    rkf_pinion = rg*sin(delta_f_pinion);                    // Radius of the Cone Foot
    height_f_pinion = rg*cos(delta_f_pinion);                // Height of the Cone from the Root Cone

    echo("Cone Angle Gear = ", delta_gear);
    echo("Cone Angle Pinion = ", delta_pinion);

    df_gear = pi*rg*delta_gear/90 - 2 * (modul + c);          // Bevel Diameter on the Large Sphere
    rf_gear = df_gear / 2;                                    // Root Cone Radius on the Large Sphere
    delta_f_gear = rf_gear/(pi*rg) * 180;                     // Tip Cone Angle
    rkf_gear = rg*sin(delta_f_gear);                          // Radius of the Cone Foot
    height_f_gear = rg*cos(delta_f_gear);                      // Height of the Cone from the Root Cone

    echo("Gear Height = ", height_f_gear);
    echo("Pinion Height = ", height_f_pinion);

    rotate = is_even(pinion_teeth);

    // Gear
    rotate([0,0,180*(1-clearance)/gear_teeth*rotate])
        bevel_herringbone_gear(modul, gear_teeth, delta_gear, tooth_width, gear_bore, pressure_angle, helix_angle);
		pionz = height_f_gear-height_f_pinion*sin(90-axis_angle);
    // Pinion
    if (together_built)
	echo("pinon z: ",pionz)
        translate([-height_f_pinion*cos(90-axis_angle),0,height_f_gear-height_f_pinion*sin(90-axis_angle)])
            rotate([0,axis_angle,0])
                bevel_herringbone_gear(modul, pinion_teeth, delta_pinion, tooth_width, pinion_bore, pressure_angle, -helix_angle);
    else
		echo("pinon z: ",rkf_pinion*2+modul+rkf_gear)
        translate([rkf_pinion*2+modul+rkf_gear,0,0])
            bevel_herringbone_gear(modul, pinion_teeth, delta_pinion, tooth_width, pinion_bore, pressure_angle, -helix_angle);

}
module bevel_herringbone_gear(modul, tooth_number, partial_cone_angle, tooth_width, bore, pressure_angle = 20, helix_angle=0){

    // Dimension Calculations

    tooth_width = tooth_width / 2;

    d_outside = modul * tooth_number;                                // Part Cone Diameter at the Cone Base,
                                                                // corresponds to the Chord in a Spherical Section
    r_outside = d_outside / 2;                                    // Part Cone Radius at the Cone Base
    rg_outside = r_outside/sin(partial_cone_angle);                  // Large-Cone Radius, corresponds to the Length of the Cone-Flank;
    c = modul / 6;                                              // Tip Clearance
    df_outside = d_outside - (modul +c) * 2 * cos(partial_cone_angle);
    rf_outside = df_outside / 2;
    delta_f = asin(rf_outside/rg_outside);
    height_f = rg_outside*cos(delta_f);                           // Height of the Cone from the Root Cone

    // Torsion Angle gamma from Helix Angle
    gamma_g = 2*atan(tooth_width*tan(helix_angle)/(2*rg_outside-tooth_width));
    gamma = 2*asin(rg_outside/r_outside*sin(gamma_g/2));

    echo("Part Cone Diameter at the Cone Base = ", d_outside);

    // Sizes for Complementary Truncated Cone
    height_k = (rg_outside-tooth_width)/cos(partial_cone_angle);      // Height of the Complementary Cone for corrected Tooth Length
    rk = (rg_outside-tooth_width)/sin(partial_cone_angle);           // Foot Radius of the Complementary Cone
    rfk = rk*height_k*tan(delta_f)/(rk+height_k*tan(delta_f));    // Tip Radius of the Cylinders for
                                                                // Complementary Truncated Cone
    height_fk = rk*height_k/(height_k*tan(delta_f)+rk);            // height of the Complementary Truncated Cones

    modul_inside = modul*(1-tooth_width/rg_outside);

        union(){
        bevel_gear(modul, tooth_number, partial_cone_angle, tooth_width, bore, pressure_angle, helix_angle);        // bottom Half
        translate([0,0,height_f-height_fk])
            rotate(a=-gamma,v=[0,0,1])
                bevel_gear(modul_inside, tooth_number, partial_cone_angle, tooth_width, bore, pressure_angle, -helix_angle); // top Half
    }
}
 module genrateCollar(collar_height,collar_width,collar_radius,hole_Radius,hole_offset){
	 
		difference () {
                cylinder (r=collar_radius+collar_width, h=collar_height, center=false);
                    translate ([0,0,-1]) {
					shaft(collar_height+2);
                    }
				translate ([0,0,collar_height-hole_offset]) {
					rotate([90,0,90]){
					cylinder (r=hole_Radius, h=2*(collar_radius+collar_width)+2, center=true);
					}
				}
                }
	 }
 module bevel_gear(modul, tooth_number, partial_cone_angle, tooth_width, bore, pressure_angle = 20, helix_angle=0) {

    // Dimension Calculations
    d_outside = modul * tooth_number;                                    // Part Cone Diameter at the Cone Base,
                                                                    // corresponds to the Chord in a Spherical Section
    r_outside = d_outside / 2;                                        // Part Cone Radius at the Cone Base
    rg_outside = r_outside/sin(partial_cone_angle);                      // Large-Cone Radius for Outside-Tooth, corresponds to the Length of the Cone-Flank;
    rg_inside = rg_outside - tooth_width;                              // Large-Cone Radius for Inside-Tooth
    r_inside = r_outside*rg_inside/rg_outside;
    alpha_spur = atan(tan(pressure_angle)/cos(helix_angle));// Helix Angle in Transverse Section
    delta_b = asin(cos(alpha_spur)*sin(partial_cone_angle));          // Base Cone Angle
    da_outside = (modul <1)? d_outside + (modul * 2.2) * cos(partial_cone_angle): d_outside + modul * 2 * cos(partial_cone_angle);
    ra_outside = da_outside / 2;
    delta_a = asin(ra_outside/rg_outside);
    c = modul / 6;                                                  // Tip Clearance
    df_outside = d_outside - (modul +c) * 2 * cos(partial_cone_angle);
    rf_outside = df_outside / 2;
    delta_f = asin(rf_outside/rg_outside);
    rkf = rg_outside*sin(delta_f);                                   // Radius of the Cone Foot
    height_f = rg_outside*cos(delta_f);                               // Height of the Cone from the Root Cone

    echo("Part Cone Diameter at the Cone Base = ", d_outside);

    // Sizes for Complementary Truncated Cone
    height_k = (rg_outside-tooth_width)/cos(partial_cone_angle);          // Height of the Complementary Cone for corrected Tooth Length
    rk = (rg_outside-tooth_width)/sin(partial_cone_angle);               // Foot Radius of the Complementary Cone
    rfk = rk*height_k*tan(delta_f)/(rk+height_k*tan(delta_f));        // Tip Radius of the Cylinders for
                                                                    // Complementary Truncated Cone
    height_fk = rk*height_k/(height_k*tan(delta_f)+rk);                // height of the Complementary Truncated Cones

    echo("Bevel Gear Height = ", height_f-height_fk);

    phi_r = sphere_ev(delta_b, partial_cone_angle);                      // Angle to Point of Involute on Partial Cone

    // Torsion Angle gamma from Helix Angle
    gamma_g = 2*atan(tooth_width*tan(helix_angle)/(2*rg_outside-tooth_width));
    gamma = 2*asin(rg_outside/r_outside*sin(gamma_g/2));

    step = (delta_a - delta_b)/16;
    tau = 360/tooth_number;                                             // Pitch Angle
    start = (delta_b > delta_f) ? delta_b : delta_f;
    mirrpoint = (180*(1-clearance))/tooth_number+2*phi_r;

    // Drawing
    rotate([0,0,phi_r+90*(1-clearance)/tooth_number]){                      // Center Tooth on X-Axis;
                                                                    // Makes Alignment with other Gears easier
        translate([0,0,height_f]) rotate(a=[0,180,0]){
            union(){
                translate([0,0,height_f]) rotate(a=[0,180,0]){                               // Truncated Cone
                    difference(){
                        linear_extrude(height=height_f-height_fk, scale=rfk/rkf) circle(rkf*1.001); // 1 permille Overlap with Tooth Root
                        translate([0,0,-1]){
                            cylinder(h = height_f-height_fk+2, r = bore/2);                // bore
                        }
                    }
                }
                for (rot = [0:tau:360]){
                    rotate (rot) {                                                          // Copy and Rotate "Number of Teeth"
                        union(){
                            if (delta_b > delta_f){
                                // Tooth Root
                                flankpoint_under = 1*mirrpoint;
                                flankpoint_over = sphere_ev(delta_f, start);
                                polyhedron(
                                    points = [
                                        sphere_to_cartesian([rg_outside, start*1.001, flankpoint_under]),    // 1 permille Overlap with Tooth
                                        sphere_to_cartesian([rg_inside, start*1.001, flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_inside, start*1.001, mirrpoint-flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_outside, start*1.001, mirrpoint-flankpoint_under]),
                                        sphere_to_cartesian([rg_outside, delta_f, flankpoint_under]),
                                        sphere_to_cartesian([rg_inside, delta_f, flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_inside, delta_f, mirrpoint-flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_outside, delta_f, mirrpoint-flankpoint_under])
                                    ],
                                    faces = [[0,1,2],[0,2,3],[0,4,1],[1,4,5],[1,5,2],[2,5,6],[2,6,3],[3,6,7],[0,3,7],[0,7,4],[4,6,5],[4,7,6]],
                                    convexity =1
                                );
                            }
                            // Tooth
                            for (delta = [start:step:delta_a-step]){
                                flankpoint_under = sphere_ev(delta_b, delta);
                                flankpoint_over = sphere_ev(delta_b, delta+step);
                                polyhedron(
                                    points = [
                                        sphere_to_cartesian([rg_outside, delta, flankpoint_under]),
                                        sphere_to_cartesian([rg_inside, delta, flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_inside, delta, mirrpoint-flankpoint_under+gamma]),
                                        sphere_to_cartesian([rg_outside, delta, mirrpoint-flankpoint_under]),
                                        sphere_to_cartesian([rg_outside, delta+step, flankpoint_over]),
                                        sphere_to_cartesian([rg_inside, delta+step, flankpoint_over+gamma]),
                                        sphere_to_cartesian([rg_inside, delta+step, mirrpoint-flankpoint_over+gamma]),
                                        sphere_to_cartesian([rg_outside, delta+step, mirrpoint-flankpoint_over])
                                    ],
                                    faces = [[0,1,2],[0,2,3],[0,4,1],[1,4,5],[1,5,2],[2,5,6],[2,6,3],[3,6,7],[0,3,7],[0,7,4],[4,6,5],[4,7,6]],
                                    convexity =1
                                );
                            }
                        }
                    }
                }
            }
        }
    }
}
///////////////////////////////////////////////////////////
module shaft(height){
	linear_extrude(height){
	difference(){	
		circle(d=6);
		translate([2.3,-3.5,0])
		square(7);	
		}
	}
}
module greaThefinalone(){
	teeth=17;
	difference(){
	bevel_herringbone_gear_pair(modul=1, gear_teeth=teeth, pinion_teeth=teeth, axis_angle=90, tooth_width=5, gear_bore=4, pinion_bore=4, pressure_angle = 20, helix_angle=30, together_built=true);

	translate([-11,0,9.28366]){
	rotate([0,90,0]){	
		shaft(10);
	}
	}
		translate([0,0,-1])
		shaft(10);
	}
}
module greaThefinalonePrint(){
	teeth=17;
	difference(){
	bevel_herringbone_gear_pair(modul=1, gear_teeth=teeth, pinion_teeth=teeth, axis_angle=90, tooth_width=5, gear_bore=4, pinion_bore=4, pressure_angle = 20, helix_angle=30, together_built=false);

		translate([23.909,0,-1]){	
		shaft(10);
	}
	
		translate([0,0,-1])
		shaft(10);
	}
}
module motor(){
	x = 7.15;
	difference(){
		union(){
			cylinder(h=10,r=18.25);
			translate([x,0,10])
				cylinder(h=4.8,r=6);
			translate([x,0,14.8])
				cylinder(h=4.2,r=3);
			translate([x,0,19])
			linear_extrude(10){
				difference(){	
					circle(d=6);
					translate([-10+0.6,-3.5,0])
					square(7);	
					}
				}
		}
		translate([-13.86,8,-1])
			cylinder(h=12,r=1.5);
		
		translate([-13.86,-8,-1])
			cylinder(h=12,r=1.5);
		
		translate([0,16,-1])
			cylinder(h=12,r=1.5);	
		
		translate([0,-16,-1])
			cylinder(h=12,r=1.5);
		
		translate([13.86,8,-1])
			cylinder(h=12,r=1.5);
		
		translate([13.86,-8,-1])
			cylinder(h=12,r=1.5);
	}	
}
module box(height){
	linear_extrude(2){
		difference(){
			circle(r=20.25);
		
			translate([-13.86,8,0])
				circle(r=1.5);
			translate([-13.86,-8,0])
				circle(r=1.5);
			
			translate([0,16,0])
				circle(r=1.5);		
			translate([0,-16,0])
				circle(r=1.5);
		
			
			translate([13.86,8,0])
				circle(r=1.5);
			translate([13.86,-8,0])
				circle(r=1.5);
			
			translate([7.15,0,0])
				circle(r=6.5);
		}
	}
	translate([0,0,2])
	difference(){			
			cylinder(h=height,r=20.25);	
		
			translate([0,0,-1])
		cylinder(h=height+2,r=18.25);
}
}
module bearingHouseing(under_cut_radius){
	difference(){
		cylinder(h=12,r=25/2,center=true);
		cylinder(h=14,r=19/2,center=true);
		
		translate([0,0,-under_cut_radius])
		rotate([0,90,0])			
		cylinder(h=100,r=under_cut_radius,center=true);
			
	}
}
module suport(under_cut_radius){
	difference(){
		translate([0,0,-1])
		cube([30,20,3],center=true);		
		
		translate([0,0,-under_cut_radius])
		rotate([0,90,0])			
		cylinder(h=100,r=under_cut_radius,center=true);
			
	}
}
module bearing(){
	difference(){
		cylinder(h=6,r=19/2);
		translate([0,0,-1])
		cylinder(h=8,r=3);
	}
}
module bearingHouseingNegative(under_cut_radius){
	difference(){		
		cylinder(h=12,r=25/2,center=true);
		cylinder(h=14,r=19/2,center=true);	
		
		translate([0,0,under_cut_radius-3])
		rotate([0,90,0])
		difference(){
	
		cylinder(h=100,r=under_cut_radius+40,center=true);
			cylinder(h=102,r=under_cut_radius,center=true);
	}
	}
}
//////////////////////////////ASEBLEY/////////////////////
/*
difference(){
	union(){
		translate([10,0,18.25])
		rotate([0,90,0])
			box(35);
		translate([33,0,-2])
		rotate([180,0,0])
			bearingHouseing(18.25);

		translate([33,0,35.5])
			rotate([0,180,180])
				bearingHouseingNegative(18.25);	
		translate([30,0,38.5])
			suport(20.25);
	}
	translate([33,0,19+18.25])
	cylinder(r=3.2,h=4,center=true);
	
	translate([33,0,0])
	cylinder(r=3.2,h=4,center=true);
}
*/
translate([0,0,18.25])
rotate([0,90,0])

motor();

union(){
	/*translate([33,0,20.35])
	rotate([180,0,0])
	greaThefinalone();*/
	
	difference(){
		union(){
		translate([35,0,20.35])
		rotate([180,0,0])
		greaThefinalone();
		//greaThefinalonePrint();
		translate([35,0,20.35])
			genrateCollar(collar_height=4,collar_width=2,collar_radius=3,hole_Radius=2.7/2,hole_offset=2);
			translate([19,0,11.2])
			rotate([0,90,0])
			rotate([0,0,180])
	genrateCollar(collar_height=8,collar_width=2,collar_radius=3,hole_Radius=0,hole_offset=0);

		}
	
	}
	
}


translate([35,0,35.5-6])
color("green") bearing();

difference(){
union(){
		translate([35,0,-22])
			shaft(60);	
		translate([35,0,35.5-9])
			cylinder(h=3,r=5);	
	}
	translate([35,0,35.35-13])
			rotate([0,90,0])
			cylinder(h=10,r=2.7/2,center=true);
}
