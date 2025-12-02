shader_type canvas_item;

// Warna Kiri
uniform vec4 color_left : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Merah
// Warna Kanan
uniform vec4 color_right : source_color = vec4(0.0, 0.0, 1.0, 1.0); // Biru

// Seberapa kuat efeknya
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);

    // PERUBAHAN DI SINI:
    // Gunakan SCREEN_UV.x agar gradasi berjalan dari Kiri (0.0) ke Kanan (1.0)
    vec4 gradient_color = mix(color_left, color_right, SCREEN_UV.x);

    COLOR = mix(original_color, gradient_color, mix_amount) * original_color.a;
}