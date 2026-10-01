shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 source = texture(screen_texture, SCREEN_UV);
    float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    float cyan_highlight = step(0.12, source.b - source.r) * step(0.08, source.g - source.r);
    vec3 output_color = mix(vec3(luminance), vec3(0.65, 0.95, 1.0), cyan_highlight);
    COLOR = vec4(output_color, source.a);
}
