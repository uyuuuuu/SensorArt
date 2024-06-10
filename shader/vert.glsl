// attribute vec3 position;
// attribute vec3 normal;
// attribute vec2 uv;
// attribute vec3 color;

//uniform mat4 projectionMatrix;
//uniform mat4 modelViewMatrix;

varying vec2 v_uv;

void main() {
    v_uv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
