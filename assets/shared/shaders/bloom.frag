#pragma header

uniform float intensity;
uniform float blurSize;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 baseColor = flixel_texture2D(bitmap, uv);
    
    vec4 sum = vec4(0.0);
    sum += flixel_texture2D(bitmap, vec2(uv.x - blurSize, uv.y));
    sum += flixel_texture2D(bitmap, vec2(uv.x + blurSize, uv.y));
    sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y - blurSize));
    sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y + blurSize));
    
    vec4 blurColor = sum / 4.0;
    gl_FragColor = baseColor + (blurColor * intensity);
}