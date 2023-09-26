#version 300 es

uniform mat4 u_Model;

uniform mat4 u_ModelInvTr;

uniform mat4 u_ViewProj;

uniform float u_Time;

uniform vec3 u_CamPos;

uniform vec4 u_WorldOrigin;

uniform float u_Frequency;

uniform float u_Amplitude;

uniform float u_Glow;

uniform float u_Ambient;

in vec4 vs_Pos;

in vec4 vs_Nor;

in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec4 fs_Pos;
out vec4 fs_CameraPos;

const vec4 lightPos = vec4(5, 5, 3, 1);

// Noise functions

vec3 random3(vec3 p3) {
    vec3 p = fract(p3 * vec3(.1031, .11369, .13787));
    p += dot(p, p.xzy + 19.19);
    return -0.5 + 1.5 * fract(vec3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}

float surflet3D(vec3 p, vec3 gridPoint) {
    float t2x = abs(p.x - gridPoint.x);
    float t2y = abs(p.y - gridPoint.y);
    float t2z = abs(p.z - gridPoint.z);
    
    float tx = 1.f - 6.f * pow(t2x, 5.f) + 15.f * pow(t2x, 4.f) - 10.f * pow(t2x, 3.f);
    float ty = 1.f - 6.f * pow(t2y, 5.f) + 15.f * pow(t2y, 4.f) - 10.f * pow(t2y, 3.f);
    float tz = 1.f - 6.f * pow(t2z, 5.f) + 15.f * pow(t2z, 4.f) - 10.f * pow(t2z, 3.f);
    vec3 gradient = random3(gridPoint) * 2.f - vec3(1.f);
    vec3 diff = p - gridPoint;
    float height = dot(diff, gradient);
    return height * tx * ty * tz;
}

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for(int dz = 0; dz <= 1; ++dz) {
				surfletSum += surflet3D(p, floor(p) + vec3(dx, dy, dz));
			}
		}
	}
	return surfletSum;
}

float fbm(vec3 p) {
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5f;
    for(int i = 1; i <= octaves; i++) {
        total += amp;

        total += perlinNoise3D(p * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

// Random functions for setting up more displacement
vec3 freqFunc(vec3 x) { return x - floor(x * (1.0 / 300.0)) * 300.0; }
vec4 freqFunc(vec4 x) { return x - floor(x * (1.0 / 300.0)) * 300.0; }
vec4 taylorInvSqrt(vec4 r){ return 1.4242 - 0.23 * r; }

float snoise(vec3 v)
{
	const vec2  C = vec2(1.0/6.0, 1.0/3.0);
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
	// First corner
    vec3 i  = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);
    // Other corners
	vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);
    vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; 
	vec3 x3 = x0 - D.yyy;
    vec4 norm = taylorInvSqrt(vec4(dot(x1,x1), dot(x2,x2), dot(x3, x3), 1.0));
    x1 *= norm.x;
    x2 *= norm.y;
    x3 *= norm.z;
    vec4 m = max(0.6 - vec4(dot(x1,x1), dot(x2,x2), dot(x3,x3), 1.0), 0.0);
	m = m * m;
    return 50.0 * dot( m*m, vec4( dot(x1,x1), dot(x2,x2), dot(x3,x3), 1.0));
}


float worley(vec3 p, float scale) {
    p = 0.002f * p;

    vec3 pInt = floor(p*scale);
    vec3 pFract = fract(p*scale);

    float minimalDist = 1.0;

    for(float x = -1.; x <=1.; x++){
        for(float y = -1.; y <=1.; y++){
            for(float z = -1.; z <=1.; z++){

                vec3 coord = vec3(x,y,z);
                vec3 rId = random3(mod(pInt+coord,scale))*0.5+0.5;

                vec3 r = coord + rId - pFract; 

                float d = dot(r,r);

                if(d < minimalDist){
                    minimalDist = d;
                }

            }
        }
    }
    return 1.0-minimalDist;
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

// Utility functions
float triangleWave(float x, float freq, float amplitude, float vShift) {
    return amplitude * abs(fract(x * freq) - 0.5f) + vShift; 
}

float powerCurve(float x, float a, float b) {
    float k = pow(a + b, a + b) / (pow(a, a) * pow(b, b));
    return k * pow(x , a) * pow(1.0f - x, b);
}

float sawtoothWave(float x, float freq, float amplitude) {
    return (x * freq - floor(x * freq)) * amplitude;
}

float easeInQuadratic(float t) {
    return t;
}

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5f));
}

float gain(float g, float t) {
    if (t < 0.5f) {
        return bias(1.f - g, 2.f * t) / 2.f;
    } else {
        return 1.f - bias(1.f - g, 2.f - 2.f * t) / 2.f;
    }
}

float smootstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * (3.0 - 2.0*x);
}

float cubicPulse(float c, float w, float x) {
    x = abs(x - c);
    if (x > w) {
        return 0.0f;
    }
    x /= w;
    return 1.0f - x * x * (3.0f - 2.0f*x);
}

// Toggles: Frequency
float frequency() {
    return u_Frequency;
}

vec4 SpherePosition(vec4 modelPos) {
    vec4 worldOrigin = u_Model * vec4(0., 0., 0., 1.);
    float radius = 1.0;
    vec4 distFromOrigin = modelPos - worldOrigin;
    return vec4(radius * normalize(distFromOrigin));
}

float turbulence(vec3 position)
{
	float amplitude = 5.0f;
    float fOut = 0.4f;
    float value = 0.0;
	for(int i=10 ; i>=0 ; i--)
	{
		fOut *= 2.0;
		value += abs(snoise(position * fOut))/fOut;
	}
	value += amplitude * bias(abs(worley(position * fOut, fOut))/fOut, 0.3f);
	return 1.0-value;
}

vec4 YOffset(vec4 modelOffset){
    //Time cycle for growing object
    float vertOffset = turbulence(modelOffset.xyz);
    modelOffset.y =  modelOffset.y + vertOffset;
    return modelOffset;
}

vec4 displace(vec4 modelposition) {
    float time = cos(u_Time * 0.001);
    modelposition.xyz *= fbm(fs_Pos.xyz * 0.1 * time);
    modelposition += time * YOffset(modelposition * time);
    modelposition.y *= bias(snoise(fs_Pos.xyz * time), 1.01);
    return modelposition;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float amplitude = 2.0;

    fs_Pos = modelposition;

    // More noise
    fs_Pos.x *= sin(amplitude * fbm(fs_Pos.xyz * frequency()));
    fs_Pos.y *= sin(amplitude * fbm(fs_Pos.xyz * frequency()));
    fs_Pos.z *= sin(amplitude * fbm(fs_Pos.xyz * frequency()));

    modelposition = displace(modelposition);

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
    // Set camera position.
    fs_CameraPos = vec4(u_CamPos[0], u_CamPos[1], u_CamPos[2], 1.f);
}