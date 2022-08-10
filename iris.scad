$fn=100;

module sector(radius,angle){
	difference(){
		circle(r=radius);
		rotate([0,0,-angle])
		square(radius+1);
		translate([-radius-1,0,0])
		square(radius+1);
		translate([-radius-1,-radius-1,0])
		square([(radius*2)+2,radius+1]);
	}
}
module edgePice(radius){
translate([sqrt(((radius*radius)-(radius/2)*(radius/2))),radius/2,0]){
		difference(){
			circle(radius);
			translate([-sqrt(((radius*radius)-(radius/2)*(radius/2))),-radius-1,0])
			square((radius*2)+2);
		}
	}
}
module section(radius,number){
	difference(){
		union(){
			sector(radius=radius,angle=360/number);
			edgePice(radius);
		}
		rotate([0,0,-360/number])
		edgePice(radius);
	rotate([0,0,-(360/number)-1])
		edgePice(radius);		
	}
}
for ( i = [1 : 6] ){
	rotate([0,0,(360/6)*i])
    section(radius=40,number=6);
}

//sector(radius=40,angle=60);