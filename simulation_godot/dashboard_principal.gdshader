shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// Puedes subir el blur_amount a 3.0 o 4.0 si quieres que el mapa se vea más difuminado
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.1, 0.12, 0.15, 0.7);

void fragment() {
	// 1. Capturamos el mapa del fondo y lo hacemos borroso
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
	
	// 2. Mezclamos solo los colores (RGB) del mapa borroso con nuestro tinte oscuro
	vec3 final_color = mix(blurred.rgb, tint_color.rgb, tint_color.a);
	
	// 3. ¡LA MAGIA! Forzamos el Alpha a 1.0 para ocultar el panel blanco que está detrás
	COLOR = vec4(final_color, 1.0);
}
