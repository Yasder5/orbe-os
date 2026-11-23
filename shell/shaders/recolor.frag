// Recolore un fond d'écran d'Orbe dans la couleur d'accent choisie, pour components/Fond.qml.
//
// Les fonds d'Orbe ne mélangent que du noir, du blanc cassé et le citron. Chaque pixel est lu
// comme gris + s × citron : s vient de sa part colorée (l'écart entre ses canaux) rapportée à
// celle du citron. On remplace alors s × citron par s × nouvelle couleur. Les étoiles blanches
// et le fond noir ne bougent pas, les halos et traits citron prennent la nouvelle couleur.
//
// Compilé en recolor.frag.qsb par tools/build-shaders.sh (qsb, paquet qt6-shadertools).

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fromColor;     // couleur d'origine (citron)
    vec4 toColor;       // couleur choisie
};

layout(binding = 1) uniform sampler2D source;

float chroma(vec3 c) {
    return max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
}

void main() {
    vec4 p = texture(source, qt_TexCoord0);
    float s = clamp(chroma(p.rgb) / max(chroma(fromColor.rgb), 0.001), 0.0, 1.0);
    vec3 rgb = clamp(p.rgb + s * (toColor.rgb - fromColor.rgb) * p.a, 0.0, 1.0);
    fragColor = vec4(rgb, p.a) * qt_Opacity;
}
