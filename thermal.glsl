#[compute]
#version 450
// setup stuff

layout(local_size_x = 3, local_size_y = 1, local_size_z = 1) in;
// experiment with other values to find a more appropriate number

layout(set = 0, binding = 0 , std430) restrict buffer InBuffer {
    float distance;
    highp float grid[3][3][4]; //have first value be thermal energy, then conductivity, specHeatCap, then mass
}
inBuffer;

layout(set = 0, binding = 1, std430) restrict buffer OutBuffer{
    highp float[4] newGrid[3][3];
}
outBuffer;


highp float getFlux(highp float tile1[4], highp float tile2[4])
{
    float tile1Temp = (tile1[1]*tile1[3])/tile1[2];
    float tile2Temp = (tile2[1]*tile2[3])/tile2[2];
    float flux = -tile1[1]*((tile1Temp - tile2Temp)/inBuffer.distance);
    return flux;
}

//for each invocation (tile)
void main() {
    highp float grid[3][3][4];
    grid = inBuffer.grid;
    
    highp float tiles[5][4] = float[5][4]((grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y]),(grid[gl_GlobalInvocationID.x+1][gl_GlobalInvocationID.y]),(grid[gl_GlobalInvocationID.x-1][gl_GlobalInvocationID.y]),(grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y+1]),(grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y-1]));
    if (gl_GlobalInvocationID.x == grid.length())
        tiles[1] = float[4](0.0,0.0,0.0,0.0);
    else if (gl_GlobalInvocationID.x == 0)
       tiles[2] =  float[4](0.0,0.0,0.0,0.0);
    if (gl_GlobalInvocationID.y == grid.length())
        tiles[3] =  float[4](0.0,0.0,0.0,0.0);
    else if (gl_GlobalInvocationID.y == 0)
        tiles[4] =  float[4](0.0,0.0,0.0,0.0);
    
    highp float[4] fluxes = float[4](getFlux(tiles[0],tiles[1]),getFlux(tiles[0],tiles[2]),getFlux(tiles[0],tiles[3]),getFlux(tiles[0],tiles[4]));
    highp float netFlux = fluxes[0] + fluxes[1] + fluxes[2] + fluxes[3];
    //net flux is the sum of fluxes between the cell and its neighbours
    highp float newData = tiles[0][0] + netFlux;
    outBuffer.newGrid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y][0] = newData;
}