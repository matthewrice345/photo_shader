#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uSaturation;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec4 color = texture(uTexture, uv);

    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 adjustedColor = mix(vec3(gray), color.rgb, uSaturation);

    fragColor = vec4(adjustedColor, color.a);
}