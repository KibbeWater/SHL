//
//  Pulse.metal
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 22/8/24.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]] half4 pulse(float2 pos, half4 color, float2 center, float time, float speed, float amplitude, float decay) {
    // Frequency and speed controls for the sine wave
    float frequency = 5.0;  // Controls the number of waves
    float dist = distance(pos, center);
    float delay = dist/speed;
    
    time -= delay;
    time = max(0.0, time);
    
    // Calculate the sine wave based on the x position and time
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);
    // float2 n = normalize(pos - center);
    
    // Modulate the input color with the wave value
    half4 newClr = color; // half4(0,0,0,color.a);
    newClr.r += 2.0 * (rippleAmount / amplitude) * (newClr.a/2);
    newClr.gb += 0.2 * (rippleAmount / amplitude) * newClr.a;

    return newClr;
}

[[ stitchable ]]
half4 Ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    // The distance of the current pixel position from `origin`.
    float distance = length(position - origin);
    // The amount of time it takes for the ripple to arrive at the current pixel position.
    float delay = distance / speed;
 
    // Adjust for delay, clamp to 0.
    time -= delay;
    time = max(0.0, time);
 
    // The ripple is a sine wave that Metal scales by an exponential decay
    // function.
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);
 
    // A vector of length `amplitude` that points away from position.
    float2 n = normalize(position - origin);
 
    // Scale `n` by the ripple amount at the current pixel position and add it
    // to the current pixel position.
    //
    // This new position moves toward or away from `origin` based on the
    // sign and magnitude of `rippleAmount`.
    float2 newPosition = position + rippleAmount * n;
 
    // Sample the layer at the new position.
    half4 color = layer.sample(newPosition);
 
    // Lighten or darken the color based on the ripple amount and its alpha
    // component.
    color.r += 1.0 * (rippleAmount / amplitude) * color.a;
 
    return color;
}
