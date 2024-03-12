////// 2017 Inigo Quilez
////
////// Based on https://www.shadertoy.com/view/4tfyW4, but simpler and faster
//////
////// See these too:
//////
////// - https://www.shadertoy.com/view/llGSzw
////// - https://www.shadertoy.com/view/XlXcW4
////// - https://www.shadertoy.com/view/4tXyWN
//////
////// Not testes for uniformity, stratification, periodicity or whatever. Use (or not!) at your own risk
////
////
////  const uint k = 1103515245U;  // GLIB C
//////const uint k = 134775813U;   // Delphi and Turbo Pascal
//////const uint k = 20170906U;    // Today's date (use three days ago's dateif you want a prime)
//////const uint k = 1664525U;     // Numerical Recipes
////
////vec3 hash( uvec3 x )
////{
////    x = ((x>>8U)^x.yzx)*k;
////    x = ((x>>8U)^x.yzx)*k;
////    x = ((x>>8U)^x.yzx)*k;
////
////    return vec3(x)*(1.0/float(0xffffffffU));
////}
////
//////uniform vec2 resolution;
////// these are the uniforms set by `ShaderUpdateDetails.updateUniforms` and also
////// set by default if you don't specify an `update` handler for `ShaderEffect`:
////uniform vec2 size;
////uniform float value;
////uniform sampler2D image;
////
////void main()
////{
////    float fragCord = FlutterFragCoord().y;
////    vec2 uv = fragCord / size;
////    uvec3 p = uvec3(fragCoord / 1., 337.);
////    float r = (uv.x * hash(p).x * 0.5 * sin(iTime) + pow(uv.x, 1.)) / 1.;
////    float r2 = hash(uvec3(fragCoord * 0., 337.)).x;
////    float r3 = hash(uvec3(fragCoord * 100., 337.)).x;
////    float t = 0.5 * (1. + sin(iTime));
////    vec3 col = uv.y > t ? vec3(1.) - vec3(0.9 + (1. - r)/1., 0.85 - r, r2) : vec3(0.5 + (1. - r)/2., 0.85 - r, r2);
////    fragColor = vec4( col, 1.0 );
////}
//
//// FRAGMENT SHADER
//// This is a simple "dissolve" fragment shader with "standard" uniforms to
//// demonstrate ShaderEffect.
//
//#version 460 core
//#include <flutter/runtime_effect.glsl>
//
//precision lowp float;
//out vec4 oColor;
//
//// these are the uniforms set by `ShaderUpdateDetails.updateUniforms` and also
//// set by default if you don't specify an `update` handler for `ShaderEffect`:
//uniform vec2 size;
//uniform float value;
//uniform sampler2D image;
//
//// this is a very basic hash function, to get pseudo-random values:
//float rand(vec2 co){
//    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
//}
//
//void main() {
//    vec2 uv = FlutterFragCoord().xy / size;
//    vec4 px = texture(image, uv);
//
//    float a = rand(uv) * 0.99 + 0.01 > value ? 0 : 1;
//
//    oColor = px * a;
//}