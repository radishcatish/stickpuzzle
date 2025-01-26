shader_type canvas_item;

uniform vec4 original_colors[2]: source_color;
uniform vec4 replace_colors[2]: source_color;

vec4 swap_color(vec4 color){
    for (int i = 0; i < 2; i ++) {
        if (distance(color, original_colors[i]) <= 0.0){
            return replace_colors[i];
        }
    }
    return color;
}

void fragment() {
    COLOR = swap_color(texture(TEXTURE, UV));
}