////////////////////////////////////////////////////////////////////////////////////////////////////
// packUnpack.fxh (HLSL)
// Brief: Packing and unpacking convenience functions for MNPR
// Contributors: Amir Semmo
////////////////////////////////////////////////////////////////////////////////////////////////////
//                     _                                   _    
//    _ __   __ _  ___| | __  _   _ _ __  _ __   __ _  ___| | __
//   | '_ \ / _` |/ __| |/ / | | | | '_ \| '_ \ / _` |/ __| |/ /
//   | |_) | (_| | (__|   <  | |_| | | | | |_) | (_| | (__|   < 
//   | .__/ \__,_|\___|_|\_\  \__,_|_| |_| .__/ \__,_|\___|_|\_\
//   |_|                                 |_|                    
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides pack/unpack functions, e.g., to improve the memory footprint and reduce buffer counts
////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef _PACKUNPACK_FXH
#define _PACKUNPACK_FXH



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

// Contributor: Amir Semmo
// Pack and unpack three positive normalized numbers between 0.0 and 1.0
// into a 32-bit fp channel of a render target
// -> Based on Packing functions by Wolfgang Engel 2009
//    [2009] BitMasks / Packing Data into fp Render Targets
inline float packRGB(float3 channel) {
    // layout of a 32-bit fp register
    // SEEEEEEEEMMMMMMMMMMMMMMMMMMMMMMM
    // 1 sign bit; 8 bits for the exponent and 23 bits for the mantissa
    uint uValue;

    // let's assume channel is in the range [-1; 1], lets offset and normalize to [0; 1]
    float3 channelNorm = saturate((channel + 1.0) / 2.0);

    // pack x
    uValue = ((uint)(channelNorm.x * 65535.0 + 0.5)); // goes from bit 0 to 15

    // pack y in EMMMMMMM
    uValue |= ((uint)(channelNorm.y * 255.0 + 0.5)) << 16;

    // pack z in SEEEEEEE
    // the last E will never be 1b because the upper value is 254
    // max value is 11111110 == 254
    // this prevents the bits of the exponents to become all 1
    // range is 1.. 254
    // to prevent an exponent that is 0 we add 1.0
    uValue |= ((uint)(channelNorm.z * 253.0 + 1.5)) << 24;

    return asfloat(uValue);
}

inline float3 unpackRGB(float fFloatFromFP32) {
    float a, b, c, d;
    uint uValue;

    uint uInputFloat = asuint(fFloatFromFP32);

    // unpack a
    // mask out all the stuff above 16-bit with 0xFFFF
    a = ((uInputFloat) & 0xFFFF) / 65535.0;

    b = ((uInputFloat >> 16) & 0xFF) / 255.0;

    // extract the 1..254 value range and subtract 1
    // ending up with 0..253
    c = (((uInputFloat >> 24) & 0xFF) - 1.0) / 253.0;

    // we assume that a,b,c should be in the range [-1; 1], lets offset
    float3 channel = 2.0 * float3(a, b, c) - 1.0;

    return channel;
}


#endif /* _PACKUNPACK_FXH */
