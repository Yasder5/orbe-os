// Orbe de particules sur le GPU, pour components/Orb.qml et le fond d'écran animé.
//
// Les particules sont réparties sur une sphère de Fibonacci. Pour chaque pixel, on prend les
// deux points de la sphère qui s'y projettent (avant et arrière), on retrouve la particule la
// plus proche de chacun en temps constant grâce à l'inverse de la répartition de Fibonacci
// (Keinert et al., « Spherical Fibonacci Mapping », 2015), puis on dessine son point.
// Coût : quelques dizaines d'opérations par pixel, quel que soit le nombre de particules.
//
// Compilé en orb.frag.qsb par tools/build-shaders.sh (qsb, paquet qt6-shadertools).

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;      // taille de l'élément, en pixels
    vec2 orbCenter;     // centre de l'orbe, en pixels
    float orbRadius;    // rayon de l'orbe, en pixels
    float dotSize;      // rayon d'un point discret, en pixels
    float yaw;          // rotation autour de l'axe vertical, en radians
    float tilt;         // inclinaison, en radians
    float count;        // nombre de particules
    float halo;         // intensité du halo accent (0 : aucun)
    vec4 baseColor;     // points discrets (blanc cassé)
    vec4 accentColor;   // points accent (citron)
    vec4 background;    // fond (transparent pour se superposer)
};

const float PI = 3.14159265359;
const float PHI = 1.61803398875;

float madfrac(float a, float b) {
    return a * b - floor(a * b);
}

vec3 fibonacciPoint(float i, float n) {
    float phi = 2.0 * PI * madfrac(i, PHI - 1.0);
    float cosTheta = 1.0 - (2.0 * i + 1.0) / n;
    float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
    return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

// Indice de la particule la plus proche du point p (unitaire) de la sphère.
float nearestParticle(vec3 p, float n) {
    float phi = min(atan(p.y, p.x), PI);
    float cosTheta = p.z;
    float k = max(2.0, floor(log(n * PI * sqrt(5.0) * (1.0 - cosTheta * cosTheta)) / log(PHI * PHI)));
    float Fk = pow(PHI, k) / sqrt(5.0);
    float F0 = floor(Fk + 0.5);
    float F1 = floor(Fk * PHI + 0.5);
    // Colonnes : vecteurs du réseau pour F0 et F1, dans l'espace (angle, hauteur).
    mat2 B = mat2(2.0 * PI * madfrac(F0 + 1.0, PHI - 1.0) - 2.0 * PI * (PHI - 1.0), -2.0 * F0 / n,
                  2.0 * PI * madfrac(F1 + 1.0, PHI - 1.0) - 2.0 * PI * (PHI - 1.0), -2.0 * F1 / n);
    vec2 c = floor(inverse(B) * vec2(phi, cosTheta - (1.0 - 1.0 / n)));
    float best = 8.0;
    float j = 0.0;
    for (int s = 0; s < 4; ++s) {
        vec2 corner = vec2(float(s - 2 * (s / 2)), float(s / 2));
        float i = clamp(dot(vec2(F0, F1), corner + c), 0.0, n - 1.0);
        vec3 q = fibonacciPoint(i, n);
        float d = dot(q - p, q - p);
        if (d < best) {
            best = d;
            j = i;
        }
    }
    return j;
}

mat3 rotation() {
    float cy = cos(yaw), sy = sin(yaw), ct = cos(tilt), st = sin(tilt);
    mat3 ry = mat3(cy, 0.0, -sy, 0.0, 1.0, 0.0, sy, 0.0, cy);
    mat3 rx = mat3(1.0, 0.0, 0.0, 0.0, ct, st, 0.0, -st, ct);
    return rx * ry;
}

float hash(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

// Contribution (couleur prémultipliée) de la particule la plus proche du point de vue v.
vec4 particle(vec3 v, vec2 pixel, mat3 rot) {
    vec3 model = transpose(rot) * v;
    float j = nearestParticle(normalize(model), count);
    vec3 q = rot * fibonacciPoint(j, count);
    float depth = (q.z + 1.0) * 0.5;
    bool accent = hash(j + 1.0) < 0.1;
    vec2 projected = orbCenter + q.xy * orbRadius;
    float d = length(pixel - projected);
    float r = accent ? dotSize * 2.0 * (0.55 + 0.45 * depth) : dotSize * (0.7 + 0.3 * depth);
    float alpha = accent ? 0.32 + 0.6 * depth : 0.08 + 0.32 * depth;
    float coverage = 1.0 - smoothstep(r - 0.75, r + 0.75, d);
    vec4 color = accent ? accentColor : baseColor;
    float a = coverage * alpha * color.a;
    return vec4(color.rgb * a, a);
}

void main() {
    vec2 pixel = qt_TexCoord0 * itemSize;
    vec2 u = (pixel - orbCenter) / orbRadius;
    float r2 = dot(u, u);

    // Fond et halo accent très discret autour de l'orbe.
    vec4 result = vec4(background.rgb * background.a, background.a);
    if (halo > 0.0) {
        float h = pow(clamp(1.0 - sqrt(r2) / 1.6, 0.0, 1.0), 2.2) * halo * accentColor.a;
        result = vec4(accentColor.rgb * h, h) + result * (1.0 - h);
    }

    // Les points du bord débordent un peu du disque : marge de quelques pixels.
    float margin = (dotSize * 3.0) / orbRadius;
    if (r2 < (1.0 + margin) * (1.0 + margin)) {
        mat3 rot = rotation();
        float z = sqrt(max(0.0, 1.0 - r2));
        vec2 uc = r2 > 1.0 ? u / sqrt(r2) : u;
        vec4 back = particle(vec3(uc, -z), pixel, rot);
        vec4 front = particle(vec3(uc, z), pixel, rot);
        result = back + result * (1.0 - back.a);
        result = front + result * (1.0 - front.a);
    }

    fragColor = result * qt_Opacity;
}
