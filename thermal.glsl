#[compute]
#version 450
// setup stuff

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
// experiment with other values to find a more appropriate number

layout(set = 0, binding = 0 ,std430) restrict uniform buffer InBuffer {
    float distance;
    float[4] grid[][]; //have first value be thermal energy, then conductivity, specHeatCap, then mass
}
inBuffer;

layout(set = 1, binding = 0, std430) restrict OutBuffer{
    float[4] newGrid[][];
}
outBuffer;


float getFlux(float[4] tile1, float[4] tile2)
{
    float tile1Temp = (tile1[1]*tile1[3])/tile1[0][2]
    float tile2Temp = (tile2[1]*tile2[3])/tile2[0][2]
    float flux = -tile1[1]*((tile1Temp - tile2Temp)/inBuffer.distance)
    return flux
}


//for each invocation (tile)
void main {
    grid = inBuffer.grid
    tiles[5] = [grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y],grid[gl_GlobalInvocationID.x+1][gl_GlobalInvocationID.y],grid[gl_GlobalInvocationID.x-1][gl_GlobalInvocationID.y],grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y+1],grid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y-1]]
    if gl_GlobalInvocationID.x == grid.length():
        tiles[1] = [0.0,0.0,0.0,0.0];
    else if gl_GlobalInvocationID.x == 0:
       tiles[2] = [0.0,0.0,0.0,0.0];
    if gl_GlobalInvocationID.y == grid.length()
        tiles[3] = [0.0,0.0,0.0,0.0];
    else if gl_GlobalInvocationID == 0:
        tiles[4] = [0.0,0.0,0.0,0.0];
    
    float[4] fluxes = [getFlux(tiles[0],tiles[1]),getFlux(tiles[0],tiles[2]),getFlux(tiles[0],tiles[3]).getFlux(tiles[0],tiles[4])];
    float netFlux = fluxes[0] + fluxes[1] + fluxes[2] + fluxes[3];
    //net flux is the sum of fluxes between the cell and its neighbours
    float newData = tiles[0][0] + netFlux;
    outBuffer.newGrid[gl_GlobalInvocationID.x][gl_GlobalInvocationID.y] = newData
}