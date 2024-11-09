shader_type spatial;

void fragment() {
    // Get the normal of the fragment (face)
    vec3 normal = normalize(VERTEX.normal);

    // Calculate the view vector (direction from fragment to camera)
    vec3 viewDir = normalize(-VERTEX.position);

    // Calculate the angle between the normal and view direction
    float angle = dot(normal, viewDir);

    // Discard fragments (make them transparent) if they are facing away from the camera
    if (angle < 0.0) {
        discard;
    }

    // Otherwise, set the fragment color to your desired output color
    ALBEDO = vec3(1.0); // Example: Set color to white
}
