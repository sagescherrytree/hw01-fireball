#version 300 es

precision highp float;

uniform vec4 u_Color;
uniform float u_Time;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 fs_CameraPos;

out vec4 out_Col;

#define MAX_ITERATIONS 4.0
// Controls the sample density, which in turn, controls the sample spread.
float density = 5.0; 

vec3 random3(vec3 p3) {
    vec3 p = fract(p3 * vec3(.1031, .11369, .13787));
    p += dot(p, p.xzy + 19.19);
    return -0.5 + 1.5 * fract(vec3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}
    
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);
    return a + b*cos(6.28318 * (c*t + d));
}

// Going to try to make a circle hehe
float SDF_Sphere(vec3 query, float radius ) {
    return length(query) - radius;
}

vec2 random(vec2 r) {
    return fract(sin(vec2(dot(r, vec2(127.1, 311.7)), dot(r, vec2(269.5, 183.3)))) * 43758.5453);
}

float surflet(vec2 P, vec2 gridPoint) {
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1.0 - 6.0 * pow(distX, 5.f) + 15.0 * pow(distX, 4.f) - 10.0 * pow(distX, 3.f);
    float tY = 1.0 - 6.0 * pow(distY, 5.f) + 15.0 * pow(distY, 4.f) - 10.0 * pow(distY, 3.f);
    // Get the random vector for the grid point
    vec2 gradient = 2.f * random(gridPoint) - vec2(1.f);
    // Get the vector from the grid point to P
    vec2 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY;
}


float perlinNoise(vec2 uv) {
    float surfletSum = 0.f;
    // Iterate over the four integer corners surrounding uv
    for(int dx = 0; dx <= 1; ++dx) {
            for(int dy = 0; dy <= 1; ++dy) {
                    surfletSum += surflet(uv, floor(uv) + vec2(dx, dy));
            }
    }
    return surfletSum;
}

float worley2(vec3 p, float t, float numCells) {
    p = 0.0002f * t + numCells * p; 
    vec3 pInt = floor(p);
    vec3 pFract = fract(p);
    float minDist1 = 1.0f; // Minimum distance initialized to max.
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            for(int z = -1; z <= 1; ++z) {
                vec3 neighbor = vec3(float(x), float(y), float(z)); 
                vec3 point = random3(pInt + neighbor); 
                vec3 diff = neighbor + point - pFract; 
                float dist = length(diff);
                if(dist < minDist1) {
                        minDist1 = dist;
                }
            }      
        }
    }

    return minDist1; 
}

// Offset
vec3 offset(vec2 query){    
    float c = cos(-0.1 * query.x);
    float s = sin(-0.1 * query.y);
    // Rotation matrix
    mat2 a = mat2(c, s, -s, c);
    
    // What is l? TODO: modify l
    vec3 l = normalize(vec3(50.5, 10., -0.05));
    l.xz = a * l.xz;
    l.xy = a * l.xy;
    
    return l;
}

void main()
{
    vec2 uv = fs_Nor.xy;
    vec3 finalCol = vec3(0.0);
    // Offset. Gets updated? Possibly? 
    vec3 off = offset(fs_Col.xy);

    for (float i = 1.0; i < MAX_ITERATIONS; i+=1.0) {
        uv = fract(uv * 1.5) - 0.5 - off.xy * .45;

        vec2 densityUV = uv * density / 6.0;
        
        float d = length(uv);
        
        vec2 colUV = finalCol.xy;
        float perlinCircle = perlinNoise(densityUV);
        float circle = SDF_Sphere(finalCol * 1.1, perlinCircle);
        circle += perlinNoise(colUV);
        
        float x = perlinNoise(uv);
        vec3 col = palette(length(uv) + u_Time * 0.001 + i * 0.4);
        col += vec3(x);
    
        d = sin(d*8.0 + u_Time) / 8.0;
        //d = 3.0 * sin(d * u_Time)/u_Time + 3.0 * cos(d * u_Time) / u_Time;
        d = 3.0 * sin(perlinCircle * u_Time) / u_Time;
        d += mod(x,i);
        d = abs(d);
        //d = pow(0.01/d, circle * 0.3);
        //d *= 1.0 / pow(0.5, i);
        
        // Time varying pixel color
        finalCol += col * d;
        finalCol -= circle;
    }

    // Output to screen
    out_Col = vec4(finalCol, 1.0);
}