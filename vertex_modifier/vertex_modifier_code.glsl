//UNIFORMS
uniform float time;
//BODY
// displacing vertex Z
float z = sin((time + co.y)*10.0) * 0.15 + sin((time + co.x)*10.0) * 0.15;
co.z += z
// getting slope (m)
float mx = cos((time + co.x)*10.0) * 1.5;
float my = cos((time + co.y)*10.0) * 1.5;
// getting normal from mx and my
vec3 vx = vec3(1.0,0,mx);
vec3 vy = vec3(0,1.0,my);
normal = cross(vx, vy);
