shader_type canvas_item;

// Uniforms sont des variables que l'on peut changer depuis l'éditeur Godot
uniform vec4 color_top : source_color = vec4(1.0, 0.5, 0.8, 1.0); // Rose clair par défaut
uniform vec4 color_bottom : source_color = vec4(0.8, 0.2, 0.6, 1.0); // Rose foncé par défaut

void fragment() {
	// On récupère la couleur de base du texte (généralement blanc)
	vec4 original_color = texture(TEXTURE, UV);
	
	// UV.y va de 0.0 (en haut) à 1.0 (en bas).
	// On utilise mix() pour mélanger les deux couleurs en fonction de cette coordonnée.
	vec4 gradient_color = mix(color_top, color_bottom, UV.y);
	
	// On multiplie la couleur du dégradé par la couleur originale.
	// Comme le texte est blanc, blanc * dégradé = dégradé.
	// L'alpha de la couleur originale permet de ne dessiner que là où il y a du texte.
	COLOR = gradient_color * original_color;
}
