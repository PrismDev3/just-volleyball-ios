shader_type canvas_item;

// gentle per glyph wave for label text. each glyphs vertices ride a sine
// keyed to their x position so the word rolls character by character.
// phase is advanced from script instead of TIME so the wave speed can ease
// down smoothly — scaling TIME in-shader would make the phase jump around

uniform float amp = 0.0;          // peak offset in px, 0 = perfectly still
uniform float phase = 0.0;        // advanced by the owning script
uniform float wavelength = 260.0; // px between crests

void vertex() {
	VERTEX.y += sin(phase - VERTEX.x / wavelength * 6.2831853) * amp;
}
