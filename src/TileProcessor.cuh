/**
 **
 ** TileProcessor.cuh
 **
 ** Copyright (C) 2018 Elphel, Inc.
 **
 ** -----------------------------------------------------------------------------**
 **
 **  TileProcessor.cuh is free software: you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation, either version 3 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **
 **  Additional permission under GNU GPL version 3 section 7
 **
 **  If you modify this Program, or any covered work, by linking or
 **  combining it with NVIDIA Corporation's CUDA libraries from the
 **  NVIDIA CUDA Toolkit (or a modified version of those libraries),
 **  containing parts covered by the terms of NVIDIA CUDA Toolkit
 **  EULA, the licensors of this Program grant you additional
 **  permission to convey the resulting work.
 ** -----------------------------------------------------------------------------**
 */

/**
**************************************************************************
* \file TileProcessor.cuh
* \brief Top level of the Tile Processor for frequency domain

*/
// Avoiding includes in jcuda, all source files will be merged
#ifndef JCUDA
#pragma once
#include "dtt8x8.cuh"
#define THREADSX         (DTT_SIZE)
#define NUM_CAMS                  4
#define NUM_PAIRS                 6
#define NUM_COLORS                3
#define IMG_WIDTH              2592
#define IMG_HEIGHT             1936
#define KERNELS_HOR             164
#define KERNELS_VERT            123
#define KERNELS_LSTEP             4
#define THREADS_PER_TILE          8
#define TILES_PER_BLOCK           4
#define CORR_THREADS_PER_TILE     8
#define CORR_TILES_PER_BLOCK      4
#define TEXTURE_THREADS_PER_TILE  8
#define TEXTURE_TILES_PER_BLOCK   1
#define IMCLT_THREADS_PER_TILE   16
#define IMCLT_TILES_PER_BLOCK     4
#define CORR_NTILE_SHIFT          8 // higher bits - number of a pair, other bits tile number
#define CORR_PAIRS_MASK        0x3f// lower bits used to address correlation pair for the selected tile
#define CORR_TEXTURE_BIT          7 // bit 7 used to request texture for the tile
#define TASK_CORR_BITS            4
#define TASK_TEXTURE_N_BIT        0 // Texture with North neighbor
#define TASK_TEXTURE_E_BIT        1 // Texture with East  neighbor
#define TASK_TEXTURE_S_BIT        2 // Texture with South neighbor
#define TASK_TEXTURE_W_BIT        3 // Texture with West  neighbor
#define TASK_TEXTURE_BIT          3 // bit to request texture calculation int task field of struct tp_task
#define LIST_TEXTURE_BIT          7 // bit to request texture calculation
#define CORR_OUT_RAD              4
#define FAT_ZERO_WEIGHT           0.0001 // add to port weights to avoid nan

#define THREADS_DYNAMIC_BITS      5 // treads in block for CDP creation of the texture list

//#undef HAS_PRINTF
#define HAS_PRINTF
//7
//#define DEBUG1 1
//#define DEBUG2 1
//#define DEBUG3 1
//#define DEBUG4 1
//#define DEBUG5 1
//#define DEBUG6 1
/*
#define DEBUG7 1
#define DEBUG8 1
#define DEBUG9 1
*/
#define DEBUG10 1
#define DEBUG11 1
#define DEBUG12 1
//#define USE_textures_gen
#define DEBUG_OOB1 1
#endif //#ifndef JCUDA

#define TASK_TEXTURE_BITS ((1 << TASK_TEXTURE_N_BIT) | (1 << TASK_TEXTURE_E_BIT) | (1 << TASK_TEXTURE_S_BIT) | (1 << TASK_TEXTURE_W_BIT))



//#define IMCLT14
//#define NOICLT 1
//#define TEST_IMCLT
//#define SAVE_CLT
// Not enough shared memory to have more threads per block,even just for the result clt tiles
// What to do:
// 1) make single image aberration correction: 1/4 of the result tiles
// With 4 cameras = calculate correlations (9x9), reusing kernel or just clt ones after color reducing, then output them to device memory
//Average run time =1308.124146 ms
//#define TILES_PER_BLOCK    2
//Average run time =12502.638672 - with 2 tiles/block it is longer!
///12129.268555 ms
//Average run time =4704.506348 ms (syncwarp)
//Average run time =4705.612305 ms (syncthreads)
//Average run time =1051.411255 ms
//Average run time =861.866577 ms
//Average run time =850.871277 ms had bugs
//Average run time =857.947632 ms fixed bugs


// Something broke, even w/o LPF: Average run time =1093.115112 ms
// without clt copying to device memory - Average run time =965.342407 ms - still worse
//Average run time =965.880554 ms
// combined tx and ty into a single int : Average run time =871.017944 ms
//Average run time =873.386597 ms (reduced number of registers)
//__umul24 : Average run time =879.125122 ms
// without __umul24 - back to Average run time =871.315552 ms
// Added copying clt to device memory - Average run time =942.071960 ms
// Removed rest of NOICLT : Average run time =943.456177 ms
// Added lpf: Average run time =1046.101318 ms (0.1 sec, 10%) - can be combined with the PSF kernel
//#define USE_UMUL24
////#define TILES_PER_BLOCK    4
//Average run time =5155.922852 ms
//Average run time =1166.388306 ms
//Average run time =988.750977 ms
//#define TILES_PER_BLOCK    8
//Average run time =9656.743164 ms
// Average run time =9422.057617 ms (reducing divergence)
//#define TILES_PER_BLOCK    1

//#define THREADS_PER_TILE   8
//#define IMCLT_THREADS_PER_TILE 16
//#define IMCLT_TILES_PER_BLOCK   4


#define KERNELS_STEP  (1 << KERNELS_LSTEP)
#define TILESX        (IMG_WIDTH / DTT_SIZE)
#define TILESY        (IMG_HEIGHT / DTT_SIZE)
// Make TILESYA >= TILESX and a multiple of 4
#define TILESYA       ((TILESY +3) & (~3))
// increase row length by 1 so vertical passes will use different ports
#define DTT_SIZE1        (DTT_SIZE + 1)
#define DTT_SIZE2        (2 * DTT_SIZE)
#define DTT_SIZE21       (DTT_SIZE2 + 1)
//#define DTT_SIZE22       (DTT_SIZE2 + 2)
#define MCLT_UNION_LEN   (DTT_SIZE2 * (DTT_SIZE2 + 2))
#define DTT_SIZE4        (4 * DTT_SIZE)
#define DTT_SIZE2M1      (DTT_SIZE2 - 1)

// Use CORR_OUT_RAD for the correlation output


#define BAYER_RED   0
#define BAYER_BLUE  1
#define BAYER_GREEN 2
// assuming GR/BG as now
#define BAYER_RED_ROW 0
#define BAYER_RED_COL 1
//#define BAYER_BLUE_ROW (1 - BAYER_RED_ROW)
//#define BAYER_BLUE_COL (1 - BAYER_RED_COL)
//#define DBG_TILE_X     40
//#define DBG_TILE_Y     80
#define DBG_TILE_X     161 // 49
#define DBG_TILE_Y     111 // 66

#define DBG_TILE     (DBG_TILE_Y * 324 + DBG_TILE_X)
//56494
// struct tp_task
//#define TASK_SIZE      12
struct tp_task {
	int   task;
	union {
		int      txy;
		unsigned short sxy[2];
	};
	float xy[NUM_CAMS][2];
};
struct CltExtra{
	float data_x;   // kernel data is relative to this displacement X (0.5 pixel increments)
	float data_y;   // kernel data is relative to this displacement Y (0.5 pixel increments)
	float center_x; // actual center X (use to find derivatives)
	float center_y; // actual center X (use to find derivatives)
	float dxc_dx;   // add this to data_x per each pixel X-shift relative to the kernel center location
	float dxc_dy;   // same per each Y-shift pixel
	float dyc_dx;
	float dyc_dy;
};
/*
 Python code to generate constant coefficients:
def setup_hwindow(n=8, l=4):
    hwindow = [math.sin(math.pi*((1.0+2*i)/(4*n))) for i in range(2*n)]
    print("__constant__ float HWINDOW[] = {", end="") #
    for i in range (n):
        print("%ff"%(hwindow[i]), end ="")
        if i == (n-1):
            print("};")
        elif ((i + 1) % l) == 0:
            print(",")
            print("                                ", end ="")
        else:
            print(", ",end="")

def setup_hwindow2(n=8, l=4):
    hwindow = [0.5*math.sin(math.pi*((1.0+2*i)/(4*n))) for i in range(2*n)]
    print("__constant__ float HWINDOW2[] = {", end="") #
    for i in range (n):
        print("%ff"%(hwindow[i]), end ="")
        if i == (n-1):
            print("};")
        elif ((i + 1) % l) == 0:
            print(",")
            print("                                 ", end ="")
        else:
            print(", ",end="")

def setup_hwindow_sq(n=8, l=4):
    hwindow = [(math.sin(math.pi*((1.0+2*i)/(4*n)))) ** 2 for i in range(2*n)]
    print("__constant__ float HWINDOW_SQ[] = {", end="") #
    for i in range (n):
        print("%ff"%(hwindow[i]), end ="")
        if i == (n-1):
            print("};")
        elif ((i + 1) % l) == 0:
            print(",")
            print("                                 ", end ="")
        else:
            print(", ",end="")


def setup_hwindow_sqi(n=8, l=4):
    hwindow = [1.0/(math.sin(math.pi*((1.0+2*i)/(4*n)))) ** 2 for i in range(2*n)]
    print("__constant__ float HWINDOW_SQi[] = {", end="") #
    for i in range (n):
        print("%ff"%(hwindow[i]), end ="")
        if i == (n-1):
            print("};")
        elif ((i + 1) % l) == 0:
            print(",")
            print("                                 ", end ="")
        else:
            print(", ",end="")



def get_fold_rindices(n=8):
    n1 = n>>1;
    rind = [0] * (2 * n) # reverse indices
    rcs =  [0] * (2 * n) # reverse signs for cosine term
    rss =  [0] * (2 * n) # reverse signs for sine term
    for x in range (n1):
        ri0 = n + n1 - x - 1
        ri1 = n + n1 + x
        ri2 =          x
        ri3 = n      - x - 1
        rind[ri0] = x
        rind[ri1] = x
        rind[ri2] = x + n1
        rind[ri3] = x + n1
        rcs[ri0] = -1
        rss[ri0] =  1
        rcs[ri1] = -1
        rss[ri1] = -1
        rcs[ri2] =  1
        rss[ri2] =  1
        rcs[ri3] = -1
        rss[ri3] =  1
    rind0 = []
    rind1 = []
    # generate start indices for the first 2 bayer rows
    for a in rind:
        rind0.append(a+rind[0]*n)
        rind1.append(a+rind[1]*n)
    #column increments for odd/even bayer rows
    inc_even = []
    inc_odd = []
    for i in range (n-1):
        inc_even.append(rind[2*i+2]-rind[2*i])
        inc_odd.append (rind[2*i+3]-rind[2*i+1])
    inc_even.reverse()
    inc_odd.reverse()
    # combine increments into int data
    inc_e = 0
    inc_o = 0
    for d in inc_even:
        inc_e = ((inc_e) << 4) | (d & 0xf)
    for d in inc_odd:
        inc_o = ((inc_o) << 4) | (d & 0xf)
    print("__constant__ int fold_indx2[2][%d] = {{"%(2*n), end="") #
    for d in rind0[:-1]:
        print('0x%2x,'%(d), end="")
    print('0x%2x},'%(rind0[-1]))
    print("                                      {", end="") #
    for d in rind1[:-1]:
        print('0x%2x,'%(d), end="")
    print('0x%2x}};'%(rind1[-1]))
    print("__constant__ int fold_inc[]=          {0x%08x, 0x%08x};"%(inc_e, inc_o))

def set_imclt_sa(stride=9):
    sa8 =[0x24,0x2c,0x34,0x3c,0x3c,0x34,0x2c,0x24,0x1c,0x14,0x0c,0x04,0x04,0x0c,0x14,0x1c]
    sa8s = [d // 8 + (d % 8) * stride for d in sa8]
    print("__constant__ int imclt_indx9[16] = {", end="") #
    for d in sa8s[:-1]:
        print('0x%02x,'%(d), end="")
    print('0x%2x};'%(sa8s[-1]))

import numpy as np # math
def printAlphaFade(transform_size):
    ts2 = 2 * transform_size
    ts2m1 = ts2-1
    alphaFade = np.zeros(shape=(16,ts2*ts2), dtype=float) # 	double [][] alphaFade = new double[16][ts2*ts2];
    fade1d =    np.zeros(shape=(16,), dtype=float) # double [] fade1d = new double [ts2];
    for i in range (ts2):
        fade1d[i] = 0.5 * (1.0 - np.cos(np.pi * (i +0.5) /ts2))
    for i in range (ts2):
        for j in range (ts2):
            indx = i * ts2 + j
            for m in range (16):
#                if   m == 0:
#                    alphaFade[m][indx] = 0
                elif m == 1: # 0
                    alphaFade[m][indx] = fade1d[ts2m1 - i]
                elif m == 2:
                    alphaFade[m][indx] = fade1d[j]
                elif m == 4:
                    alphaFade[m][indx] = fade1d[i]
                elif m == 8:
                    alphaFade[m][indx] = fade1d[ts2m1 - j]
                elif m == 3:
                    alphaFade[m][indx] = (fade1d[ts2m1 - i],fade1d[j])[j > ts2m1 - i]
                elif m == 6:
                    alphaFade[m][indx] = (fade1d[i],fade1d[j])[j > i]
                elif m == 9:
                    alphaFade[m][indx] = (fade1d[ts2m1 - j],fade1d[ts2m1 - i])[j > i]
                elif m == 12:
                    alphaFade[m][indx] = (fade1d[ts2m1 - j],fade1d[i])[i > ts2m1 - j]
                else:
                    alphaFade[m][indx] = 1.0
    floats_in_line=8
    print("__constant__ float alphaFade[16][%d] = {"%(ts2*ts2))
    for m in range (16):
        for i in range (ts2 * ts2):
            if ((i % floats_in_line) == 0):
                print("    ",end="")
                if (i == 0) :
                    print("{",end="")
                else:
                    print(" ",end="")
            print("%ff"%(alphaFade[m][i]), end ="")
            if (((i + 1) % floats_in_line) == 0):
                if (i == (ts2 * ts2 -1)):
                    print("}",end="")
                else:
                    print(",")
            else:
                print(", ",end="")
        if (m == 15):
            print("};")
        else:
            print(",")


*/


__constant__ float HWINDOW[] =   {0.098017f, 0.290285f, 0.471397f, 0.634393f,
                                  0.773010f, 0.881921f, 0.956940f, 0.995185f};

__constant__ float HWINDOW2[] =  {0.049009f, 0.145142f, 0.235698f, 0.317197f,
                                  0.386505f, 0.440961f, 0.478470f, 0.497592f};

__constant__ float HWINDOW_SQ[] = {0.009607f, 0.084265f, 0.222215f, 0.402455f,
                                   0.597545f, 0.777785f, 0.915735f, 0.990393f};
__constant__ float HWINDOW_SQi[] = {104.086869f, 11.867296f, 4.500149f, 2.484751f,
                                      1.673514f, 1.285702f, 1.092019f, 1.009701f};

// Offsets in 8x8 DCT_CC/DST_SC tile for the first 2 lines of the 16x16 bayer image
__constant__ int fold_indx2[2][16] = {{0x24,0x25,0x26,0x27,0x27,0x26,0x25,0x24,0x23,0x22,0x21,0x20,0x20,0x21,0x22,0x23},
                                      {0x2c,0x2d,0x2e,0x2f,0x2f,0x2e,0x2d,0x2c,0x2b,0x2a,0x29,0x28,0x28,0x29,0x2a,0x2b}};

// increments of the offsets in 8x8 tile when going down, jumping two lines (same Bayer). Each 4 bits have to be <<3,
// addd to the current index and result should be AND-ed with 0x3f. inc_e is for even rows (0,2, ...) while inc_o - for odd ones (1,3,)
__constant__ int fold_inc[]=          {0x02feee12, 0x021eeef2};

//__constant__ int imclt_indx[16] = {0x24,0x2c,0x34,0x3c,0x3c,0x34,0x2c,0x24,0x1c,0x22,0x21,0x20,0x20,0x21,0x22,0x23};
//__constant__ int imclt_indx9[16] = {0x28,0x31,0x3a,0x43,0x43,0x3a,0x31,0x28,0x1f,0x16,0x0d,0x04,0x04,0x0d,0x16,0x1f};
__constant__ int imclt_indx9[16] = {0x28,0x29,0x2a,0x2b,0x2b,0x2a,0x29,0x28,0x27,0x26,0x25,0x24,0x24,0x25,0x26,0x27};


// Hope that if 2 outer indices are known at compile time there will be no integer multiplications
__constant__ float idct_signs[4][4][4] ={
		{ // quadrant 0, each elements corresponds to 4x4 pixel output, covering altogether 16x16
				{ 1,-1,-1,-1},
				{-1, 1, 1, 1},
				{-1, 1, 1, 1},
				{-1, 1, 1, 1}
		},{ // quadrant 1, each elements corresponds to 4x4 pixel output, covering altogether 16x16
				{ 1, 1, 1,-1},
				{-1,-1,-1, 1},
				{-1,-1,-1, 1},
				{-1,-1,-1, 1}
		},{ // quadrant 2, each elements corresponds to 4x4 pixel output, covering altogether 16x16
				{ 1,-1,-1,-1},
				{ 1,-1,-1,-1},
				{ 1,-1,-1,-1},
				{-1, 1, 1, 1}
		},{ // quadrant 3, each elements corresponds to 4x4 pixel output, covering altogether 16x16
				{ 1, 1, 1,-1},
				{ 1, 1, 1,-1},
				{ 1, 1, 1,-1},
				{-1,-1,-1, 1}
		}};
// LPF for sigma 0.9 each color (modify through cudaMemcpyToSymbol() or similar in Driver API
//#ifndef NOICLT
__constant__ float lpf_data[4][64]={
		{ // red
				1.00000000f, 0.87041007f, 0.65943687f, 0.43487258f, 0.24970076f, 0.12518080f, 0.05616371f, 0.02728573f,
				0.87041007f, 0.75761368f, 0.57398049f, 0.37851747f, 0.21734206f, 0.10895863f, 0.04888546f, 0.02374977f,
				0.65943687f, 0.57398049f, 0.43485698f, 0.28677101f, 0.16466189f, 0.08254883f, 0.03703642f, 0.01799322f,
				0.43487258f, 0.37851747f, 0.28677101f, 0.18911416f, 0.10858801f, 0.05443770f, 0.02442406f, 0.01186582f,
				0.24970076f, 0.21734206f, 0.16466189f, 0.10858801f, 0.06235047f, 0.03125774f, 0.01402412f, 0.00681327f,
				0.12518080f, 0.10895863f, 0.08254883f, 0.05443770f, 0.03125774f, 0.01567023f, 0.00703062f, 0.00341565f,
				0.05616371f, 0.04888546f, 0.03703642f, 0.02442406f, 0.01402412f, 0.00703062f, 0.00315436f, 0.00153247f,
				0.02728573f, 0.02374977f, 0.01799322f, 0.01186582f, 0.00681327f, 0.00341565f, 0.00153247f, 0.00074451f
		},{ // blue
				1.00000000f, 0.87041007f, 0.65943687f, 0.43487258f, 0.24970076f, 0.12518080f, 0.05616371f, 0.02728573f,
				0.87041007f, 0.75761368f, 0.57398049f, 0.37851747f, 0.21734206f, 0.10895863f, 0.04888546f, 0.02374977f,
				0.65943687f, 0.57398049f, 0.43485698f, 0.28677101f, 0.16466189f, 0.08254883f, 0.03703642f, 0.01799322f,
				0.43487258f, 0.37851747f, 0.28677101f, 0.18911416f, 0.10858801f, 0.05443770f, 0.02442406f, 0.01186582f,
				0.24970076f, 0.21734206f, 0.16466189f, 0.10858801f, 0.06235047f, 0.03125774f, 0.01402412f, 0.00681327f,
				0.12518080f, 0.10895863f, 0.08254883f, 0.05443770f, 0.03125774f, 0.01567023f, 0.00703062f, 0.00341565f,
				0.05616371f, 0.04888546f, 0.03703642f, 0.02442406f, 0.01402412f, 0.00703062f, 0.00315436f, 0.00153247f,
				0.02728573f, 0.02374977f, 0.01799322f, 0.01186582f, 0.00681327f, 0.00341565f, 0.00153247f, 0.00074451f
		},{ // green
				1.00000000f, 0.91166831f, 0.75781950f, 0.57470069f, 0.39864249f, 0.25575500f, 0.15880862f, 0.11071780f,
				0.91166831f, 0.83113910f, 0.69088002f, 0.52393641f, 0.36342972f, 0.23316373f, 0.14478079f, 0.10093791f,
				0.75781950f, 0.69088002f, 0.57429040f, 0.43551939f, 0.30209905f, 0.19381613f, 0.12034827f, 0.08390411f,
				0.57470069f, 0.52393641f, 0.43551939f, 0.33028089f, 0.22910011f, 0.14698258f, 0.09126743f, 0.06362960f,
				0.39864249f, 0.36342972f, 0.30209905f, 0.22910011f, 0.15891583f, 0.10195481f, 0.06330787f, 0.04413682f,
				0.25575500f, 0.23316373f, 0.19381613f, 0.14698258f, 0.10195481f, 0.06541062f, 0.04061610f, 0.02831663f,
				0.15880862f, 0.14478079f, 0.12034827f, 0.09126743f, 0.06330787f, 0.04061610f, 0.02522018f, 0.01758294f,
				0.11071780f, 0.10093791f, 0.08390411f, 0.06362960f, 0.04413682f, 0.02831663f, 0.01758294f, 0.01225843f
		},{ // mono
				1.00000000f, 0.94100932f, 0.83403534f, 0.69821800f, 0.55623487f, 0.42968171f, 0.33580928f, 0.28608280f,
				0.94100932f, 0.88549854f, 0.78483503f, 0.65702965f, 0.52342219f, 0.40433449f, 0.31599966f, 0.26920658f,
				0.83403534f, 0.78483503f, 0.69561495f, 0.58233849f, 0.46391954f, 0.35836973f, 0.28007681f, 0.23860316f,
				0.69821800f, 0.65702965f, 0.58233849f, 0.48750838f, 0.38837320f, 0.30001150f, 0.23446808f, 0.19974816f,
				0.55623487f, 0.52342219f, 0.46391954f, 0.38837320f, 0.30939723f, 0.23900395f, 0.18678883f, 0.15912923f,
				0.42968171f, 0.40433449f, 0.35836973f, 0.30001150f, 0.23900395f, 0.18462637f, 0.14429110f, 0.12292455f,
				0.33580928f, 0.31599966f, 0.28007681f, 0.23446808f, 0.18678883f, 0.14429110f, 0.11276787f, 0.09606926f,
				0.28608280f, 0.26920658f, 0.23860316f, 0.19974816f, 0.15912923f, 0.12292455f, 0.09606926f, 0.08184337f
		}};

__constant__ float lpf_rb_corr[64]={ // modify if needed
				1.00000000f, 0.92598908f, 0.79428680f, 0.63198650f, 0.46862740f, 0.32891038f, 0.22914618f, 0.17771927f,
				0.92598908f, 0.85745578f, 0.73550091f, 0.58521260f, 0.43394386f, 0.30456742f, 0.21218686f, 0.16456610f,
				0.79428680f, 0.73550091f, 0.63089153f, 0.50197854f, 0.37222456f, 0.26124917f, 0.18200779f, 0.14116007f,
				0.63198650f, 0.58521260f, 0.50197854f, 0.39940694f, 0.29616619f, 0.20786692f, 0.14481729f, 0.11231618f,
				0.46862740f, 0.43394386f, 0.37222456f, 0.29616619f, 0.21961164f, 0.15413642f, 0.10738418f, 0.08328412f,
				0.32891038f, 0.30456742f, 0.26124917f, 0.20786692f, 0.15413642f, 0.10818204f, 0.07536856f, 0.05845371f,
				0.22914618f, 0.21218686f, 0.18200779f, 0.14481729f, 0.10738418f, 0.07536856f, 0.05250797f, 0.04072369f,
				0.17771927f, 0.16456610f, 0.14116007f, 0.11231618f, 0.08328412f, 0.05845371f, 0.04072369f, 0.03158414f
		};
__constant__ float lpf_corr[64]={ // modify if needed
				1.00000000f, 0.87041007f, 0.65943687f, 0.43487258f, 0.24970076f, 0.12518080f, 0.05616371f, 0.02728573f,
				0.87041007f, 0.75761368f, 0.57398049f, 0.37851747f, 0.21734206f, 0.10895863f, 0.04888546f, 0.02374977f,
				0.65943687f, 0.57398049f, 0.43485698f, 0.28677101f, 0.16466189f, 0.08254883f, 0.03703642f, 0.01799322f,
				0.43487258f, 0.37851747f, 0.28677101f, 0.18911416f, 0.10858801f, 0.05443770f, 0.02442406f, 0.01186582f,
				0.24970076f, 0.21734206f, 0.16466189f, 0.10858801f, 0.06235047f, 0.03125774f, 0.01402412f, 0.00681327f,
				0.12518080f, 0.10895863f, 0.08254883f, 0.05443770f, 0.03125774f, 0.01567023f, 0.00703062f, 0.00341565f,
				0.05616371f, 0.04888546f, 0.03703642f, 0.02442406f, 0.01402412f, 0.00703062f, 0.00315436f, 0.00153247f,
				0.02728573f, 0.02374977f, 0.01799322f, 0.01186582f, 0.00681327f, 0.00341565f, 0.00153247f, 0.00074451f
		};


__constant__ int pairs[6][2]={
		{0, 1},
		{2, 3},
		{0, 2},
		{1, 3},
		{0, 3},
		{2, 1}};

__constant__ float alphaFade[16][256] = {
    {0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f,
     0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f, 0.000000f},
    {0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f,
     0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f,
     0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f,
     0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f,
     0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f,
     0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f},
    {0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f},
    {0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.997592f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.978470f, 0.997592f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.059039f, 0.059039f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.021530f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f},
    {0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f,
     0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f, 0.002408f,
     0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f,
     0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f, 0.021530f,
     0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f,
     0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f, 0.059039f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {0.002408f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.021530f, 0.021530f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.059039f, 0.059039f, 0.059039f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.113495f, 0.113495f, 0.113495f, 0.113495f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.549009f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.940961f, 0.978470f, 0.997592f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.978470f, 0.997592f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f},
    {0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.997592f, 0.978470f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.059039f, 0.059039f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.021530f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.002408f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.021530f, 0.021530f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.059039f, 0.059039f, 0.059039f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.113495f, 0.113495f, 0.113495f, 0.113495f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.182803f, 0.182803f, 0.182803f, 0.182803f, 0.182803f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f, 0.264302f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f, 0.354858f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f, 0.450991f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.549009f,
     0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f, 0.549009f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.645142f, 0.645142f,
     0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f, 0.645142f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.735698f, 0.735698f, 0.735698f,
     0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f, 0.735698f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f, 0.817197f,
     0.997592f, 0.978470f, 0.940961f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f, 0.886505f,
     0.997592f, 0.978470f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f, 0.940961f,
     0.997592f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f, 0.978470f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f,
     0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f, 0.997592f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f,
     1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f, 1.000000f}};

//#endif
__device__ void convertCorrectTile(
		struct CltExtra     * gpu_kernel_offsets, // [tileY][tileX][color]
		float               * gpu_kernels,        // [tileY][tileX][color]
		float               * gpu_images,
		float               * gpu_clt,
		const int             color,
		const int             lpf_mask,
		const float           centerX,
		const float           centerY,
//		const short          tx,
//		const short          ty,
		const int             txy,
		const size_t          dstride, // in floats (pixels)
		float               * clt_tile, //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float               * clt_kernels, //      [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		int   int_topleft     [2],
		float residual_shift  [2],
	    float window_hor_cos  [2*DTT_SIZE],
	    float window_hor_sin  [2*DTT_SIZE],
	    float window_vert_cos [2*DTT_SIZE]);

__device__ void debug_print_lpf(
		float * lpf_tile);

__device__ void debug_print_clt1(
		float * clt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color,
		int mask);
__device__ void debug_print_clt_scaled(
		float * clt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color,
		int mask,
		float scale); // scale printed results
__device__ void debug_print_mclt(
		float * mclt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color);
__device__ void debug_print_corr_15x15(
		int     corr_radius,
		float * mclt_tile, //DTT_SIZE2M1 x DTT_SIZE2M1
		const int color);
// Fractional pixel shift (phase rotation), horizontal. In-place.
__device__ void shiftTileHor( // implemented, used
		float * clt_tile, //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float residual_shift                         );
// Fractional pixel shift (phase rotation), vertical. In-place.
__device__ void shiftTileVert( // implemented, used
		float *clt_tile, //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float residual_shift                         );
__device__ void convolveTiles( // implemented, used
		float* clt_tile, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
		float* kernel); //      [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the CLT kernel (DTT3 converted)
__device__ void correlateAccumulateTiles(
		float  scale,      //    scale correlation
		float* clt_tile1,  //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 1, rows extended to optimize shared ports
		float* clt_tile2,  //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 2, rows extended to optimize shared ports
		float* corr_tile); //    [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the correlation result
__device__ void resetCorrelation(
		float* corr_tile); //    [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the correlation result
__device__ void normalizeTileAmplitude(
		float * clt_tile, //       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float fat_zero);  // fat zero is absolute, scale it outside
__device__ void corrUnfoldTile(
		int corr_radius,
		float* qdata0, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
		float* rslt);  //   [DTT_SIZE2M1][DTT_SIZE2M1]) // 15x15
//__device__ void imclt(  // implemented, used // why is it twice?
//		float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
//		float * mclt_tile ); //           [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
__device__ void imclt(  // for 16 threads implemented, used // why is it twice?
		float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
		float * mclt_tile ); //           [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
__device__ void imclt8threads(// for 8 threads
		int     do_acc,     // 1 - add to previous value, 0 - overwrite
		float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
		float * mclt_tile,  //           [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		int debug);
__device__ void debayer(
		const int rb_mode,   // 0 - green, 1 - r/b
		float * mclt_src,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float * mclt_dst,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		int debug);

__device__ void debayer_shot(
		const int rb_mode,   // 0 - green, 1 - r/b
		float     min_shot,  // 10.0
		float     shot_corr, // 3.0 (0.0 for mono)
		float   * mclt_src,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float   * mclt_dst,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float   * mclt_tmp,
		int       debug);
__device__ void tile_combine_rgba(
		int     colors,        // number of colors
		float * mclt_tile,     // debayer
		float * rbg_tile,      // if not null - original (not-debayered) rbg tile to use for the output
		float * rgba,          // result
		float * ports_rgb,     // average values of R,G,B for each camera (R0,R1,...,B2,B3) // null
		float * max_diff,      // maximal (weighted) deviation of each channel from the average /null
		float * port_offsets,  // [port]{x_off, y_off} - just to scale pixel value differences
		float   diff_sigma,     // pixel value/pixel change
		float   diff_threshold, // pixel value/pixel change
		float   min_agree,      // minimal number of channels to agree on a point (real number to work with fuzzy averages)
		float * chn_weights,     // color channel weights, sum == 1.0
		int     dust_remove,     // Do not reduce average weight when only one image differes much from the average
		int     keep_weights,   // return channel weights after A in RGBA - ALWAYS
		int     debug
		);


__device__ void imclt_plane( // not implemented, not used
		int               color,
		float           * gpu_clt,   // [TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		float           * gpu_rbg,            // WIDTH, HEIGHT
		const size_t      dstride);            // in floats (pixels)

extern "C"
__global__ void clear_texture_list(
		int              * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		int                width,  // <= TILESX, use for faster processing of LWIR images
		int                height); // <= TILESY, use for faster processing of LWIR images

extern "C"
__global__ void mark_texture_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,            // number of tiles in task list
		int              * gpu_texture_indices); // packed tile + bits (now only (1 << 7)
extern "C"
__global__ void mark_texture_neighbor_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,           // number of tiles in task list
		int              * gpu_texture_indices, // packed tile + bits (now only (1 << 7)
		int              * woi);                // x,y,width,height of the woi
extern "C"
__global__ void gen_texture_list(
		struct tp_task   * gpu_tasks,
		int                num_tiles,           // number of tiles in task list
		int              * gpu_texture_indices, // packed tile + bits (now only (1 << 7)
		int              * num_texture_tiles,  // number of texture tiles to process
		int              * woi);                // x,y,width,height of the woi

extern "C" __global__ void clear_texture_rbga(
		int               texture_width,
		int               texture_slice_height,
		const size_t      texture_rbga_stride,     // in floats 8*stride
		float           * gpu_texture_tiles);  // (number of colors +1 + ?)*16*16 rgba texture tiles
extern "C" __global__ void textures_accumulate(
//		int               border_tile,        // if 1 - watch for border
		int             * woi,                // x, y, width,height
		float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		size_t            num_texture_tiles,  // number of texture tiles to process
		int             * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		float           * gpu_port_offsets,       // relative ports x,y offsets - just to scale differences, may be approximate
		int               colors,             // number of colors (3/1)
		int               is_lwir,            // do not perform shot correction
		float             min_shot,           // 10.0
		float             scale_shot,         // 3.0
		float             diff_sigma,         // pixel value/pixel change
		float             diff_threshold,     // pixel value/pixel change
		float             min_agree,          // minimal number of channels to agree on a point (real number to work with fuzzy averages)
		float             weight0,            // scale for R
		float             weight1,            // scale for B
		float             weight2,            // scale for G
		int               dust_remove,        // Do not reduce average weight when only one image differs much from the average
		int               keep_weights,       // return channel weights after A in RGBA (was removed) (should be 0 if gpu_texture_rbg)?
// combining both non-overlap and overlap (each calculated if pointer is not null )
		size_t            texture_rbg_stride, // in floats
		float           * gpu_texture_rbg,    // (number of colors +1 + ?)*16*16 rgba texture tiles
		size_t            texture_stride,     // in floats (now 256*4 = 1024)
		float           * gpu_texture_tiles); // (number of colors +1 + ?)*16*16 rgba texture tiles

extern "C"
__global__ void correlate2D(
		float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		int               colors,             // number of colors (3/1)
		float             scale0,             // scale for R
		float             scale1,             // scale for B
		float             scale2,             // scale for G
		float             fat_zero,           // here - absolute
		size_t            num_corr_tiles,     // number of correlation tiles to process
		int             * gpu_corr_indices,   // packed tile+pair
		const size_t      corr_stride,        // in floats
		int               corr_radius,        // radius of the output correlation (7 for 15x15)
		float           * gpu_corrs)          // correlation output data
{
///	int thr3 =        threadIdx.x >> 3; // now zero?
///	int column =      threadIdx.x; // modify to use 2 * 8 threads, if needed.
	float scales[3] = {scale0, scale1, scale2};
	int corr_in_block = threadIdx.y;
	int corr_num = blockIdx.x * CORR_TILES_PER_BLOCK + corr_in_block;
	if (corr_num >= num_corr_tiles){
		return; // nothing to do
	}
	// get number of pair and number of tile
	int corr_pair = gpu_corr_indices[corr_num];
	int tile_num = corr_pair >> CORR_NTILE_SHIFT;
	corr_pair &= (corr_pair & ((1 << CORR_NTILE_SHIFT) - 1));
	if (corr_pair > NUM_PAIRS){
		return; // BUG - should not happen
	}
	int cam1 = pairs[corr_pair][0]; // number of the first camera in a pair
	int cam2 = pairs[corr_pair][1]; // number of the first camera in a pair
    __syncthreads();// __syncwarp();
    __shared__ float clt_tiles1  [CORR_TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float clt_tiles2  [CORR_TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float clt_corrs   [CORR_TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float mlt_corrs   [CORR_TILES_PER_BLOCK][DTT_SIZE2M1][DTT_SIZE2M1]; // result correlation
    // set clt_corr to all zeros
    float * clt_corr =  ((float *) clt_corrs) +  corr_in_block * (4 * DTT_SIZE * DTT_SIZE1); // top left quadrant0
    float * mclt_corr = ((float *) mlt_corrs) +  corr_in_block * (DTT_SIZE2M1*DTT_SIZE2M1);
    resetCorrelation(clt_corr);
    for (int color = 0; color < colors; color++){
        // copy clt (frequency domain data)
        float * clt_tile1 = ((float *) clt_tiles1) +  corr_in_block * (4 * DTT_SIZE * DTT_SIZE1);
        float * clt_tile2 = ((float *) clt_tiles2) +  corr_in_block * (4 * DTT_SIZE * DTT_SIZE1);
        int offs = (tile_num * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE) + threadIdx.x;
        float * gpu_tile1 = ((float *) gpu_clt[cam1]) + offs;
        float * gpu_tile2 = ((float *) gpu_clt[cam2]) + offs;
		float * clt_tile1i = clt_tile1 + threadIdx.x;
		float * clt_tile2i = clt_tile2 + threadIdx.x;
#pragma unroll
		for (int i = 0; i < DTT_SIZE4; i++){ // copy 32 rows (4 quadrants of 8 rows)
			*clt_tile1i= *gpu_tile1;
			*clt_tile2i= *gpu_tile2;
			clt_tile1i += DTT_SIZE1;
			clt_tile2i += DTT_SIZE1;
			gpu_tile1 += DTT_SIZE;
			gpu_tile2 += DTT_SIZE;
		}
		__syncthreads();
#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D tile = %d, pair=%d, color = %d   CAMERA1\n",tile_num, corr_pair,color);
    	debug_print_clt1(clt_tile1, color,  0xf); //
        printf("\ncorrelate2D tile = %d, pair=%d, color = %d   CAMERA2\n",tile_num, corr_pair,color);
    	debug_print_clt1(clt_tile2, color,  0xf); //
    }
     __syncthreads();// __syncwarp();
#endif
#endif
		// each thread should get the same pointers here, offsets are inside
        correlateAccumulateTiles(
        		scales[color], // float  scale,     // scale correlation
				clt_tile1, // float* clt_tile1, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 1, rows extended to optimize shared ports
				clt_tile2, // float* clt_tile2, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 2, rows extended to optimize shared ports
				clt_corr); // float* corr_tile) //    [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the correlation result
        __syncthreads();

#ifdef DBG_TILE
#ifdef DEBUG6
        if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        	printf("\ncorrelate2D, color = %d CORRELATION\n", color);
        	debug_print_clt1(clt_corr, color,  0xf);
        }
        __syncthreads();// __syncwarp();
#endif
#endif
        if (color == 1){ // LPF only after B (nothing in mono)

#ifdef DBG_TILE
#ifdef DEBUG6
        	if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        		printf("\ncorrelate2D LPF for RB correlation\n");
        		debug_print_lpf(lpf_rb_corr);
        	}
        	__syncthreads();// __syncwarp();
#endif
#endif

        	float *clt = clt_corr + threadIdx.x;
#pragma unroll
        	for (int q = 0; q < 4; q++){
        		float *lpf_rb = lpf_rb_corr + threadIdx.x;
#pragma unroll
        		for (int i = 0; i < DTT_SIZE; i++){
        			(*clt) *= (*lpf_rb);
        			clt    += DTT_SIZE1;
        			lpf_rb += DTT_SIZE;
        		}
        	}
        	__syncthreads();// __syncwarp();
#ifdef DBG_TILE
#ifdef DEBUG6
        	if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        		printf("\ncorrelate2D CORRELATION RB LPF-ed\n");
        		debug_print_clt1(clt_corr, -1,  0xf);
        	}
        	__syncthreads();// __syncwarp();
#endif
#endif








        } // if (color == 1){ // LPF only after B (nothing in mono)




    } // for (int color = 0; color < colors; color++){
    normalizeTileAmplitude(
    		clt_corr, // float * clt_tile, //       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
			fat_zero); // float fat_zero ) // fat zero is absolute, scale it outside
// Low Pass Filter from constant area (is it possible to replace?)

#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D CORRELATION NORMALIZED, fat_zero=%f\n",fat_zero);
    	debug_print_clt1(clt_corr, -1,  0xf);
    }
     __syncthreads();// __syncwarp();
#endif
#endif


#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D LPF\n");
        debug_print_lpf(lpf_corr);
    }
     __syncthreads();// __syncwarp();
#endif
#endif



    float *clt = clt_corr + threadIdx.x;
#pragma unroll
    for (int q = 0; q < 4; q++){
		float *lpf = lpf_corr + threadIdx.x;
#pragma unroll
    	for (int i = 0; i < DTT_SIZE; i++){
    		(*clt) *= (*lpf);
    		clt   += DTT_SIZE1;
    		lpf   += DTT_SIZE;
    	}
    }
    __syncthreads();// __syncwarp();
#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D CORRELATION LPF-ed\n");
    	debug_print_clt1(clt_corr, -1,  0xf);
    }
     __syncthreads();// __syncwarp();
#endif
#endif

/*
Java code:
     	for (int quadrant = 0; quadrant < 4; quadrant++){
    		int mode = ((quadrant << 1) & 2) | ((quadrant >> 1) & 1); // transpose
    		tcorr[first_col][quadrant] = dtt.dttt_iie(tcorr[first_col][quadrant], mode, transform_size);
    	}
 */
    // change to 16-32 threads?? in next iteration
    // vert pass (hor pass in Java, before transpose. Here transposed, no transform needed)
    for (int q = 0; q < 4; q++){
    	int is_sin = (q >> 1) & 1;
    	dttii_shared_mem_nonortho(clt_corr + q * (DTT_SIZE1 * DTT_SIZE) + threadIdx.x , DTT_SIZE1, is_sin); // vertical pass, thread is column
    }
    __syncthreads();
#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D AFTER VERTICAL (HORIZONTAL) PASS\n");
    	debug_print_clt1(clt_corr, -1,  0xf);
    }
     __syncthreads();// __syncwarp();
#endif
#endif

    // hor pass, corresponding to vert pass in Java
    for (int q = 0; q < 4; q++){
    	int is_sin = q & 1;
    	dttii_shared_mem_nonortho(clt_corr + (q * DTT_SIZE + threadIdx.x) * DTT_SIZE1 ,  1, is_sin); // horizontal pass, tread is row
    }
    __syncthreads();
#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 4)){
        printf("\ncorrelate2D AFTER HOSIZONTAL (VERTICAL) PASS, corr_radius=%d\n",corr_radius);
    	debug_print_clt1(clt_corr, -1,  0xf);
    }
     __syncthreads();// __syncwarp();

#endif
#endif

     corrUnfoldTile(
    		 corr_radius, // int corr_radius,
			 (float *) clt_corr,  // float* qdata0, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
			 (float *) mclt_corr); // float* rslt)  //   [DTT_SIZE2M1][DTT_SIZE2M1]) // 15x15

     __syncthreads();

#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D after UNFOLD, corr_radius=%d\n",corr_radius);
    	debug_print_corr_15x15(
    			corr_radius, // int     corr_radius,
    			mclt_corr,
				-1);
    }
     __syncthreads();// __syncwarp();
#endif
#endif

    // copy 15x15 tile to main memory (2 * corr_radius +1) x (2 * corr_radius +1)
 	int size2r1 = 2 * corr_radius + 1;
 	int len2r1x2r1 = size2r1 * size2r1;
    int corr_tile_offset =  + corr_stride * corr_num;
    float *mem_corr = gpu_corrs + corr_tile_offset;
#pragma unroll
//    for (int offs = threadIdx.x; offs < DTT_SIZE2M1*DTT_SIZE2M1; offs+=CORR_THREADS_PER_TILE){ // variable number of cycles per thread
    for (int offs = threadIdx.x; offs < len2r1x2r1; offs+=CORR_THREADS_PER_TILE){ // variable number of cycles per thread
    	mem_corr[offs] = mclt_corr[offs];
    }

    __syncthreads();
#ifdef DBG_TILE
#ifdef DEBUG6
    if ((tile_num == DBG_TILE) && (corr_pair == 0) && (threadIdx.x == 0)){
        printf("\ncorrelate2D after copy to main memory\n");
//    	debug_print_clt1(clt_corr, -1,  0xf);
    }
     __syncthreads();// __syncwarp();
#endif
#endif

}
#define USE_CDP
#ifdef USE_CDP
extern "C"
__global__ void generate_RBGA(
// Parameters to generate texture tasks
			struct tp_task   * gpu_tasks,
			int                num_tiles,          // number of tiles in task list
// declare arrays in device code?
			int              * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
			int              * num_texture_tiles,  // number of texture tiles to process  (8 separate elements for accumulation)
			int              * woi,                // x,y,width,height of the woi
			int                width,  // <= TILESX, use for faster processing of LWIR images (should be actual + 1)
			int                height, // <= TILESY, use for faster processing of LWIR images
// Parameters for the texture generation
			float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
			float           * gpu_port_offsets,       // relative ports x,y offsets - just to scale differences, may be approximate
			int               colors,             // number of colors (3/1)
			int               is_lwir,            // do not perform shot correction
			float             min_shot,           // 10.0
			float             scale_shot,         // 3.0
			float             diff_sigma,         // pixel value/pixel change
			float             diff_threshold,     // pixel value/pixel change
			float             min_agree,          // minimal number of channels to agree on a point (real number to work with fuzzy averages)
			float             weight0,            // scale for R
			float             weight1,            // scale for B
			float             weight2,            // scale for G
			int               dust_remove,        // Do not reduce average weight when only one image differs much from the average
			int               keep_weights,       // return channel weights after A in RGBA (was removed)
			const size_t      texture_rbga_stride,     // in floats
			float           * gpu_texture_tiles)  // (number of colors +1 + ?)*16*16 rgba texture tiles
{
// TODO use atomic_add to increment	num_texture_tiles
// TODO calculate woi
    dim3 threads0((1 << THREADS_DYNAMIC_BITS), 1, 1);
    int blocks_x = (width + ((1 << THREADS_DYNAMIC_BITS) - 1)) >> THREADS_DYNAMIC_BITS;
    dim3 blocks0 (blocks_x, height, 1);

	if (threadIdx.x == 0) {
		clear_texture_list<<<blocks0,threads0>>>(
				gpu_texture_indices,
				width,
				height);
		cudaDeviceSynchronize(); // not needed yet, just for testing
		dim3 threads((1 << THREADS_DYNAMIC_BITS), 1, 1);
		int blocks_t =   (num_tiles + ((1 << THREADS_DYNAMIC_BITS)) -1) >> THREADS_DYNAMIC_BITS;//
	    dim3 blocks(blocks_t, 1, 1);
	    // mark used tiles in gpu_texture_indices memory
		mark_texture_tiles <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,          // number of tiles in task list
				gpu_texture_indices); // packed tile + bits (now only (1 << 7)
		cudaDeviceSynchronize();
	    // mark n/e/s/w used tiles from gpu_texture_indices memory to gpu_tasks lower 4 bits
		*(woi + 0) = TILESX;
		*(woi + 1) = TILESY;
		*(woi + 2) = 0; // maximal x
		*(woi + 3) = 0; // maximal y
		mark_texture_neighbor_tiles <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,           // number of tiles in task list
				gpu_texture_indices, // packed tile + bits (now only (1 << 7)
				woi);               // min_x, min_y, max_x, max_y
// REMOVE when done!
/*
		*(woi + 0) -= 1;
		*(woi + 1) -= 1;
		*(woi + 2) += 1;
		*(woi + 3) += 1;
*/


		cudaDeviceSynchronize();
	    // Generate tile indices list, upper 24 bits - tile index, lower 4 bits: n/e/s/w neighbors, bit 7 - set to 1
		*(num_texture_tiles+0) = 0;
		*(num_texture_tiles+1) = 0;
		*(num_texture_tiles+2) = 0;
		*(num_texture_tiles+3) = 0;
		*(num_texture_tiles+4) = 0;
		*(num_texture_tiles+5) = 0;
		*(num_texture_tiles+6) = 0;
		*(num_texture_tiles+7) = 0;

		gen_texture_list <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,          // number of tiles in task list
				gpu_texture_indices,// packed tile + bits (now only (1 << 7)
				num_texture_tiles,  // number of texture tiles to process
				woi);               // x,y, here woi[2] = max_X, woi[3] - max-Y

		cudaDeviceSynchronize(); // not needed yet, just for testing
		*(woi + 2) += 1 - *(woi + 0); // width
		*(woi + 3) += 1 - *(woi + 1); // height
	}
	 __syncthreads();
// Zero output textures. Trim
// texture_rbga_stride
	 int texture_width =        (*(woi + 2) + 1)* DTT_SIZE;
	 int texture_tiles_height = (*(woi + 3) + 1) * DTT_SIZE;
///	 int texture_height =       texture_tiles_height * DTT_SIZE;
	 int texture_slices =       colors + 1;

	 if (threadIdx.x == 0) {
		 //DTT_SIZE_LOG2
//		    dim3 threads2((1 << THREADS_DYNAMIC_BITS), 1, 1);
//		    int blocks_x = (texture_width + ((1 << THREADS_DYNAMIC_BITS) - 1)) >> THREADS_DYNAMIC_BITS;
//		    dim3 blocks2 (blocks_x, texture_tiles_height * texture_slices, 1); // each thread - 8 vertical

		    dim3 threads2((1 << THREADS_DYNAMIC_BITS), 1, 1);
		    int blocks_x = (texture_width + ((1 << (THREADS_DYNAMIC_BITS + DTT_SIZE_LOG2 )) - 1)) >> (THREADS_DYNAMIC_BITS + DTT_SIZE_LOG2);
		    dim3 blocks2 (blocks_x, texture_tiles_height * texture_slices, 1); // each thread - 8 vertical
		    clear_texture_rbga<<<blocks2,threads2>>>( // illegal value error
		    		texture_width,
					texture_tiles_height * texture_slices, // int               texture_slice_height,
					texture_rbga_stride,                   // const size_t      texture_rbga_stride,     // in floats 8*stride
					gpu_texture_tiles) ;                   // float           * gpu_texture_tiles);
// Run 8 times - first 4 1-tile offsets  inner tiles (w/o verifying margins), then - 4 times with verification and ignoring 4-pixel
// oversize (border 16x116 tiles overhang by 4 pixels)
			cudaDeviceSynchronize(); // not needed yet, just for testing
			for (int pass = 0; pass < 8; pass++){
			    dim3 threads_texture(TEXTURE_THREADS_PER_TILE, NUM_CAMS, 1); // TEXTURE_TILES_PER_BLOCK, 1);
			    int border_tile =  pass >> 2;
			    int ntt = *(num_texture_tiles + ((pass & 3) << 1) + border_tile);
			    dim3 grid_texture((ntt + TEXTURE_TILES_PER_BLOCK-1) / TEXTURE_TILES_PER_BLOCK,1,1);
			    int ti_offset = (pass & 3) * (TILESX * (TILESYA >> 2));  // 1/4
			    if (border_tile){
			    	ti_offset += TILESX * (TILESYA >> 2) - ntt;
			    }
#ifdef DEBUG12
				printf("\ngenerate_RBGA() pass= %d, border_tile= %d, ti_offset= %d, ntt=%d\n",
						pass, border_tile,ti_offset, ntt);
				printf("\ngenerate_RBGA() gpu_texture_indices= %p, gpu_texture_indices + ti_offset= %p\n",
						(void *) gpu_texture_indices, (void *) (gpu_texture_indices + ti_offset));
				printf("\ngenerate_RBGA() grid_texture={%d, %d, %d)\n",
						grid_texture.x, grid_texture.y, grid_texture.z);
				printf("\ngenerate_RBGA() threads_texture={%d, %d, %d)\n",
						threads_texture.x, threads_texture.y, threads_texture.z);
				printf("\n");
#endif
			    /* */
			    textures_accumulate<<<grid_texture,threads_texture>>>(
			    		// get rid of border tile
//			    		border_tile,                     // int               border_tile,        // if 1 - watch for border
			    		woi,                             // int             * woi,                // x, y, width,height
						gpu_clt,                         // float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
						ntt,                             // size_t            num_texture_tiles,  // number of texture tiles to process
						gpu_texture_indices + ti_offset, // int             * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
						gpu_port_offsets,                // float           * gpu_port_offsets,       // relative ports x,y offsets - just to scale differences, may be approximate
						colors,                          // int               colors,             // number of colors (3/1)
						is_lwir,                         // int               is_lwir,            // do not perform shot correction
						min_shot,                        // float             min_shot,           // 10.0
						scale_shot,                      // float             scale_shot,         // 3.0
						diff_sigma,                      // float             diff_sigma,         // pixel value/pixel change
						diff_threshold,                  // float             diff_threshold,     // pixel value/pixel change
						min_agree,                       // float             min_agree,          // minimal number of channels to agree on a point (real number to work with fuzzy averages)
						weight0,                         // float             weight0,            // scale for R
						weight1,                         // float             weight1,            // scale for B
						weight2,                         // float             weight2,            // scale for G
						dust_remove,                     // int               dust_remove,        // Do not reduce average weight when only one image differs much from the average
			    		0,                               // int               keep_weights,       // return channel weights after A in RGBA (was removed) (should be 0 if gpu_texture_rbg)?
			    // combining both non-overlap and overlap (each calculated if pointer is not null )
						texture_rbga_stride,             // size_t      texture_rbg_stride, // in floats
						gpu_texture_tiles,               // float           * gpu_texture_rbg,     // (number of colors +1 + ?)*16*16 rgba texture tiles
			    		0,                               // size_t      texture_stride,     // in floats (now 256*4 = 1024)
						gpu_texture_tiles); // (float *) 0 );                   // float           * gpu_texture_tiles);  // (number of colors +1 + ?)*16*16 rgba texture tiles
				cudaDeviceSynchronize(); // not needed yet, just for testing
				/* */
			}

	 }
	 __syncthreads();

}

// blockDim.x * gridDim.x >= width
extern "C" __global__ void clear_texture_rbga(
		int               texture_width, // aligned to DTT_SIZE
		int               texture_slice_height,
		const size_t      texture_rbga_stride,     // in floats 8*stride
		float           * gpu_texture_tiles)  // (number of colors +1 + ?)*16*16 rgba texture tiles
{
	int col = (blockDim.x * blockIdx.x + threadIdx.x) << DTT_SIZE_LOG2;
	if (col > texture_width) {
		return;
	}
	int row = blockIdx.y;; // includes slices
	float * pix = gpu_texture_tiles + col + row * texture_rbga_stride;
#pragma unroll
	for (int n = 0; n < DTT_SIZE; n++) {
		*(pix++) = 0.0;
	}
}




/**
 * prepare list of texture tiles, woi, and calculate orthogonal neighbors for tiles (in 4 bits of the task field
 * use 4x8=32 threads,
 */
extern "C"
__global__ void prepare_texture_list(
			struct tp_task   * gpu_tasks,
			int                num_tiles,          // number of tiles in task list
			int              * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
			// modified to have 8 length - split each subsequence into non-border/border tiles. Non-border will grow up,
			// border - down from the sam3\e 1/4 of the buffer
			int              * num_texture_tiles,  // number of texture tiles to process  (4 separate elements for accumulation)
			int              * woi,                // x,y,width,height of the woi
			int                width,  // <= TILESX, use for faster processing of LWIR images (should be actual + 1)
			int                height) // <= TILESY, use for faster processing of LWIR images
{
// TODO use atomic_add to increment	num_texture_tiles
// TODO calculate woi
//	int task_num = blockIdx.x;
//	int tid = threadIdx.x; // maybe it will be just <<<1,1>>>
    dim3 threads0((1 << THREADS_DYNAMIC_BITS), 1, 1);
//    int blocks_x = (width + 1) >> THREADS_DYNAMIC_BITS;
    int blocks_x = (width + ((1 << THREADS_DYNAMIC_BITS) - 1)) >> THREADS_DYNAMIC_BITS;

    dim3 blocks0 (blocks_x, height, 1);

	if (threadIdx.x == 0) {
		clear_texture_list<<<blocks0,threads0>>>(
				gpu_texture_indices,
				width,
				height);
		cudaDeviceSynchronize(); // not needed yet, just for testing
		dim3 threads((1 << THREADS_DYNAMIC_BITS), 1, 1);
		int blocks_t =   (num_tiles + ((1 << THREADS_DYNAMIC_BITS)) -1) >> THREADS_DYNAMIC_BITS;//
	    dim3 blocks(blocks_t, 1, 1);
	    // mark used tiles in gpu_texture_indices memory
		mark_texture_tiles <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,          // number of tiles in task list
				gpu_texture_indices); // packed tile + bits (now only (1 << 7)
		cudaDeviceSynchronize();
	    // mark n/e/s/w used tiles from gpu_texture_indices memory to gpu_tasks lower 4 bits
		*(woi + 0) = TILESX;
		*(woi + 1) = TILESY;
		*(woi + 2) = 0; // maximal x
		*(woi + 3) = 0; // maximal y
		mark_texture_neighbor_tiles <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,           // number of tiles in task list
				gpu_texture_indices, // packed tile + bits (now only (1 << 7)
				woi);               // min_x, min_y, max_x, max_y
		cudaDeviceSynchronize();
	    // Generate tile indices list, upper 24 bits - tile index, lower 4 bits: n/e/s/w neighbors, bit 7 - set to 1
		*(num_texture_tiles+0) = 0;
		*(num_texture_tiles+1) = 0;
		*(num_texture_tiles+2) = 0;
		*(num_texture_tiles+3) = 0;
		*(num_texture_tiles+4) = 0;
		*(num_texture_tiles+5) = 0;
		*(num_texture_tiles+6) = 0;
		*(num_texture_tiles+7) = 0;

		gen_texture_list <<<blocks,threads>>>(
				gpu_tasks,
				num_tiles,          // number of tiles in task list
				gpu_texture_indices,// packed tile + bits (now only (1 << 7)
				num_texture_tiles,  // number of texture tiles to process
				woi);               // x,y, here woi[2] = max_X, woi[3] - max-Y

		cudaDeviceSynchronize(); // not needed yet, just for testing
		*(woi + 2) += 1 - *(woi + 0); // width
		*(woi + 3) += 1 - *(woi + 1); // height
	}
	 __syncthreads();
}

// blockDim.x * gridDim.x >= width
extern "C"
__global__ void clear_texture_list(
		int              * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		int                width,  // <= TILESX, use for faster processing of LWIR images
		int                height) // <= TILESY, use for faster processing of LWIR images
{
	int col = blockDim.x * blockIdx.x + threadIdx.x;
	int row = blockIdx.y;
	if (col > width) {
		return;
	}
	*(gpu_texture_indices + col + row * TILESX) = 0;
}

// treads (*,1,1), blocks = (*,1,1)
extern "C"
__global__ void mark_texture_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,           // number of tiles in task list
		int              * gpu_texture_indices) // packed tile + bits (now only (1 << 7)
{
	int task_num = blockDim.x * blockIdx.x + threadIdx.x;
	if (task_num >= num_tiles) {
		return; // nothing to do
	}
	int task = gpu_tasks[task_num].task;
	if (!(task & TASK_TEXTURE_BITS)){ // here any bit in TASK_TEXTURE_BITS is sufficient
		return; // NOP tile
	}
	int cxy = gpu_tasks[task_num].txy;
	*(gpu_texture_indices + (cxy & 0xffff) + (cxy >> 16) * TILESX) = 1;
}


// treads (*,1,1), blocks = (*,1,1)
extern "C"
__global__ void mark_texture_neighbor_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,           // number of tiles in task list
		int              * gpu_texture_indices, // packed tile + bits (now only (1 << 7)
		int              * woi)                  // x,y,width,height of the woi

{
	int task_num = blockDim.x * blockIdx.x + threadIdx.x;
	if (task_num >= num_tiles) {
		return; // nothing to do
	}
//	struct tp_task  * gpu_task = &gpu_tasks[task_num];
//	int task = gpu_task->task;
	int task = gpu_tasks[task_num].task;
	if (!(task & TASK_TEXTURE_BITS)){ // here any bit in TASK_TEXTURE_BITS is sufficient
		return; // NOP tile
	}
//	int cxy = gpu_task->txy;
	int cxy = gpu_tasks[task_num].txy;
	int x = (cxy & 0xffff);
	int y = (cxy >> 16);
	atomicMin(woi+0, x);
	atomicMin(woi+1, y);
	atomicMax(woi+2, x);
	atomicMax(woi+3, y);
	int d = 0;
	if ((y > 0)            && *(gpu_texture_indices +  x +     (y - 1) * TILESX)) d |= (1 << TASK_TEXTURE_N_BIT);
	if ((x < (TILESX - 1)) && *(gpu_texture_indices + (x + 1) + y *      TILESX)) d |= (1 << TASK_TEXTURE_E_BIT);
	if ((y < (TILESY - 1)) && *(gpu_texture_indices +  x +     (y + 1) * TILESX)) d |= (1 << TASK_TEXTURE_S_BIT);
	if ((x > 0)            && *(gpu_texture_indices + (x - 1) + y *      TILESX)) d |= (1 << TASK_TEXTURE_W_BIT);
	gpu_tasks[task_num].task = ((task ^ d) & TASK_TEXTURE_BITS) ^ task;
}

extern "C"
__global__ void gen_texture_list(
		struct tp_task   * gpu_tasks,
		int                num_tiles,            // number of tiles in task list
		int              * gpu_texture_indices, // packed tile + bits (now only (1 << 7)
		int              * num_texture_tiles,    // number of texture tiles to process
		int              * woi)                  // min_x, min_y, max_x, max_y input

{
	int task_num = blockDim.x * blockIdx.x + threadIdx.x;
	if (task_num >= num_tiles) {
		return; // nothing to do
	}

	int task = gpu_tasks[task_num].task & TASK_TEXTURE_BITS;
	if (!task){ // here any bit in TASK_TEXTURE_BITS is sufficient
		return; // NOP tile
	}
	int cxy = gpu_tasks[task_num].txy;
	int x = (cxy & 0xffff);
	int y = (cxy >> 16);

#ifdef DEBUG12
		if ((x == DBG_TILE_X)  && (y == DBG_TILE_Y)){
			printf("\ngen_texture_list() x = %d, y= %d\n",x, y);
			printf("\ngen_texture_list() num_texture_tiles = %d(%d) %d(%d) %d(%d) %d(%d)\n",
					num_texture_tiles[0],num_texture_tiles[1],num_texture_tiles[2],num_texture_tiles[3],
					num_texture_tiles[4],num_texture_tiles[5],num_texture_tiles[6],num_texture_tiles[7]);
		}
		__syncthreads();// __syncwarp();
#endif // DEBUG12


//	int is_border = (x == woi[0]) || (y == woi[1]) || (x == woi[2]) || (y == woi[3]);
	// don't care if calculate extra pixels that still fit into memory
//	int is_border = (x == woi[0]) || (y == woi[1]) || (x == (TILESX - 1)) || (y == (TILESY - 1));
	int is_border = (x == woi[0]) || (y == woi[1]) || (x == (TILESX - 1)) || (y == woi[3]);
	int buff_head = 0;
	int num_offset = 0;
	if (x & 1) {
		buff_head += TILESX * (TILESYA >> 2); //TILESYA - 2 LSB == 00
		num_offset += 2; // int *
	}
	if (y & 1) {
		buff_head += TILESX * (TILESYA >> 1);
		num_offset += 4; // int *
	}
	if (is_border){
		buff_head += (TILESX * (TILESYA >> 2) - 1); // end of the buffer
		num_offset += 1; // int *
	}
	gpu_texture_indices += buff_head;
	num_texture_tiles += num_offset;
	// using atomic operation in global memory - slow, but as operations here are per-til, not per- pixel, it should be OK
	int buf_offset = atomicAdd(num_texture_tiles, 1);
	if (is_border){
		buf_offset = -buf_offset;
	}
#ifdef DEBUG12
	if ((x == DBG_TILE_X)  && (y == DBG_TILE_Y)){
		printf("\ngen_texture_list() buff_head=%d, buf_offset = %d, num_offset= %d, is_border=%d\n",
				buff_head, buf_offset, num_offset,is_border);
		printf("\ngen_texture_list() gpu_texture_indices = %p,  gpu_texture_indices + buf_offset = %p\n",
				(void *) gpu_texture_indices, (void *) (gpu_texture_indices + buf_offset));
	}
	__syncthreads();// __syncwarp();
#endif // DEBUG12
	*(gpu_texture_indices + buf_offset) = task | ((x + y * TILESX) << CORR_NTILE_SHIFT) | (1 << LIST_TEXTURE_BIT);
}

#endif //#ifdef USE_CDP



extern "C"
__global__ void convert_correct_tiles(
//		struct CltExtra ** gpu_kernel_offsets, // [NUM_CAMS], // changed for jcuda to avoid struct parameters
			float           ** gpu_kernel_offsets, // [NUM_CAMS],
			float           ** gpu_kernels,        // [NUM_CAMS],
			float           ** gpu_images,         // [NUM_CAMS],
			struct tp_task   * gpu_tasks,
			float           ** gpu_clt,            // [NUM_CAMS][TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
			size_t             dstride,            // in floats (pixels)
			int                num_tiles,          // number of tiles in task
			int                lpf_mask)           // apply lpf to colors : bit 0 - red, bit 1 - blue, bit2 - green. Now - always 0 !
{
	dim3 t = threadIdx;
	int tile_in_block = threadIdx.y;
	int task_num = blockIdx.x * TILES_PER_BLOCK + tile_in_block;
	if (task_num >= num_tiles) return; // nothing to do
	struct tp_task  * gpu_task = &gpu_tasks[task_num];
	if (!gpu_task->task)       return; // NOP tile
	__shared__ struct tp_task tt [TILES_PER_BLOCK];
	// Copy task data to shared memory
	tt[tile_in_block].task =          gpu_task -> task;
	tt[tile_in_block].txy =           gpu_task -> txy;
	int thread0 =  threadIdx.x & 1;
	int thread12 = threadIdx.x >>1;
	if (thread12 < NUM_CAMS) {
		tt[tile_in_block].xy[thread12][thread0] = gpu_task -> xy[thread12][thread0];
	}
	if (NUM_CAMS > 4){ // unlikely
#pragma unroll
		for (int nc0 = 4; nc0 < NUM_CAMS; nc0 += 4){
			int nc = nc0 + thread12;
			if (nc < NUM_CAMS) {
				tt[tile_in_block].xy[nc][thread0] = gpu_task -> xy[nc][thread0];
			}
		}
	}
#pragma unroll
	for (int i = 0; i < (NUM_CAMS / 4); i++){
		int nc = (threadIdx.x >> 1) + (i << 2);
		if (nc < NUM_CAMS) {
			tt[tile_in_block].xy[nc][0] = gpu_task -> xy[nc][0];
			tt[tile_in_block].xy[nc][1] = gpu_task -> xy[nc][1];
		}

	}
     __syncthreads();// __syncwarp();
    __shared__ float clt_tile        [TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float clt_kernels     [TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1]; // +1 to alternate column ports
    __shared__ int   int_topleft     [TILES_PER_BLOCK][2];
    __shared__ float residual_shift  [TILES_PER_BLOCK][2];
    __shared__ float window_hor_cos  [TILES_PER_BLOCK][2*DTT_SIZE];
    __shared__ float window_hor_sin  [TILES_PER_BLOCK][2*DTT_SIZE];
    __shared__ float window_vert_cos [TILES_PER_BLOCK][2*DTT_SIZE];

    // process each camera,l each color in series (to reduce shared memory)
    for (int ncam = 0; ncam <  NUM_CAMS; ncam++){
    	for (int color = 0; color <  NUM_COLORS; color++){
    		convertCorrectTile(
    				(struct CltExtra*)(gpu_kernel_offsets[ncam]),        // struct CltExtra* gpu_kernel_offsets,
					gpu_kernels[ncam],               // float           * gpu_kernels,
					gpu_images[ncam],                // float           * gpu_images,
					gpu_clt[ncam],                   // float           * gpu_clt,
					color,                           // const int         color,
					lpf_mask,                        // const int         lpf_mask,
					tt[tile_in_block].xy[ncam][0],   // const float       centerX,
					tt[tile_in_block].xy[ncam][1],   // const float       centerY,
					tt[tile_in_block].txy,           //  const int txy,
					dstride,                         // size_t            dstride, // in floats (pixels)
					(float * )(clt_tile [tile_in_block]),        // float clt_tile [TILES_PER_BLOCK][NUM_CAMS][NUM_COLORS][4][DTT_SIZE][DTT_SIZE])
					(float * )(clt_kernels[tile_in_block]),      // float clt_tile    [NUM_COLORS][4][DTT_SIZE][DTT_SIZE],
					int_topleft[tile_in_block],      // int   int_topleft  [NUM_COLORS][2],
					residual_shift[tile_in_block],   // float frac_topleft [NUM_COLORS][2],
					window_hor_cos[tile_in_block],   // float window_hor_cos  [NUM_COLORS][2*DTT_SIZE],
					window_hor_sin[tile_in_block],   //float window_hor_sin  [NUM_COLORS][2*DTT_SIZE],
					window_vert_cos[tile_in_block]); //float window_vert_cos [NUM_COLORS][2*DTT_SIZE]);
    		 __syncthreads();// __syncwarp();
    	}
    }
}

//#undef USE_textures_gen
#ifdef USE_textures_gen
extern "C"
__global__ void textures_gen(
		float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		size_t            num_texture_tiles,  // number of texture tiles to process
		int             * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		float           * gpu_port_offsets,       // relative ports x,y offsets - just to scale differences, may be approximate
		int               colors,             // number of colors (3/1)
		int               is_lwir,            // do not perform shot correction
		float             min_shot,           // 10.0
		float             scale_shot,         // 3.0
		float             diff_sigma,         // pixel value/pixel change
		float             diff_threshold,     // pixel value/pixel change
		//		int               diff_gauss,         // when averaging images, use gaussian around average as weight (false - sharp all/nothing)
		float             min_agree,          // minimal number of channels to agree on a point (real number to work with fuzzy averages)
		float             weight0,            // scale for R
		float             weight1,            // scale for B
		float             weight2,            // scale for G
		int               dust_remove,        // Do not reduce average weight when only one image differs much from the average
		int               keep_weights,       // return channel weights after A in RGBA (was removed)
		const size_t      texture_stride,     // in floats (now 256*4 = 1024)
		float           * gpu_texture_tiles)  // (number of colors +1 + ?)*16*16 rgba texture tiles
{
	float weights[3] = {weight0, weight1, weight2};
	// will process exactly 4 cameras in one block (so this number is not adjustable here NUM_CAMS should be == 4 !
	int camera_num = threadIdx.y;
	int tile_indx = blockIdx.x; //  * TEXTURE_TILES_PER_BLOCK + tile_in_block;
	if (tile_indx >= num_texture_tiles){
		return; // nothing to do
	}
	// get number of tile
	int tile_code = gpu_texture_indices[tile_indx];
	if ((tile_code & (1 << CORR_TEXTURE_BIT)) == 0){
		return; // nothing to do
	}
	int tile_num = tile_code >> CORR_NTILE_SHIFT;
	__shared__ float mclt_tiles [NUM_CAMS][NUM_COLORS][2*DTT_SIZE][DTT_SIZE21];
	__shared__ union {
		float clt_tiles  [NUM_CAMS][NUM_COLORS][4][DTT_SIZE][DTT_SIZE1]; // NUM_CAMS == 4
		float mclt_debayer [NUM_CAMS][NUM_COLORS][MCLT_UNION_LEN]; // to align with clt_tiles

	} shr;
	__shared__ union {
		float mclt_tmp           [NUM_CAMS][NUM_COLORS][DTT_SIZE2][DTT_SIZE21];
		float rgbaw              [NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1][DTT_SIZE2][DTT_SIZE21];
		// add more
	} shr1;
	//	__shared__ float port_weights[NUM_CAMS][DTT_SIZE2 * DTT_SIZE21];
	//	__shared__ float color_avg   [NUM_CAMS][DTT_SIZE2 * DTT_SIZE21];

	__shared__ float port_offsets[NUM_CAMS][2];
	__shared__ float ports_rgb   [NUM_CAMS][NUM_COLORS]; // return to system memory (optionally pass null to skip calculation)
	__shared__ float max_diff [NUM_CAMS]; // return to system memory (optionally pass null to skip calculation)
	if (threadIdx.x < 2){
		port_offsets[camera_num][threadIdx.x] = * (gpu_port_offsets + 2 * camera_num + threadIdx.x);
	}


#ifdef DBG_TILE
#ifdef DEBUG7
	if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		printf("\ntextures_gen tile = %d\n",tile_num);
		//    	debug_print_clt1(clt_tile1, color,  0xf); //
		//        printf("\textures_gen tile = %d, pair=%d, color = %d   CAMERA22\n",tile_num, corr_pair,color);
		//    	debug_print_clt1(clt_tile2, color,  0xf); //
	}
	__syncthreads();// __syncwarp();
#endif
#endif
	// serially for each color, parallel for each camera
	// copy clt (frequency domain data)
	for (int color = 0; color < colors; color++){
		//        int offs = (tile_num * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE);
		float * clt_tile = ((float *) shr.clt_tiles[camera_num][color]); // start of 4 * DTT_SIZE * DTT_SIZE block, no threadIdx.x here
		float * clt_tilei = clt_tile + threadIdx.x;
		float * gpu_tile = ((float *) gpu_clt[camera_num]) +  (tile_num * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE) + threadIdx.x;
		float * mclt_tile = (float *) mclt_tiles [camera_num][color];
		float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
		float * mclt_tmp =  (float *) shr1.mclt_tmp[camera_num][color];
		//		float scale = 0.25;

#pragma unroll
		for (int q = 0; q < 4; q++) {
			float *lpf = lpf_data[(colors > 1)? color : 3] + threadIdx.x; // lpf_data[3] - mono
#pragma unroll
			for (int i = 0; i < DTT_SIZE; i++){ // copy 32 rows (4 quadrants of 8 rows)
				//				*clt_tilei = *gpu_tile * (*lpf) * scale;
				*clt_tilei = *gpu_tile * (*lpf);
				clt_tilei +=  DTT_SIZE1;
				gpu_tile +=   DTT_SIZE;
				lpf +=        DTT_SIZE;
			}
		}
		__syncthreads();
#ifdef DEBUG7
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\ntextures_gen LPF for color = %d\n",color);
			debug_print_lpf(lpf_data[(colors > 1)? color : 3]);

			printf("\ntextures_gen tile = %d, color = %d \n",tile_num, color);
			debug_print_clt_scaled(clt_tile, color,  0xf, 0.25); //
		}
		__syncthreads();// __syncwarp();
#endif
		// perform idct
		imclt8threads(
				0,          // int     do_acc,     // 1 - add to previous value, 0 - overwrite
				clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
				mclt_tile,  // float * mclt_tile )
				((tile_num == DBG_TILE)  && (threadIdx.x == 0)));
		__syncthreads();// __syncwarp();

#ifdef DEBUG7
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\ntextures_gen mclt color = %d\n",color);
			debug_print_mclt(
					mclt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					color);
		}
		__syncthreads();// __syncwarp();
#endif
		if (colors > 1) {
			debayer_shot(
					(color < 2), // const int rb_mode,    // 0 - green, 1 - r/b
					min_shot,    // float     min_shot,   // 10.0
					scale_shot,  // float     scale_shot, // 3.0 (0.0 for mono)
					mclt_tile,   // float   * mclt_src,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
					mclt_dst,    // float   * mclt_dst,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
					mclt_tmp,    // float   * mclt_tmp,
					((tile_num == DBG_TILE)  && (threadIdx.x == 0))); // int debug);
			__syncthreads();// __syncwarp();
		} else {
			// copy? - no, just remember to use mclt_tile, not mclt_dst
			// will have to copy mclt_tiles -> mclt_dst as they have different gaps
			// untested copy for mono mode
#pragma unroll
			for (int n = 0; n <= DTT_SIZE; n += DTT_SIZE){
				float * msp = mclt_tile + threadIdx.x + n;
				float * dst = mclt_dst +  threadIdx.x + n;
#pragma unroll
				for (int row = 0; row < DTT_SIZE2; row++){
					*dst = *msp;
					msp += DTT_SIZE21;
					dst += DTT_SIZE21;
				}
			}
			__syncthreads();
		}
#ifdef DEBUG77
		//		float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];

		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
				printf("\ntextures_gen AFTER DEBAER cam= %d, color = %d\n",threadIdx.y, color);
				debug_print_mclt(
						mclt_dst, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
				printf("\ntextures_gen AFTER DEBAER0 cam= %d, color = %d\n",threadIdx.y, 0);
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][0], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);

			}
			__syncthreads();// __syncwarp();
		}
		__syncthreads();// __syncwarp();
#endif
	} // for (int color = 0; color < colors; color++)

	__syncthreads(); // __syncwarp();
///	return;
#ifdef DEBUG77
	if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			//		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			for (int nncol = 0; nncol < colors; nncol++){
				printf("\ntextures_gen AFTER DEBAER1 cam= %d, color = %d\n",ccam, nncol);
				//				float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][nncol], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
			}
		}
	}
	__syncthreads();// __syncwarp();
#endif

#ifdef DEBUG77
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			for (int nncol = 0; nncol < colors; nncol++){
				printf("\ntextures_gen AFTER DEBAER1 cam= %d, color = %d\n",ccam, nncol);
				//				float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][nncol], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
			}
		}
		__syncthreads();// __syncwarp();
	}
	__syncthreads();// __syncwarp();
#endif
//	__shared__ float mclt_tiles [NUM_CAMS][NUM_COLORS][2*DTT_SIZE][DTT_SIZE21];
	tile_combine_rgba(
			colors,                    // int     colors,        // number of colors
			(float*) shr.mclt_debayer, // float * mclt_tile,     // debayer // has gaps to align with union !
			(float*) mclt_tiles,       // float * rbg_tile,      // if not null - original (not-debayered) rbg tile to use for the output
			(float *) shr1.rgbaw,      // float * rgba,          // result
			(float * ) 0,              // float * ports_rgb,     // average values of R,G,B for each camera (R0,R1,...,B2,B3) // null
			(float * ) 0,              // float * max_diff,      // maximal (weighted) deviation of each channel from the average /null
			(float *) port_offsets,    // float * port_offsets,  // [port]{x_off, y_off} - just to scale pixel value differences
			diff_sigma,                // float   diff_sigma,     // pixel value/pixel change
			diff_threshold,            // float   diff_threshold, // pixel value/pixel change
			min_agree,                 // float   min_agree,   NOT USED?   // minimal number of channels to agree on a point (real number to work with fuzzy averages)
			weights,                   // float * chn_weights,    // color channel weights, sum == 1.0
			dust_remove,               // int     dust_remove,    // Do not reduce average weight when only one image differes much from the average
			keep_weights,              // int     keep_weights,   // return channel weights and rms after A in RGBA (weight are always calculated)
			(tile_num == DBG_TILE) );  //int     debug );

// return either only 4 slices (RBGA) or all 12 (with weights and rms) if keep_weights
// float rgbaw              [NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1][DTT_SIZE2][DTT_SIZE21];
//	size_t texture_tile_offset = + tile_indx * texture_stride;
	float * gpu_texture_tile = gpu_texture_tiles + tile_indx * texture_stride;

	for (int pass = 0; pass < 8; pass ++) {
		int row = pass * 2 + (threadIdx.y >> 1);
		int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
		int i  = row * DTT_SIZE21 + col;
		int gi = row * DTT_SIZE2  + col;
		float * gpu_texture_tile_gi = gpu_texture_tile + gi;
		float * rgba_i = ((float *) shr1.rgbaw) + i;
		// always copy 3 (1) colors + alpha
		if (colors == 3){
			if (keep_weights) {
#pragma unroll
				for (int ncol = 0; ncol < NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1 ; ncol++) { // 12
					*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			} else {
#pragma unroll
				for (int ncol = 0; ncol < NUM_COLORS + 1; ncol++) { // 4
					*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			}
		} else { // assuming colors = 1
			if (keep_weights) {
#pragma unroll
				for (int ncol = 0; ncol < 1 + 1 + NUM_CAMS + 1 + 1 ; ncol++) { // 8
					*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			} else {
#pragma unroll
				for (int ncol = 0; ncol < 1 + 1; ncol++) { // 2
					*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			}
		}
	}

#ifdef DEBUG7
	if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
        printf("\ntextures_gen tile done = %d, texture_stride= %d\n",tile_num, (int) texture_stride);
    }
     __syncthreads();// __syncwarp();
#endif
}
#endif // ifdef USE_textures_gen
extern "C"
__global__ void textures_accumulate(
//		int               border_tile,        // if 1 - watch for border
		int             * woi,                // x, y, width,height
		float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		size_t            num_texture_tiles,  // number of texture tiles to process
		int             * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		float           * gpu_port_offsets,       // relative ports x,y offsets - just to scale differences, may be approximate
		int               colors,             // number of colors (3/1)
		int               is_lwir,            // do not perform shot correction
		float             min_shot,           // 10.0
		float             scale_shot,         // 3.0
		float             diff_sigma,         // pixel value/pixel change
		float             diff_threshold,     // pixel value/pixel change
		float             min_agree,          // minimal number of channels to agree on a point (real number to work with fuzzy averages)
		float             weight0,            // scale for R
		float             weight1,            // scale for B
		float             weight2,            // scale for G
		int               dust_remove,        // Do not reduce average weight when only one image differs much from the average
		int               keep_weights,       // return channel weights after A in RGBA (was removed) (should be 0 if gpu_texture_rbg)?
// combining both non-overlap and overlap (each calculated if pointer is not null )
		size_t            texture_rbg_stride, // in floats
		float           * gpu_texture_rbg,    // (number of colors +1 + ?)*16*16 rgba texture tiles
		size_t            texture_stride,     // in floats (now 256*4 = 1024)
		float           * gpu_texture_tiles)  // (number of colors +1 + ?)*16*16 rgba texture tiles

{
	float weights[3] = {weight0, weight1, weight2};
	// will process exactly 4 cameras in one block (so this number is not adjustable here NUM_CAMS should be == 4 !
	int camera_num = threadIdx.y;
	int tile_indx = blockIdx.x; //  * TEXTURE_TILES_PER_BLOCK + tile_in_block;
	if (tile_indx >= num_texture_tiles){
		return; // nothing to do
	}
	// get number of tile
	int tile_code = gpu_texture_indices[tile_indx];
	if ((tile_code & (1 << CORR_TEXTURE_BIT)) == 0){
		return; // nothing to do
	}
	int tile_num = tile_code >> CORR_NTILE_SHIFT;
	__shared__ float mclt_tiles [NUM_CAMS][NUM_COLORS][2*DTT_SIZE][DTT_SIZE21];
	__shared__ union {
		float clt_tiles  [NUM_CAMS][NUM_COLORS][4][DTT_SIZE][DTT_SIZE1]; // NUM_CAMS == 4
		float mclt_debayer [NUM_CAMS][NUM_COLORS][MCLT_UNION_LEN]; // to align with clt_tiles

	} shr;
	__shared__ union {
		float mclt_tmp           [NUM_CAMS][NUM_COLORS][DTT_SIZE2][DTT_SIZE21];
		float rgbaw              [NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1][DTT_SIZE2][DTT_SIZE21];
		// add more
	} shr1;
	//	__shared__ float port_weights[NUM_CAMS][DTT_SIZE2 * DTT_SIZE21];
	//	__shared__ float color_avg   [NUM_CAMS][DTT_SIZE2 * DTT_SIZE21];

	__shared__ float port_offsets[NUM_CAMS][2];
	__shared__ float ports_rgb   [NUM_CAMS][NUM_COLORS]; // return to system memory (optionally pass null to skip calculation)
	__shared__ float max_diff [NUM_CAMS]; // return to system memory (optionally pass null to skip calculation)
	if (threadIdx.x < 2){
		port_offsets[camera_num][threadIdx.x] = * (gpu_port_offsets + 2 * camera_num + threadIdx.x);
	}


#ifdef DBG_TILE
#ifdef DEBUG7
	if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		printf("\ntextures_gen tile = %d\n",tile_num);
		//    	debug_print_clt1(clt_tile1, color,  0xf); //
		//        printf("\textures_gen tile = %d, pair=%d, color = %d   CAMERA22\n",tile_num, corr_pair,color);
		//    	debug_print_clt1(clt_tile2, color,  0xf); //
	}
	__syncthreads();// __syncwarp();
#endif
#endif
	// serially for each color, parallel for each camera
	// copy clt (frequency domain data)
	for (int color = 0; color < colors; color++){
		//        int offs = (tile_num * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE);
		float * clt_tile = ((float *) shr.clt_tiles[camera_num][color]); // start of 4 * DTT_SIZE * DTT_SIZE block, no threadIdx.x here
		float * clt_tilei = clt_tile + threadIdx.x;
		float * gpu_tile = ((float *) gpu_clt[camera_num]) +  (tile_num * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE) + threadIdx.x;
		float * mclt_tile = (float *) mclt_tiles [camera_num][color];
		float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
		float * mclt_tmp =  (float *) shr1.mclt_tmp[camera_num][color];
		//		float scale = 0.25;

#pragma unroll
		for (int q = 0; q < 4; q++) {
			float *lpf = lpf_data[(colors > 1)? color : 3] + threadIdx.x; // lpf_data[3] - mono
#pragma unroll
			for (int i = 0; i < DTT_SIZE; i++){ // copy 32 rows (4 quadrants of 8 rows)
				//				*clt_tilei = *gpu_tile * (*lpf) * scale;
				*clt_tilei = *gpu_tile * (*lpf);
				clt_tilei +=  DTT_SIZE1;
				gpu_tile +=   DTT_SIZE;
				lpf +=        DTT_SIZE;
			}
		}
		__syncthreads();
#ifdef DEBUG7
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\ntextures_gen LPF for color = %d\n",color);
			debug_print_lpf(lpf_data[(colors > 1)? color : 3]);

			printf("\ntextures_gen tile = %d, color = %d \n",tile_num, color);
			debug_print_clt_scaled(clt_tile, color,  0xf, 0.25); //
		}
		__syncthreads();// __syncwarp();
#endif
		// perform idct
		imclt8threads(
				0,          // int     do_acc,     // 1 - add to previous value, 0 - overwrite
				clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
				mclt_tile,  // float * mclt_tile )
				((tile_num == DBG_TILE)  && (threadIdx.x == 0)));
		__syncthreads();// __syncwarp();

#ifdef DEBUG7
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\ntextures_gen mclt color = %d\n",color);
			debug_print_mclt(
					mclt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					color);
		}
		__syncthreads();// __syncwarp();
#endif
		if (colors > 1) {
			debayer_shot(
					(color < 2), // const int rb_mode,    // 0 - green, 1 - r/b
					min_shot,    // float     min_shot,   // 10.0
					scale_shot,  // float     scale_shot, // 3.0 (0.0 for mono)
					mclt_tile,   // float   * mclt_src,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
					mclt_dst,    // float   * mclt_dst,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
					mclt_tmp,    // float   * mclt_tmp,
					((tile_num == DBG_TILE)  && (threadIdx.x == 0))); // int debug);
			__syncthreads();// __syncwarp();
		} else {
			// copy? - no, just remember to use mclt_tile, not mclt_dst
			// will have to copy mclt_tiles -> mclt_dst as they have different gaps
			// untested copy for mono mode
#pragma unroll
			for (int n = 0; n <= DTT_SIZE; n += DTT_SIZE){
				float * msp = mclt_tile + threadIdx.x + n;
				float * dst = mclt_dst +  threadIdx.x + n;
#pragma unroll
				for (int row = 0; row < DTT_SIZE2; row++){
					*dst = *msp;
					msp += DTT_SIZE21;
					dst += DTT_SIZE21;
				}
			}
			__syncthreads();
		}
#ifdef DEBUG77
		//		float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];

		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
				printf("\ntextures_gen AFTER DEBAER cam= %d, color = %d\n",threadIdx.y, color);
				debug_print_mclt(
						mclt_dst, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
				printf("\ntextures_gen AFTER DEBAER0 cam= %d, color = %d\n",threadIdx.y, 0);
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][0], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);

			}
			__syncthreads();// __syncwarp();
		}
		__syncthreads();// __syncwarp();
#endif
	} // for (int color = 0; color < colors; color++)

	__syncthreads(); // __syncwarp();
///	return;
#ifdef DEBUG77
	if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			//		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			for (int nncol = 0; nncol < colors; nncol++){
				printf("\ntextures_gen AFTER DEBAER1 cam= %d, color = %d\n",ccam, nncol);
				//				float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][nncol], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
			}
		}
	}
	__syncthreads();// __syncwarp();
#endif

#ifdef DEBUG77
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			for (int nncol = 0; nncol < colors; nncol++){
				printf("\ntextures_gen AFTER DEBAER1 cam= %d, color = %d\n",ccam, nncol);
				//				float * mclt_dst =  (float *) shr.mclt_debayer[camera_num][color];
				debug_print_mclt(
						(float *) shr.mclt_debayer[ccam][nncol], //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
			}
		}
		__syncthreads();// __syncwarp();
	}
	__syncthreads();// __syncwarp();
#endif
//	__shared__ float mclt_tiles [NUM_CAMS][NUM_COLORS][2*DTT_SIZE][DTT_SIZE21];
	tile_combine_rgba(
			colors,                    // int     colors,        // number of colors
			(float*) shr.mclt_debayer, // float * mclt_tile,     // debayer // has gaps to align with union !
			(float*) mclt_tiles,       // float * rbg_tile,      // if not null - original (not-debayered) rbg tile to use for the output
			(float *) shr1.rgbaw,      // float * rgba,          // result
			(float * ) 0,              // float * ports_rgb,     // average values of R,G,B for each camera (R0,R1,...,B2,B3) // null
			(float * ) 0,              // float * max_diff,      // maximal (weighted) deviation of each channel from the average /null
			(float *) port_offsets,    // float * port_offsets,  // [port]{x_off, y_off} - just to scale pixel value differences
			diff_sigma,                // float   diff_sigma,     // pixel value/pixel change
			diff_threshold,            // float   diff_threshold, // pixel value/pixel change
			min_agree,                 // float   min_agree,   NOT USED?   // minimal number of channels to agree on a point (real number to work with fuzzy averages)
			weights,                   // float * chn_weights,    // color channel weights, sum == 1.0
			dust_remove,               // int     dust_remove,    // Do not reduce average weight when only one image differes much from the average
			keep_weights,              // int     keep_weights,   // return channel weights and rms after A in RGBA (weight are always calculated)
			(tile_num == DBG_TILE) );  //int     debug );

// return either only 4 slices (RBGA) or all 12 (with weights and rms) if keep_weights
// float rgbaw              [NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1][DTT_SIZE2][DTT_SIZE21];
//	size_t texture_tile_offset = + tile_indx * texture_stride;
// multiply all 4(2) slices by a window (if not all directions)
	if (gpu_texture_tiles && (texture_stride != 0)){ // generate non-ovelapping tiles
		float * gpu_texture_tile = gpu_texture_tiles + tile_indx * texture_stride;

		for (int pass = 0; pass < 8; pass ++) {
			int row = pass * 2 + (threadIdx.y >> 1);
			int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
			int i  = row * DTT_SIZE21 + col;
			int gi = row * DTT_SIZE2  + col;
			float * gpu_texture_tile_gi = gpu_texture_tile + gi;
			float * rgba_i = ((float *) shr1.rgbaw) + i;
			// always copy 3 (1) colors + alpha
			if (colors == 3){
				if (keep_weights) {
#pragma unroll
					for (int ncol = 0; ncol < NUM_COLORS + 1 + NUM_CAMS + NUM_COLORS + 1 ; ncol++) { // 12
						*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
					}
				} else {
#pragma unroll
					for (int ncol = 0; ncol < NUM_COLORS + 1; ncol++) { // 4
						*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
					}
				}
			} else { // assuming colors = 1
				if (keep_weights) {
#pragma unroll
					for (int ncol = 0; ncol < 1 + 1 + NUM_CAMS + 1 + 1 ; ncol++) { // 8
						*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
					}
				} else {
#pragma unroll
					for (int ncol = 0; ncol < 1 + 1; ncol++) { // 2
						*(gpu_texture_tile_gi + ncol * (DTT_SIZE2 * DTT_SIZE2)) = *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
					}
				}
			}

		}
#ifdef DEBUG7
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\textures_accumulate tile done = %d, texture_stride= %d\n",tile_num, (int) texture_stride);
		}
		__syncthreads();// __syncwarp();
#endif
	} // if (gpu_texture_tiles){ // generate non-ovelapping tiles

	tile_code &= TASK_TEXTURE_BITS;
	if (!tile_code){
		return; // should not happen
	}

	if (gpu_texture_rbg && (texture_rbg_stride != 0)) { // generate RGBA
#ifdef DEBUG12
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
//			printf("\ntextures_accumulate accumulating tile = %d, tile_code= %d, border_tile=%d\n",
//					tile_num, (int) tile_code, border_tile);
			printf("\ntextures_accumulate accumulating tile = %d, tile_code= %d\n", tile_num, (int) tile_code);

			for (int ncol = 0; ncol <= colors; ncol++) {
				printf("\ntile[%d]\n",ncol);
				debug_print_mclt(
						(float *) (shr1.rgbaw[ncol]),
						-1);
			}
		}
		__syncthreads();// __syncwarp();
#endif // DEBUG12
		if (tile_code != TASK_TEXTURE_BITS){ // only multiply if needed, for tile_code == TASK_TEXTURE_BITS keep as is.
			for (int pass = 0; pass < 8; pass ++) {
				int row = pass * 2 + (threadIdx.y >> 1);
				int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
				int i  = row * DTT_SIZE21 + col;
				int gi = row * DTT_SIZE2  + col;
				float * rgba_i = ((float *) shr1.rgbaw) + i;
				// always copy 3 (1) colors + alpha
				if (colors == 3){
#pragma unroll
					for (int ncol = 0; ncol < NUM_COLORS + 1; ncol++) { // 4
						*(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21)) *= alphaFade[tile_code][gi]; // reduce [tile_code] by LUT
					}
				} else { // assuming colors = 1
#pragma unroll
					for (int ncol = 0; ncol < 1 + 1; ncol++) { // 2
						*(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21)) *= alphaFade[tile_code][gi]; // reduce [tile_code] by LUT
					}
				}
			}
		}
		int slice_stride = texture_rbg_stride * (*(woi + 3) + 1) * DTT_SIZE; // offset to the next color
		int tileY = tile_num / TILESX; // slow, but 1 per tile
		int tileX = tile_num - tileY * TILESX;
		int tile_x0 = (tileX - *(woi + 0)) * DTT_SIZE; //  - (DTT_SIZE/2); // may be negative == -4
		int tile_y0 = (tileY - *(woi + 1)) * DTT_SIZE; //  - (DTT_SIZE/2); // may be negative == -4
		int height = *(woi + 3) << DTT_SIZE_LOG2;

#ifdef DEBUG12
		if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
			printf("\ntextures_accumulate () tileX=%d, tileY=%d, tile_x0=%d, tile_y0=%d, slice_stride=%d\n",
					tileX, tileY, tile_x0, tile_y0, slice_stride);

			for (int ncol = 0; ncol <= colors; ncol++) {
				printf("\ntile[%d]\n",ncol);
				debug_print_mclt(
						(float *) (shr1.rgbaw[ncol]),
						-1);
			}
		}
		__syncthreads();// __syncwarp();
#endif // DEBUG12
		for (int pass = 0; pass < 8; pass ++) {
			int row = pass * 2 + (threadIdx.y >> 1);          // row    inside a tile (0..15)
			int col = ((threadIdx.y & 1) << 3) + threadIdx.x; // column inside a tile (0..15)
			int g_row = row + tile_y0;
			int g_col = col + tile_x0;
			int i  = row * DTT_SIZE21 + col;
			int gi = g_row * texture_rbg_stride  + g_col; // offset to the top left corner
			float * gpu_texture_rbg_gi = gpu_texture_rbg + gi;
			float * rgba_i = ((float *) shr1.rgbaw) + i;
#ifdef DEBUG12
			if ((tile_num == DBG_TILE)  && (threadIdx.x == 0) && (threadIdx.y == 0)){
				printf("\ntextures_accumulate () pass=%d, row=%d, col=%d, g_row=%d, g_col=%d, i=%d, gi=%d\n",
						pass, row, col, g_row, g_col, i, gi);

			}
			__syncthreads();// __syncwarp();
#endif // DEBUG12

			///			if (!border_tile ||
			///					((g_row >= 0) && (g_col >= 0) && (g_row < (DTT_SIZE * TILESY)) && (g_col < (DTT_SIZE * TILESX)))){
			///					((g_row >= 0) && (g_col >= 0) && (g_row < height) && (g_col < (DTT_SIZE * TILESX)))){
			// always copy 3 (1) colors + alpha
			if (colors == 3){
#pragma unroll
				for (int ncol = 0; ncol < NUM_COLORS + 1; ncol++) { // 4
					*(gpu_texture_rbg_gi + ncol * slice_stride) += *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			} else { // assuming colors = 1
#pragma unroll
				for (int ncol = 0; ncol < 1 + 1; ncol++) { // 2
					*(gpu_texture_rbg_gi + ncol * slice_stride) += *(rgba_i + ncol * (DTT_SIZE2 * DTT_SIZE21));
				}
			}
///			}
		}
	} // 	if (gpu_texture_rbg) { // generate RGBA
} // textures_accumulate()








extern "C"
__global__ void imclt_rbg(
		float           * gpu_clt,            // [TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		float           * gpu_rbg,            // WIDTH, 3 * HEIGHT
		int               color,
		int               v_offset,
		int               h_offset,
		const size_t      dstride)            // in floats (pixels)
{
	float *color_plane = gpu_rbg + dstride * (IMG_HEIGHT + DTT_SIZE) * color;
	int pass =           (v_offset << 1) + h_offset;     		// 0..3 to correctly acummulate 16x16 tiles stride 8
	int tile_in_block = threadIdx.y;
	int tile_num = blockIdx.x * IMCLT_TILES_PER_BLOCK + tile_in_block;
//	if (tile_num >= (TILESY * TILESX)) {
//		return; // just testing with a single tile
//	}
//	int tilesy_half = (TILESY + (v_offset ^ 1)) >> 1;
	int tilesx_half = (TILESX + (h_offset ^ 1)) >> 1;
	int tileY_half =  tile_num / tilesx_half;
	int tileX_half =  tile_num - tileY_half * tilesx_half;
	int tileY = (tileY_half << 1) + v_offset;
	int tileX = (tileX_half << 1) + h_offset;
	if (tileY >= TILESY) {
		return; // just testing with a single tile
	}
#ifdef DEBUG4
	if (threadIdx.x == 0) {
		if (tileY == DBG_TILE_Y) {
			printf("tileX == %d, tileY = %d\n",tileX, tileY);
		}
		if (tileX == DBG_TILE_X) {
			printf("tileX == %d, tileY = %d\n",tileX, tileY);
		}
		if ((tileX == DBG_TILE_X) && (tileY == DBG_TILE_Y)) {
			printf("tileX == %d, tileY = %d\n",tileX, tileY);
		}
	}


#endif

	int thr3 =    threadIdx.x >> 3;
	int column =  threadIdx.x; // modify to use 2 * 8 threads, if needed.

    __shared__ float clt_tiles        [IMCLT_TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float mclt_tiles       [IMCLT_TILES_PER_BLOCK][DTT_SIZE2][DTT_SIZE21];

    // copy clt (frequency domain data)
    float * clt_tile = ((float *) clt_tiles) +  tile_in_block * (4 * DTT_SIZE * DTT_SIZE1); // top left quadrant0
//    float * gpu_tile = ((float *) gpu_clt) +  ((DBG_TILE_Y * TILESX + DBG_TILE_X) * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE); // top left quadrant0
    float * gpu_tile = ((float *) gpu_clt) +  ((tileY * TILESX + tileX) * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE); // top left quadrant0

    clt_tile += column + thr3; // first 2 rows
    gpu_tile += column;  // first 2 rows
#pragma unroll
    for (int i = 0; i < DTT_SIZE2; i++){
    	*clt_tile= *gpu_tile;
    	clt_tile += (2 * DTT_SIZE1);
    	gpu_tile += (2 * DTT_SIZE);
    }

	float * mclt_top = ((float*) mclt_tiles) +  tile_in_block * (DTT_SIZE2 * DTT_SIZE21) + column;
	float * rbg_top = color_plane + (tileY * DTT_SIZE)* dstride + (tileX * DTT_SIZE) + column;
	float * mclt_tile = mclt_top;

	if (pass == 0){ // just set mclt tile to all 0
#pragma unroll
		for (int i = 0; i < DTT_SIZE2; i++){
			*mclt_tile= 0.0f;
			mclt_tile += DTT_SIZE21;
		}
	} else {
		float * rbg_p = rbg_top;
#pragma unroll
			for (int i = 0; i < DTT_SIZE2; i++){
				*mclt_tile= *rbg_p;
				mclt_tile += DTT_SIZE21;
				rbg_p +=     dstride; // DTT_SIZE2;
			}
	}
	__syncthreads();// __syncwarp();
	imclt(
			((float*) clt_tiles) +  tile_in_block * (4 * DTT_SIZE * DTT_SIZE1), // float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
			((float*) mclt_tiles) +  tile_in_block * (DTT_SIZE2 * DTT_SIZE21)); // float * mclt_tile )
	__syncthreads();// __syncwarp();

#ifdef DEBUG5
    if (((threadIdx.x) == 0) &&(tileX == DBG_TILE_X)  && (tileY == DBG_TILE_Y)){
//        printf("\nMCLT Tiles after IMCLT\n");
		printf("tileX == %d, tileY = %d\n",tileX, tileY);
    	debug_print_mclt(mclt_tile, -1); // only 1 quadrant for R,B and 2 - for G
    }
    __syncthreads();// __syncwarp();
#endif



//	save result (back)
	float * rbg_p = rbg_top;
	mclt_tile =     mclt_top;
	if ((tileX == 0)  && (tileY == 0)){
#pragma unroll
		for (int i = 0; i < DTT_SIZE2; i++){
			*rbg_p = 100.0f; // just testing
			mclt_tile += DTT_SIZE21;
			rbg_p +=     dstride; // DTT_SIZE2; // FIXME
		}
	} else if ((tileX == DBG_TILE_X)  && (tileY == DBG_TILE_Y)){
#pragma unroll
		for (int i = 0; i < DTT_SIZE2; i++){
			*rbg_p = (*mclt_tile) * 2.0; // just testing
			mclt_tile += DTT_SIZE21;
			rbg_p +=     dstride; // DTT_SIZE2; // FIXME
		}
	} else {
#pragma unroll
		for (int i = 0; i < DTT_SIZE2; i++){
			*rbg_p = *mclt_tile;
			mclt_tile += DTT_SIZE21;
			rbg_p +=     dstride; // DTT_SIZE2; // FIXME
		}
	}
}



// Fractional pixel shift (phase rotation), horizontal. In-place. uses 8 threads (.x)
__device__ void shiftTileHor(
		float * clt_tile, //       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float residual_shift )
{
	int joffs = threadIdx.x; // * DTT_SIZE1;
	float * clt_tile_j0 = clt_tile +    joffs;                // ==&clt_tile[0][j][0]
	float * clt_tile_j1 = clt_tile_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * clt_tile_j2 = clt_tile_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * clt_tile_j3 = clt_tile_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]
	float x = residual_shift * ((threadIdx.x << 1 ) +1) * (0.5f/ DTT_SIZE);
	float ch =  cospif(x);
	float sh =  sinpif(x);
#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++) {
		float clt_tile_a = *clt_tile_j0;
		float clt_tile_b = *clt_tile_j1;
		*clt_tile_j0 =  clt_tile_a * ch - clt_tile_b * sh;
		*clt_tile_j1 =  clt_tile_a * sh + clt_tile_b * ch;

		clt_tile_a = *clt_tile_j2;
		clt_tile_b = *clt_tile_j3;
		*clt_tile_j2 =  clt_tile_a * ch - clt_tile_b * sh;
		*clt_tile_j3 =  clt_tile_a * sh + clt_tile_b * ch;

		clt_tile_j0 +=DTT_SIZE1;
		clt_tile_j1 +=DTT_SIZE1;
		clt_tile_j2 +=DTT_SIZE1;
		clt_tile_j3 +=DTT_SIZE1;
	}
}


__device__ void shiftTileVert(
		float * clt_tile, //       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float residual_shift)
{
	int joffs = threadIdx.x * DTT_SIZE1;
	float * clt_tile_j0 = clt_tile +    joffs;                // ==&clt_tile[0][j][0]
	float * clt_tile_j1 = clt_tile_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * clt_tile_j2 = clt_tile_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * clt_tile_j3 = clt_tile_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]
	float x = residual_shift * ((threadIdx.x << 1 ) +1) * (0.5f/ DTT_SIZE);
	float ch =  cospif(x);
	float sh =  sinpif(x);
#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++) {
		float clt_tile_a = *clt_tile_j0;
		float clt_tile_b = *clt_tile_j2;
		*clt_tile_j0 =  clt_tile_a * ch - clt_tile_b * sh;
		*clt_tile_j2 =  clt_tile_a * sh + clt_tile_b * ch;

		clt_tile_a = *clt_tile_j1;
		clt_tile_b = *clt_tile_j3;
		*clt_tile_j1 =  clt_tile_a * ch - clt_tile_b * sh;
		*clt_tile_j3 =  clt_tile_a * sh + clt_tile_b * ch;

		clt_tile_j0 ++;
		clt_tile_j1 ++;
		clt_tile_j2 ++;
		clt_tile_j3 ++;
	}
}

__device__ void convolveTiles(
		float* clt_tile, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
		float* kernel) //      [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the CLT kernel (DTT3 converted)
{
	int joffs = threadIdx.x * DTT_SIZE1;
	float * kernel_j; //  =   kernel +      joffs;                // ==&kernel[0][j][0]
	float * clt_tile_j0 = clt_tile +    joffs;                // ==&clt_tile[0][j][0]
	float * clt_tile_j1 = clt_tile_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * clt_tile_j2 = clt_tile_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * clt_tile_j3 = clt_tile_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]
//#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++){
		// k=0
		kernel_j =   kernel + joffs + i;
		float krn = *(kernel_j);
		float r0 =  *(clt_tile_j0) * krn;
		float r1 =  *(clt_tile_j1) * krn;
		float r2 =  *(clt_tile_j2) * krn;
		float r3 =  *(clt_tile_j3) * krn;
		// k = 1
		kernel_j += (DTT_SIZE1*DTT_SIZE);
		krn = *(kernel_j);
		r0 -=  *(clt_tile_j1) * krn;
		r1 +=  *(clt_tile_j0) * krn;
		r2 -=  *(clt_tile_j3) * krn;
		r3 +=  *(clt_tile_j2) * krn;
		// k=2
		kernel_j += (DTT_SIZE1*DTT_SIZE);
		krn = *(kernel_j);
		r0 -=  *(clt_tile_j2) * krn;
		r1 -=  *(clt_tile_j3) * krn;
		r2 +=  *(clt_tile_j0) * krn;
		r3 +=  *(clt_tile_j1) * krn;
		// k=3
		kernel_j += (DTT_SIZE1*DTT_SIZE);
		krn = *(kernel_j);
		r0 +=  *(clt_tile_j3) * krn;
		r1 -=  *(clt_tile_j2) * krn;
		r2 -=  *(clt_tile_j1) * krn;
		r3 +=  *(clt_tile_j0) * krn;
		*(clt_tile_j0)= r0;
		*(clt_tile_j1)= r1;
		*(clt_tile_j2)= r2;
		*(clt_tile_j3)= r3;
		clt_tile_j0 ++;
		clt_tile_j1 ++;
		clt_tile_j2 ++;
		clt_tile_j3 ++;
	}
}

__device__ void correlateAccumulateTiles(
		float  scale,     // scale correlation
		float* clt_tile1, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 1, rows extended to optimize shared ports
		float* clt_tile2, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data 2, rows extended to optimize shared ports
		float* corr_tile) //    [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the correlation result
{
	int joffs = threadIdx.x * DTT_SIZE1;
	float * clt_tile2_j; //  =   clt_tile2 +      joffs;                // ==&clt_tile2[0][j][0]
	float * clt_tile1_j0 = clt_tile1 +    joffs;                // ==&clt_tile[0][j][0]
	float * clt_tile1_j1 = clt_tile1_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * clt_tile1_j2 = clt_tile1_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * clt_tile1_j3 = clt_tile1_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]

	float * corr_tile_j0 = corr_tile +    joffs;                // ==&clt_tile[0][j][0]
	float * corr_tile_j1 = corr_tile_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * corr_tile_j2 = corr_tile_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * corr_tile_j3 = corr_tile_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]
//#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++){
		// k=0
		clt_tile2_j =   clt_tile2 + joffs + i;
		float clt2 = *(clt_tile2_j);
		float r0 =  *(clt_tile1_j0) * clt2;
		float r1 = -*(clt_tile1_j1) * clt2;
		float r2 = -*(clt_tile1_j2) * clt2;
		float r3 =  *(clt_tile1_j3) * clt2;
		// k = 1
		clt_tile2_j += (DTT_SIZE1*DTT_SIZE);
		clt2 = *(clt_tile2_j);
		r0 +=  *(clt_tile1_j1) * clt2;
		r1 +=  *(clt_tile1_j0) * clt2;
		r2 -=  *(clt_tile1_j3) * clt2;
		r3 -=  *(clt_tile1_j2) * clt2;
		// k=2
		clt_tile2_j += (DTT_SIZE1*DTT_SIZE);
		clt2 = *(clt_tile2_j);
		r0 +=  *(clt_tile1_j2) * clt2;
		r1 -=  *(clt_tile1_j3) * clt2;
		r2 +=  *(clt_tile1_j0) * clt2;
		r3 -=  *(clt_tile1_j1) * clt2;
		// k=3
		clt_tile2_j += (DTT_SIZE1*DTT_SIZE);
		clt2 = *(clt_tile2_j);
		r0 +=  *(clt_tile1_j3) * clt2;
		r1 +=  *(clt_tile1_j2) * clt2;
		r2 +=  *(clt_tile1_j1) * clt2;
		r3 +=  *(clt_tile1_j0) * clt2;

		*(corr_tile_j0) += scale * r0;
		*(corr_tile_j1) += scale * r1;
		*(corr_tile_j2) += scale * r2;
		*(corr_tile_j3) += scale * r3;
		clt_tile1_j0 ++;
		clt_tile1_j1 ++;
		clt_tile1_j2 ++;
		clt_tile1_j3 ++;
		corr_tile_j0 ++;
		corr_tile_j1 ++;
		corr_tile_j2 ++;
		corr_tile_j3 ++;
	}
}

__device__ void resetCorrelation(
		float* corr_tile) //    [4][DTT_SIZE][DTT_SIZE1]) // 4 quadrants of the correlation result
{
	int joffs = threadIdx.x * DTT_SIZE1;

	float * corr_tile_j0 = corr_tile +    joffs;                // k = 0
	float * corr_tile_j1 = corr_tile_j0 + (DTT_SIZE1*DTT_SIZE); // k = 1
	float * corr_tile_j2 = corr_tile_j1 + (DTT_SIZE1*DTT_SIZE); // k = 2
	float * corr_tile_j3 = corr_tile_j2 + (DTT_SIZE1*DTT_SIZE); // k = 3
//#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++){

		*(corr_tile_j0) = 0;
		*(corr_tile_j1) = 0;
		*(corr_tile_j2) = 0;
		*(corr_tile_j3) = 0;
		corr_tile_j0 ++;
		corr_tile_j1 ++;
		corr_tile_j2 ++;
		corr_tile_j3 ++;
	}
}

__device__ void normalizeTileAmplitude(
		float * clt_tile, //       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float fat_zero ) // fat zero is absolute, scale it outside
{
	int joffs = threadIdx.x * DTT_SIZE1;
	float * clt_tile_j0 = clt_tile +    joffs;                // ==&clt_tile[0][j][0]
	float * clt_tile_j1 = clt_tile_j0 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[1][j][0]
	float * clt_tile_j2 = clt_tile_j1 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[2][j][0]
	float * clt_tile_j3 = clt_tile_j2 + (DTT_SIZE1*DTT_SIZE); // ==&clt_tile[3][j][0]
#pragma unroll
	for (int i = 0; i < DTT_SIZE; i++) {
		float s2 = fat_zero * fat_zero +
				*(clt_tile_j0) * *(clt_tile_j0) +
				*(clt_tile_j1) * *(clt_tile_j1) +
				*(clt_tile_j2) * *(clt_tile_j2) +
				*(clt_tile_j3) * *(clt_tile_j3);
		float scale = rsqrtf(s2); // 1.0/sqrt(s2)
		*(clt_tile_j0) *= scale;
		*(clt_tile_j1) *= scale;
		*(clt_tile_j2) *= scale;
		*(clt_tile_j3) *= scale;

		clt_tile_j0 ++; // =DTT_SIZE1;
		clt_tile_j1 ++; // =DTT_SIZE1;
		clt_tile_j2 ++; // =DTT_SIZE1;
		clt_tile_j3 ++; // =DTT_SIZE1;
	}
}
/*
Converted from DttRad2.java:443
	public  double [] corr_unfold_tile(
		double [][]  qdata, // [4][transform_size*transform_size] data after DCT2 (pixel domain)
		int          transform_size
	)
 */
__device__ void corrUnfoldTile(
		int corr_radius,
		float* qdata0, //    [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
		float* rslt)  //   [DTT_SIZE2M1][DTT_SIZE2M1]) // 15x15
{
	int size2r1 = 2 * corr_radius + 1; // 15
	int crp1 = corr_radius + 1;        //8
///	const int rslt_base_index = DTT_SIZE2M1 * (DTT_SIZE) - DTT_SIZE; // offset of the center
	int rslt_base_index = size2r1 * crp1 - crp1; // offset of the center

	float * qdata1 = qdata0 + (DTT_SIZE * DTT_SIZE1);
	float * qdata2 = qdata1 + (DTT_SIZE * DTT_SIZE1);
	float * qdata3 = qdata2 + (DTT_SIZE * DTT_SIZE1);
	int i = threadIdx.x;
	if (i > corr_radius) {
		return; // not needed, only use inner
	}
//	printf("\corrUnfoldTile() corr_radius=%d, i=%d\n",corr_radius,i);
	float corr_pixscale = 0.25f;
	int i_transform_size = i * DTT_SIZE1; // used to address source rows which are 9 long
	int im1_transform_size = i_transform_size - DTT_SIZE1; // negative for i = 0, use only after divergence
///	int rslt_row_offs = i * DTT_SIZE2M1;
	int rslt_row_offs = i * size2r1;
	int rslt_base_index_p = rslt_base_index + rslt_row_offs; // i * DTT_SIZE2M1;
	int rslt_base_index_m = rslt_base_index - rslt_row_offs; // i * DTT_SIZE2M1;
	rslt[rslt_base_index_p] = corr_pixscale * qdata0[i_transform_size]; // incomplete, will only be used for thread i=0
	rslt[rslt_base_index_m] = rslt[rslt_base_index_p];                  // nop for i=0 incomplete, will only be used for thread i=0
///	for (int j = 1; j < DTT_SIZE; j++) {
	for (int j = 1; j <= corr_radius; j++) {
		int rslt_base_index_pp = rslt_base_index_p + j;
		int rslt_base_index_pm = rslt_base_index_p - j;
		rslt[rslt_base_index_pp] = corr_pixscale * (
				 qdata0[i_transform_size + j] +
				 qdata1[i_transform_size + j -1]); // incomplete, will only be used for thread i=0
		rslt[rslt_base_index_pm] = corr_pixscale * (
				 qdata0[i_transform_size + j] +
				-qdata1[i_transform_size + j -1]); // incomplete, will only be used for thread i=0
	}
	if (i == 0) {
		return;
	}
///	im1_transform_size = i_transform_size - DTT_SIZE1; // already is calculated
	float d = corr_pixscale * qdata2[im1_transform_size];
	rslt[rslt_base_index_p] += d;
	rslt[rslt_base_index_m] -= d;
	for (int j = 1; j <= corr_radius; j++) {
		int rslt_base_index_pp = rslt_base_index_p + j;
		int rslt_base_index_pm = rslt_base_index_p - j;
		int rslt_base_index_mp = rslt_base_index_m + j;
		int rslt_base_index_mm = rslt_base_index_m - j;
		float d2 = corr_pixscale * qdata2[im1_transform_size + j];
		float d3 = corr_pixscale * qdata3[im1_transform_size + j -1];
		//rslt[rslt_base_index_mp], rslt[rslt_base_index_mp] are partially calculated in the cycle common with i=0
		rslt[rslt_base_index_mp] = rslt[rslt_base_index_pp] - d2 - d3;
		rslt[rslt_base_index_mm] = rslt[rslt_base_index_pm] - d2 + d3;
		rslt[rslt_base_index_pp] += d2 + d3;
		rslt[rslt_base_index_pm] += d2 - d3;
	}
}

__device__ void debug_print_lpf(
		float * lpf_tile)
{
#ifdef	HAS_PRINTF
	for (int dbg_row = 0; dbg_row < DTT_SIZE; dbg_row++){
		for (int dbg_col = 0; dbg_col < DTT_SIZE; dbg_col++){
			printf ("%10.5f ", lpf_tile[dbg_row * DTT_SIZE + dbg_col]);
		}
		printf("\n");
	}
#endif
}


__device__ void debug_print_clt1(
		float * clt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color,
		int mask)
{
#ifdef	HAS_PRINTF
	if (color >= 0) printf("----------- Color = %d -----------\n",color);
	for (int dbg_quadrant = 0; dbg_quadrant < 4; dbg_quadrant++){
		printf("----------- Quadrant (c(h)-c(v), s-c, c-s, s-s) = %d -----------\n",dbg_quadrant);
		if ((mask >> dbg_quadrant) & 1) {
			for (int dbg_row = 0; dbg_row < DTT_SIZE; dbg_row++){
				for (int dbg_col = 0; dbg_col < DTT_SIZE; dbg_col++){
					printf ("%10.5f ", clt_tile[(dbg_quadrant*DTT_SIZE + dbg_row)*DTT_SIZE1 + dbg_col]);
				}
				printf("\n");
			}
		}
		printf("\n");
	}
#endif
}
__device__ void debug_print_clt_scaled(
		float * clt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color,
		int mask,
		float scale)
{
#ifdef	HAS_PRINTF
	if (color >= 0) printf("----------- Color = %d -----------\n",color);
	for (int dbg_quadrant = 0; dbg_quadrant < 4; dbg_quadrant++){
		printf("----------- Quadrant (c(h)-c(v), s-c, c-s, s-s) = %d -----------\n",dbg_quadrant);
		if ((mask >> dbg_quadrant) & 1) {
			for (int dbg_row = 0; dbg_row < DTT_SIZE; dbg_row++){
				for (int dbg_col = 0; dbg_col < DTT_SIZE; dbg_col++){
					printf ("%10.5f ", scale * clt_tile[(dbg_quadrant*DTT_SIZE + dbg_row)*DTT_SIZE1 + dbg_col]);
				}
				printf("\n");
			}
		}
		printf("\n");
	}
#endif
}



__device__ void debug_print_mclt(
		float * mclt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
		const int color)
{
#ifdef	HAS_PRINTF
	if (color >= 0) printf("----------- Color = %d -----------\n",color);
	for (int dbg_row = 0; dbg_row < DTT_SIZE2; dbg_row++){
		for (int dbg_col = 0; dbg_col < DTT_SIZE2; dbg_col++){
			printf ("%10.4f ", mclt_tile[dbg_row *DTT_SIZE21 + dbg_col]);
		}
		printf("\n");
	}
	printf("\n");
#endif
}

__device__ void debug_print_corr_15x15(
		int     corr_radius,
		float * mclt_tile, //DTT_SIZE2M1 x DTT_SIZE2M1
		const int color)
{
#ifdef	HAS_PRINTF
	int size2r1 = 2 * corr_radius + 1;
	if (color >= 0) printf("----------- Color = %d -----------\n",color);
	for (int dbg_row = 0; dbg_row < size2r1; dbg_row++){
		for (int dbg_col = 0; dbg_col < size2r1; dbg_col++){
			printf ("%10.5f ", mclt_tile[dbg_row * size2r1 + dbg_col]);
		}
		printf("\n");
	}
	printf("\n");
#endif
}



__device__ void convertCorrectTile(
		struct CltExtra     * gpu_kernel_offsets, // [tileY][tileX][color]
		float               * gpu_kernels,        // [tileY][tileX][color]
		float               * gpu_images,
		float               * gpu_clt,
		const int             color,
		const int             lpf_mask, // now 0
		const float           centerX,
		const float           centerY,
		const int             txy,
		const size_t          dstride, // in floats (pixels)
		float               * clt_tile, //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		float               * clt_kernels, //      [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
		int   int_topleft     [2],
		float residual_shift  [2],
	    float window_hor_cos  [2*DTT_SIZE],
	    float window_hor_sin  [2*DTT_SIZE],
	    float window_vert_cos [2*DTT_SIZE])

{

	int   ktileX, ktileY;
	int   kernel_index; // common for all coors
	float kdx, kdy;
	if (threadIdx.x == 0){
		ktileX = min(KERNELS_HOR-1,  max(0, ((int) lrintf(centerX * (1.0/KERNELS_STEP)+1))));
		ktileY = min(KERNELS_VERT-1, max(0, ((int) lrintf(centerY * (1.0/KERNELS_STEP)+1))));
		kdx =    centerX - (ktileX << KERNELS_LSTEP) + (1 << (KERNELS_LSTEP -1)); // difference in pixel
		kdy =    centerY - (ktileY << KERNELS_LSTEP) + (1 << (KERNELS_LSTEP -1)); // difference in pixel
#ifdef USE_UMUL24
    	kernel_index = __umul24((ktileX + __umul24(ktileY, KERNELS_HOR)), NUM_COLORS);
#else
    	kernel_index = (ktileX + ktileY * KERNELS_HOR) * NUM_COLORS;
#endif
	}
////     __syncthreads();// __syncwarp();
    // broadcast kernel_index
    kernel_index =  __shfl_sync(
    		0xffffffff,        // unsigned mask,
			kernel_index,      // T var,
			0,                 // int srcLane,
			THREADS_PER_TILE); // int width=warpSize);
////     __syncthreads();// __syncwarp(); // is it needed?
    kdx =  __shfl_sync(
    		0xffffffff,        // unsigned mask,
			kdx,               // T var,
			0,                 // int srcLane,
			THREADS_PER_TILE); // int width=warpSize);
    kdy =  __shfl_sync(
    		0xffffffff,        // unsigned mask,
			kdy,               // T var,
			0,                 // int srcLane,
			THREADS_PER_TILE); // int width=warpSize);

     __syncthreads();// __syncwarp(); // is it needed?
    float px, py;
    // copy kernel
	int kernel_full_index = kernel_index + color;
#ifdef USE_UMUL24
    float * kernel_src = gpu_kernels + __umul24(kernel_full_index, (DTT_SIZE * DTT_SIZE * 4));
#else
    float * kernel_src = gpu_kernels + kernel_full_index* (DTT_SIZE * DTT_SIZE * 4);
#endif

    float * kernelp =  clt_kernels;

    kernel_src += threadIdx.x; // lsb;
    kernelp +=    threadIdx.x; // lsb;
#pragma unroll
    for (int j = 0; j < DTT_SIZE * 4; j++){ // all 4 components, 8 rows
    	// shared memory kernels use DTT_SIZE1 (same as image data)
    	*kernelp = *kernel_src;
    	kernelp+=DTT_SIZE1;
    	kernel_src+=THREADSX;
    }

    // Calculate offsets and prepare windows (all colors):
	struct CltExtra * clt_extra = &gpu_kernel_offsets[kernel_full_index];

	px = centerX - DTT_SIZE - (clt_extra->data_x + clt_extra->dxc_dx * kdx + clt_extra->dxc_dy * kdy) ; // fractional left corner
	int itlx = (int) floorf(px +0.5f);
	if (itlx < 0){
		itlx &= 1; // for color - extend by pairs
	}
	if (itlx >= (IMG_WIDTH - DTT_SIZE)){
		itlx = itlx & 1 +(IMG_WIDTH - DTT_SIZE - 2); // for color - extend by pairs
	}
	int_topleft [0] = itlx;
	float shift_hor =  itlx - px;
	residual_shift[0] = shift_hor;
	float x = shift_hor *(1.0f/16);
	float ahc = cospif(x);
	float ahs = sinpif(x);
	int i1 = DTT_SIZE;
	int i = 0;
	// embed sign for cosine and sine branches into window coefficients
#pragma unroll
	for (; i < (DTT_SIZE/2); i++ ){
		int ri = (DTT_SIZE-1) - i;
		window_hor_cos[i] =   HWINDOW[i ]*ahc + HWINDOW[ri]*ahs;
		window_hor_cos[i1] =  HWINDOW[ i]*ahs - HWINDOW[ri]*ahc;
		if (color == BAYER_GREEN){
			window_hor_sin[i] =    HWINDOW[i ]*ahc + HWINDOW[ri]*ahs; // bayer_color== 2
			window_hor_sin[i1] =   HWINDOW[ri]*ahc - HWINDOW[ i]*ahs;
		}
		i1++;
	}
	// embed sign for cosine and sine branches into window coefficients
#pragma unroll
	for (; i < DTT_SIZE; i++ ){
		int ri = (DTT_SIZE-1) - i;
		window_hor_cos[i] =   -HWINDOW[i ]*ahc - HWINDOW[ri]*ahs;
		window_hor_cos[i1] =   HWINDOW[ i]*ahs - HWINDOW[ri]*ahc;
		if (color == BAYER_GREEN){
			window_hor_sin[i] =    HWINDOW[i ]*ahc + HWINDOW[ri]*ahs;
			window_hor_sin[i1] =   HWINDOW[ i]*ahs - HWINDOW[ri]*ahc;
		}
		i1++;
	}

	py = centerY - DTT_SIZE - (clt_extra->data_y + clt_extra->dyc_dx * kdx + clt_extra->dyc_dy * kdy) ; // fractional top corner
	int itly = (int) floorf(py +0.5f);
	if (itly < 0){
		itly &= 1; // for color - extend by pairs
	}
	if (itly >= (IMG_HEIGHT - DTT_SIZE)){
		itly = (itly & 1) +(IMG_HEIGHT - DTT_SIZE - 2); // for color - extend by pairs
	}
	int_topleft[1] = itly;

#ifdef DEBUG_OOB1
	if ((int_topleft[0] < 0) || (int_topleft[1] < 0) || (int_topleft[0] >= (IMG_WIDTH - DTT_SIZE)) || (int_topleft[1] >= IMG_HEIGHT - DTT_SIZE)){
		printf("Source data OOB, left=%d, top=%d\n",int_topleft[0],int_topleft[1]);
		printf("\n");
		printf("\n");
	    __syncthreads();// __syncwarp();
	}
#endif // DEBUG_OOB1


	float shift_vert =  itly - py;
	residual_shift[1] = shift_vert;
	x = shift_vert *(1.0f/16);
	float avc = cospif(x);
	float avs = sinpif(x);
	i1 = DTT_SIZE; //**** Was commented out
	// embed sign for cosine branch only into window coefficients (for R,B only CC is needed, for G - CC and SC
	i = 0;
#pragma unroll
	for (; i < DTT_SIZE/2; i++ ){
		int ri = (DTT_SIZE-1) - i;
		window_vert_cos[i] =    HWINDOW[i ]*avc + HWINDOW[ri]*avs;
		window_vert_cos[i1++] = HWINDOW[ i]*avs - HWINDOW[ri]*avc;
	}
#pragma unroll
	for (; i < DTT_SIZE; i++ ){
		int ri = (DTT_SIZE-1) - i;
		window_vert_cos[i] =  -(HWINDOW[i ]*avc + HWINDOW[ri]*avs);
		window_vert_cos[i1++] = HWINDOW[ i]*avs - HWINDOW[ri]*avc;
	}


//    } //  if (color < 3) else
     __syncthreads();// __syncwarp();
#ifdef DEBUG1
    if ((threadIdx.x) == 0){
		printf("COLOR=%d\n",color);
		printf("centerX=%f,    centerY=%f\n",centerX, centerY);
		printf("ktileX=%d,     ktileY=%d\n", ktileX,  ktileY);
		printf("kdx=%f,        kdy=%f\n",    kdx, kdy);
		printf("int_topleft[%d][0]=%d,    int_topleft[%d][1]=%d\n",i,int_topleft[0],i,int_topleft[1]);
		printf("residual_shift[%d][0]=%f, residual_shift[%d][1]=%f\n",i,residual_shift[0],i,residual_shift[1]);
    }
     __syncthreads();// __syncwarp();
#endif



    // prepare, fold and write data to DTT buffers
    int dstride2 = dstride << 1; // in floats (pixels)
    int color0 = color & 1;
    int color1 = (color >>1) & 1;

    for (int gpass = 0; gpass < (color1 + 1); gpass++) { // Only once for R, B, twice - for G
    	int col_tl = int_topleft[0]; //  + (threadIdx.x << 1);
    	int row_tl = int_topleft[1];
    	// for red, blue and green, pass 0
    	int local_col = ((col_tl & 1) ^ (BAYER_RED_COL ^ color0 ^ color1 ^ gpass)) + (threadIdx.x << 1); // green red row: invert column from red
//    	int local_row = ((row_tl & 1) ^ BAYER_RED_ROW ^ gpass);                            // use red row
//    	int local_row = ((row_tl & 1) ^ BAYER_RED_ROW ^ color0 ^ color1 ^ gpass);                            // use red row
    	int local_row = ((row_tl & 1) ^ BAYER_RED_ROW ^ color0          ^ gpass);                            // use red row
    	float hwind_cos = window_hor_cos[local_col];
    	float hwind_sin = window_hor_sin[local_col]; // **** only used for green

    	int dtt_offset =     fold_indx2[local_row][local_col];
    	int dtt_offset_inc = fold_inc[local_row];
#ifdef USE_UMUL24
    	float *dct_buf = clt_tile + __umul24(gpass << 1 , DTT_SIZE * DTT_SIZE1);
    	float *dst_buf = clt_tile + __umul24((gpass << 1) + 1 , DTT_SIZE * DTT_SIZE1);   // **** only used for green
#else
    	float *dct_buf = clt_tile + ((gpass << 1) * (DTT_SIZE * DTT_SIZE1));
    	float *dst_buf = clt_tile + (((gpass << 1) + 1) * (DTT_SIZE * DTT_SIZE1));   // **** only used for green
#endif

    	if ((col_tl >= 0) && ((col_tl < (IMG_WIDTH - DTT_SIZE * 2))) && (row_tl >= 0) && ((row_tl < (IMG_HEIGHT - DTT_SIZE * 2)))) {
#ifdef USE_UMUL24
    		float *image_p = gpu_images + __umul24(row_tl + local_row, dstride)+ col_tl + local_col;
#else
    		float *image_p = gpu_images + dstride * (row_tl + local_row)+ col_tl + local_col;
#endif
#pragma unroll
    		for (int i = 0; i < 8; i++) {
//    			float d = (*image_p) * window_vert_cos[local_row]; //warp illegal address (0,2,1)
    			float d = (*image_p);
    			d *= window_vert_cos[local_row]; //warp illegal address (0,2,1)
    			int dtt_offset1 = dtt_offset + (dtt_offset >> 3); // converting for 9-long rows (DTT_SIZE1)
    			dct_buf[dtt_offset1] = d * hwind_cos;
    			dst_buf[dtt_offset1] = d * hwind_sin; // **** only used for green
    			dtt_offset = ( dtt_offset + ((dtt_offset_inc & 0xf) << 3)) & 0x3f;
    			dtt_offset_inc >>= 4;
    			local_row += 2;
    			image_p += dstride2;
    		}
    	} else { // handling border tiles (slower)
    		int eff_col = (min(IMG_HEIGHT/2 -1, max(0, col_tl >> 1)) << 1) + (col_tl & 1);
    		int row_lsb =  row_tl & 1;
    		int row_pair = row_tl >> 1;
#ifdef USE_UMUL24
    		float *image_p = gpu_images + __umul24(local_row, dstride) + (eff_col + local_col);
#else
    		float *image_p = gpu_images + dstride * local_row+ (eff_col + local_col);
#endif
#pragma unroll
    		for (int i = 0; i < 8; i++) {
    			int eff_row = (min(IMG_WIDTH/2 - 1, max(0, row_pair + i)) << 1) + row_lsb;
#ifdef USE_UMUL24
    			float d =  image_p[__umul24(eff_row,dstride)] * window_vert_cos[local_row];
#else
    			float d =  image_p[dstride * eff_row] * window_vert_cos[local_row];
#endif

    			int dtt_offset1 = dtt_offset + (dtt_offset >> 3); // converting for 9-long rows (DTT_SIZE1)
    			dct_buf[dtt_offset1] = d * hwind_cos;
    			dst_buf[dtt_offset1] = d * hwind_sin; // **** only used for green

    			dtt_offset = ( dtt_offset + ((dtt_offset_inc & 0xf) << 3)) & 0x3f;
    			dtt_offset_inc >>= 4;
    			local_row += 2;
    		}
    	}
    }
     __syncthreads();// __syncwarp();
#ifdef DEBUG2
    if ((threadIdx.x == 0) && (color == BAYER_GREEN)){
        printf("\nFOLDED DTT Tiles Green before reduction\n");
    	debug_print_clt1(clt_tile, color, 0xf); // all quadrants for green only
    }
     __syncthreads();// __syncwarp();
#endif
/*
    if (color == BAYER_GREEN) {
    	// reduce 4 green DTT buffers into 2 (so free future rotated green that were borrowed)
//    	float *dtt_buf =  ((float *) clt_tile[0]) + threadIdx.x;
//    	float *dtt_buf1 = ((float *) clt_tile[2]) + threadIdx.x;
    	float *dtt_buf =  clt_tile + threadIdx.x;
    	float *dtt_buf1 = dtt_buf+ (2 * DTT_SIZE1 * DTT_SIZE); // ((float *) clt_tile[2]) + threadIdx.x;

    	(*dtt_buf) += (*dtt_buf1);
    	dtt_buf +=    (4 * DTT_SIZE1);
    	dtt_buf1 +=   (4 * DTT_SIZE1);
    	(*dtt_buf) += (*dtt_buf1);

    	dtt_buf =         clt_tile + (DTT_SIZE1 * DTT_SIZE) + threadIdx.x; // ((float *) clt_tile[1]) + threadIdx.x;
    	dtt_buf1 =        dtt_buf +  (2 * DTT_SIZE1 * DTT_SIZE);           // ((float *) clt_tile[3]) + threadIdx.x;
    	(*dtt_buf) += (*dtt_buf1);
    	dtt_buf += (4 * DTT_SIZE1);
    	dtt_buf1 += (4 * DTT_SIZE1);
    	(*dtt_buf) += (*dtt_buf1);
    	 __syncthreads();// __syncwarp();
    }
*/
     if (color == BAYER_GREEN) {
    	 // reduce 4 green DTT buffers into 2 (so free future rotated green that were borrowed)
    	 float *dtt_buf =  clt_tile + threadIdx.x;
    	 float *dtt_buf1 = dtt_buf+ (2 * DTT_SIZE1 * DTT_SIZE); // ((float *) clt_tile[2]) + threadIdx.x;
#pragma unroll
    	 for (int i = 0; i < 2*DTT_SIZE; i++) {
    		 (*dtt_buf) += (*dtt_buf1);
    		 dtt_buf +=    DTT_SIZE1;
    		 dtt_buf1 +=   DTT_SIZE1;
    	 }
    	 __syncthreads();// __syncwarp();
     }

#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nFOLDED DTT Tiles,color=%d\n", color);
    	debug_print_clt1(clt_tile, color, (color== BAYER_GREEN)?3:1); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif

    dctiv_nodiverg( // all colors
#ifdef USE_UMUL24
    		clt_tile + __umul24(threadIdx.x,DTT_SIZE1), // [0][threadIdx.x], // pointer to start of row
#else
			clt_tile + (DTT_SIZE1 * threadIdx.x), // [0][threadIdx.x], // pointer to start of row
#endif
			1); //int inc);
    if (color == BAYER_GREEN){
        dstiv_nodiverg( // all colors
#ifdef USE_UMUL24
        		clt_tile + __umul24(threadIdx.x + DTT_SIZE, DTT_SIZE1), // clt_tile[1][threadIdx.x], // pointer to start of row
#else
				clt_tile + DTT_SIZE1 * (threadIdx.x + DTT_SIZE), // clt_tile[1][threadIdx.x], // pointer to start of row
#endif
    			1); //int inc);

    }
  	 __syncthreads();// __syncwarp();

#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after horizontal pass, color=%d\n",color);
    	debug_print_clt1(clt_tile, color, (color== BAYER_GREEN)?3:1); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif
    dctiv_nodiverg( // all colors
    		clt_tile + threadIdx.x, //  &clt_tile[0][0][threadIdx.x], // pointer to start of column
			DTT_SIZE1); // int inc,
    if (color == BAYER_GREEN){
//        dstiv_nodiverg( // all colors
          dctiv_nodiverg( // all colors
        		clt_tile + threadIdx.x + (DTT_SIZE1 * DTT_SIZE), // &clt_tile[1][0][threadIdx.x], // pointer to start of column
    			DTT_SIZE1); // int inc,
    }
  	 __syncthreads();// __syncwarp();

#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after vertical pass (both passes), color = %d\n",color);
    	debug_print_clt1(clt_tile, color, (color== BAYER_GREEN)?3:1); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif

// Replicate DTT, so non-bayer can still use same in-place rotation code
    float *src, *dst;
    int   negate; // , dst_inc;

    // Replicate horizontally (for R and B only):
    if (color != BAYER_GREEN) {
    	negate = 1-(((int_topleft[0] & 1) ^ (BAYER_RED_COL ^ color)) << 1); // +1/-1
    	src = clt_tile + threadIdx.x; // &clt_tile[0][0][threadIdx.x    ];
    	dst = clt_tile + (DTT_SIZE1 * DTT_SIZE) + (threadIdx.x ^ 7); // &clt_tile[1][0][threadIdx.x ^ 7];
#pragma unroll
    	for (int i = 0; i < DTT_SIZE; i++){
    		*dst = negate*(*src);
    		src += DTT_SIZE1;
    		dst += DTT_SIZE1;
    	}
    	 __syncthreads();// __syncwarp();
#ifdef DEBUG2
    	if ((threadIdx.x) == 0){
    		printf("\nDTT Tiles after first replicating, color = %d\n",color);
    		debug_print_clt1(clt_tile, color, 0x3);
    	}
    	 __syncthreads();// __syncwarp();
#endif

    }
    // replicate all colors down diagonal
	negate = 1-(((int_topleft[0] & 1) ^ (int_topleft[1] & 1) ^ (BAYER_RED_COL ^ BAYER_RED_ROW ^ (color >> 1))) << 1); // +1/-1 // 1 -
	// CC -> SS
	src = clt_tile + threadIdx.x; // &clt_tile[0][0][threadIdx.x    ];
	dst = clt_tile + (DTT_SIZE1 * (DTT_SIZE * 3 + 7)) +  (threadIdx.x ^ 7); // &clt_tile[3][7][threadIdx.x ^ 7];
#pragma unroll
    for (int i = 0; i < DTT_SIZE; i++){
    	*dst = negate*(*src);
    	src += DTT_SIZE1;
    	dst -= DTT_SIZE1;
    }
    //SC -> CS
	src = clt_tile + (DTT_SIZE1 * DTT_SIZE) + threadIdx.x; // &clt_tile[1][0][threadIdx.x    ];
	dst = clt_tile + (DTT_SIZE1 * (DTT_SIZE * 2 + 7)) +  (threadIdx.x ^ 7); // &clt_tile[2][7][threadIdx.x    ];
#pragma unroll
    for (int i = 0; i < DTT_SIZE; i++){
    	*dst = negate*(*src);
    	src += DTT_SIZE1;
    	dst -= DTT_SIZE1;
    }
#ifdef DEBUG2
    	if ((threadIdx.x) == 0){
    		printf("\nDTT Tiles after all replicating, color = %d\n",color);
    		debug_print_clt1(clt_tile, color, 0xf);
    	}
    	 __syncthreads();// __syncwarp();
#endif



#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nKernel tiles to convolve, color = %d\n",color);
    	debug_print_clt1(clt_kernels, color, 0xf); // all colors, all quadrants
    }
     __syncthreads();// __syncwarp();
#endif


    // convolve first, then rotate to match Java and make it easier to verify
    convolveTiles(
    		clt_tile,      // float clt_tile   [4][DTT_SIZE][DTT_SIZE1], // 4 quadrants of the clt data, rows extended to optimize shared ports
			clt_kernels); // float kernel     [4][DTT_SIZE][DTT_SIZE1]); // 4 quadrants of the CLT kernel (DTT3 converted)
     __syncthreads();// __syncwarp();
#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after convolution, color = %d\n",color);
    	debug_print_clt1(clt_tile, color, 0xf); // all colors, all quadrants
    }
     __syncthreads();// __syncwarp();
#endif

    // rotate phases: first horizontal, then vertical
    shiftTileHor(
    		clt_tile,           // float clt_tile       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
			residual_shift[0]); // float residual_shift);
     __syncthreads();// __syncwarp();
#ifdef DEBUG2
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after horizontal shift, color = %d\n",color);
    	debug_print_clt1(clt_tile, color,  0xf); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif


    shiftTileVert(
    		clt_tile,           // float clt_tile       [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports
			residual_shift[1]); // float residual_shift);
     __syncthreads();// __syncwarp();
#ifdef DEBUG1
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after vertical shift, color = %d\n",color);
    	debug_print_clt1(clt_tile, color,  0xf); // only 1 quadrant for R,B and 2 - for G
        printf("\nDTT All done\n");
    }
     __syncthreads();// __syncwarp();
#endif


#ifdef DBG_TILE
#ifdef DEBUG3
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after vertical shift, color = %d\n",color);
    	debug_print_clt1(clt_tile, color,  0xf); // only 1 quadrant for R,B and 2 - for G
        printf("\nDTT All done\n");
    }
     __syncthreads();// __syncwarp();
#endif
#endif



     // optionally apply LF
     if ((lpf_mask >> color) & 1){
    	 float * clt = clt_tile + threadIdx.x;
#pragma unroll
    	 for (int q = 0; q < 4; q++) {
    		 float *lpf = lpf_data[color] + threadIdx.x;
    		 //(colors > 1)? color : 3 for mono - not yet implemented
#pragma unroll
    		 for (int i = 0; i <8; i++){
    			 (*clt) *= (*lpf);
    			 clt   += DTT_SIZE1;
    			 lpf   += DTT_SIZE;
    		 }
    	 }
         __syncthreads();// __syncwarp();
#ifdef DBG_TILE
#ifdef DEBUG3
         if ((threadIdx.x) == 0){
        	 printf("\nDTT Tiles after LPF, color = %d\n",color);
        	 debug_print_clt1(clt_tile, color,  0xf); // only 1 quadrant for R,B and 2 - for G
        	 printf("\nDTT All done\n");
         }
     __syncthreads();// __syncwarp();
#endif
#endif
     }
     //	const int         tx = txy & 0xffff; // slow again
     //	const int         ty = txy >> 16;

     int offset_src = threadIdx.x;
//     int offset_dst = ((ty * TILESX + tx)*NUM_COLORS + color)* ( 4 * DTT_SIZE * DTT_SIZE) + threadIdx.x; // gpu_kernels + kernel_full_index* (DTT_SIZE * DTT_SIZE * 4);
//     int offset_dst = ((ty * TILESX + tx)*NUM_COLORS + color)* ( 4 * DTT_SIZE * DTT_SIZE) + threadIdx.x; // gpu_kernels + kernel_full_index* (DTT_SIZE * DTT_SIZE * 4);
#ifdef USE_UMUL24
     int offset_dst = __umul24(    __umul24( __umul24(txy >> 16, TILESX) + (txy & 0xfff)  , NUM_COLORS) + color ,  4 * DTT_SIZE * DTT_SIZE) + threadIdx.x;
#else
     int offset_dst = (((txy >> 16) * TILESX + (txy & 0xfff))*NUM_COLORS + color)* ( 4 * DTT_SIZE * DTT_SIZE) + threadIdx.x;
#endif

     float * clt_src = clt_tile + offset_src; // threadIdx.x;
     float * clt_dst = gpu_clt +  offset_dst; // ((ty * TILESX + tx)*NUM_COLORS + color)* ( 4 * DTT_SIZE * DTT_SIZE1) + threadIdx.x; // gpu_kernels + kernel_full_index* (DTT_SIZE * DTT_SIZE * 4);
//#ifndef NOICLT

#ifdef DBG_TILE
#ifdef DEBUG3
    if ((threadIdx.x) == 0){
        printf("clt_src = 0x%lx\n",clt_src);
        printf("clt_dst = 0x%lx\n",clt_dst);
    }
#endif
#endif



#pragma unroll
    for (int j = 0; j < DTT_SIZE * 4; j++){ // all 4 components, 8 rows
    	// shared memory tiles use DTT_SIZE1
    	*clt_dst =  *clt_src;
    	clt_src   += DTT_SIZE1;
    	clt_dst   += DTT_SIZE;
    }
    __syncthreads();// __syncwarp();
    // just for testing perform imclt, save result to clt_kernels

//#endif
}

#ifdef NOICLT1
extern "C"
__global__ void test_imclt(
		float           * gpu_clt,            // [TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		int             ncam) // just for debug print
// Initially - no output, will add later

{
//	dim3 t = threadIdx;
	int tile_in_block = threadIdx.y;
	int tile_num = blockIdx.x * IMCLT_TILES_PER_BLOCK + tile_in_block;
	if (tile_num >= 1) return; // just testing with a single tile
	int thr3 =    threadIdx.x >> 3;
	int column =  threadIdx.x; // modify to use 2*8 threads, if needed.
//	int thr012 =  threadIdx.x & 7;

	// Read clt tile to
    __shared__ float clt_tiles        [IMCLT_TILES_PER_BLOCK][4][DTT_SIZE][DTT_SIZE1];
    __shared__ float mclt_tiles       [IMCLT_TILES_PER_BLOCK][DTT_SIZE2][DTT_SIZE21];

    // Read clt tile from device memory
    for (int color = 0; color < NUM_COLORS; color++) {
    	float * clt_tile = ((float *) clt_tiles) +  tile_in_block * (4 * DTT_SIZE * DTT_SIZE1); // top left quadrant0
    	float * gpu_tile = ((float *) gpu_clt) +  ((DBG_TILE_Y * TILESX + DBG_TILE_X) * NUM_COLORS + color) * (4 * DTT_SIZE * DTT_SIZE); // top left quadrant0

#ifdef DEBUG3
    	if ((threadIdx.x) == 0){
    		printf("\n\n\n================== gpu_tile = 0x%lx, clt_tile = 0x%lx, COLOR=%d, ncam = %d  ======================\n",gpu_tile,clt_tile,color,ncam);
    	}
#endif
    	clt_tile += column + thr3; // first 2 rows
    	gpu_tile += column;  // first 2 rows
#pragma unroll
    	for (int i = 0; i < DTT_SIZE2; i++){
    		*clt_tile= *gpu_tile;
    		clt_tile += (2 * DTT_SIZE1);
    		gpu_tile += (2 * DTT_SIZE);
    	}
    	// reset mclt tile to zero


    	float * mclt_tile = ((float*) mclt_tiles) +  tile_in_block * (DTT_SIZE2 * DTT_SIZE21) + column;
#pragma unroll
    	for (int i = 0; i < DTT_SIZE2; i++){
    		*mclt_tile= 0.0f;
    		mclt_tile += DTT_SIZE21;
    	}


    	__syncthreads();// __syncwarp();
    	imclt(
    			((float*) clt_tiles) +  tile_in_block * (4 * DTT_SIZE * DTT_SIZE1), // float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
				((float*) mclt_tiles) +  tile_in_block * (DTT_SIZE2 * DTT_SIZE21)); // float * mclt_tile )
    	__syncthreads();// __syncwarp();
    }
}
#endif // NOICLT1

//
// Uses 16 threads, gets 4*8*8 clt tiles, performs idtt-iv (swapping 1 and 2 quadrants) and then unfolds with window,
// adding to the output 16x16 tile (to use Read-modify-write with 4 passes over the frame. Should be zeroed before the
// first pass
//__constant__ int imclt_indx9[16] = {0x28,0x31,0x3a,0x43,0x43,0x3a,0x31,0x28,0x1f,0x16,0x0d,0x04,0x04,0x0d,0x16,0x1f};
__device__ void imclt(
		float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
		float * mclt_tile ) //           [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
{
	int thr3 =    threadIdx.x >> 3;
	int column =  threadIdx.x; // modify to use 2*8 threads, if needed.
	int thr012 =  threadIdx.x & 7;
	int column4 = threadIdx.x >> 2;
//	int wcolumn =column ^ (7 * thr3); //0..7,7,..0
//	int wcolumn = ((thr3 << 3) -1) ^ thr3; //0..7,7,..0
	int wcolumn = ((thr3 << 3) - thr3) ^ thr012; //0..7,7,..0
	float * clt_tile1 = clt_tile +  (DTT_SIZE1 * DTT_SIZE);
	float * clt_tile2 = clt_tile1 + (DTT_SIZE1 * DTT_SIZE);
	float * clt_tile3 = clt_tile2 + (DTT_SIZE1 * DTT_SIZE);
#ifdef DEBUG3
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles before IDTT\n");
    	debug_print_clt1(clt_tile, -1,  0xf); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif

	// perform horizontal dct-iv on quadrants 0 and 1
    dctiv_nodiverg(
//    		clt_tile +  DTT_SIZE1 * (thr012 +   DTT_SIZE * thr3), // pointer to start of row for quadrants 0 and 1
    		clt_tile +  DTT_SIZE1 * (thr012 + 2*DTT_SIZE * thr3), // pointer to start of row for quadrants 0 and 2
			1);
	// perform horizontal dst-iv on quadrants 2 and 3
    dstiv_nodiverg( // all colors
//    		clt_tile2 + DTT_SIZE1 * (thr012 +   DTT_SIZE * thr3), // pointer to start of row for quadrants 2 and 3
    		clt_tile1 + DTT_SIZE1 * (thr012 + 2*DTT_SIZE * thr3), // pointer to start of row for quadrants 1 and 3
			1);
    __syncthreads();// __syncwarp();
	// perform vertical   dct-iv on quadrants 0 and 2
    dctiv_nodiverg(
//    		clt_tile +  thr012 + (DTT_SIZE1 * 2*DTT_SIZE) * thr3, // pointer to start of row for quadrants 0 and 2
    		clt_tile +  thr012 + (DTT_SIZE1 *   DTT_SIZE) * thr3, // pointer to start of row for quadrants 0 and 1
			DTT_SIZE1);
	// perform vertical   dst-iv on quadrants 1 and 3
    dstiv_nodiverg(
//    		clt_tile1 + thr012 + (DTT_SIZE1 * 2*DTT_SIZE) * thr3, // pointer to start of row for quadrants 1 and 3
    		clt_tile2 + thr012 + (DTT_SIZE1 *   DTT_SIZE) * thr3, // pointer to start of row for quadrants 2 and 3
			DTT_SIZE1);
    __syncthreads();// __syncwarp();

#ifdef DEBUG3
    if ((threadIdx.x) == 0){
        printf("\nDTT Tiles after IDTT\n");
    	debug_print_clt1(clt_tile, -1,  0xf); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif


    float hw = HWINDOW2[wcolumn];
    int clt_offset = imclt_indx9[column]; // index in each of the 4 iclt quadrants, accounting for stride=9
    float * rslt = mclt_tile + column;
#pragma unroll
    for (int i = 0; i < 4; i++){
    	float val = *rslt;
    	float w = HWINDOW2[i] * hw;
    	float d0 = idct_signs[0][0][column4] * (*(clt_tile +  clt_offset));
    	float d1 = idct_signs[1][0][column4] * (*(clt_tile1 + clt_offset));
    	float d2 = idct_signs[2][0][column4] * (*(clt_tile2 + clt_offset));
    	float d3 = idct_signs[3][0][column4] * (*(clt_tile3 + clt_offset));
    	d0+=d1;
    	d2+=d3;
    	d0+= d2;
    	if (i < 3){
    		clt_offset +=  DTT_SIZE1;
    	}
//    	*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    	val = __fmaf_rd(w,d0,val); // w*d0 + val
    	*rslt = val;
    	rslt += DTT_SIZE21;
    }
#pragma unroll
    for (int i = 4; i < 8; i++){
    	float val = *rslt;
    	float w = HWINDOW2[i] * hw;
    	float d0 = idct_signs[0][1][column4] * (*(clt_tile +  clt_offset));
    	float d1 = idct_signs[1][1][column4] * (*(clt_tile1 + clt_offset));
    	float d2 = idct_signs[2][1][column4] * (*(clt_tile2 + clt_offset));
    	float d3 = idct_signs[3][1][column4] * (*(clt_tile3 + clt_offset));
    	d0+=d1;
    	d2+=d3;
    	d0+= d2;
//    	if (i < 7){
   		clt_offset -=  DTT_SIZE1;
//    	}
    	*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    	rslt += DTT_SIZE21;
    }
#pragma unroll
    for (int i = 7; i >= 4; i--){
    	float val = *rslt;
    	float w = HWINDOW2[i] * hw;
    	float d0 = idct_signs[0][2][column4] * (*(clt_tile +  clt_offset));
    	float d1 = idct_signs[1][2][column4] * (*(clt_tile1 + clt_offset));
    	float d2 = idct_signs[2][2][column4] * (*(clt_tile2 + clt_offset));
    	float d3 = idct_signs[3][2][column4] * (*(clt_tile3 + clt_offset));
    	d0+=d1;
    	d2+=d3;
    	d0+= d2;
    	if (i > 4){
    		clt_offset -=  DTT_SIZE1;
    	}
    	*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    	rslt += DTT_SIZE21;
    }
#pragma unroll
    for (int i = 3; i >= 0; i--){
    	float val = *rslt;
    	float w = HWINDOW2[i] * hw;
    	float d0 = idct_signs[0][3][column4] * (*(clt_tile +  clt_offset));
    	float d1 = idct_signs[1][3][column4] * (*(clt_tile1 + clt_offset));
    	float d2 = idct_signs[2][3][column4] * (*(clt_tile2 + clt_offset));
    	float d3 = idct_signs[3][3][column4] * (*(clt_tile3 + clt_offset));
    	d0+=d1;
    	d2+=d3;
    	d0+= d2;
    	if (i > 0){
    		clt_offset +=  DTT_SIZE1;
    	}
    	*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    	rslt += DTT_SIZE21;
    }
#ifdef DEBUG3
    __syncthreads();// __syncwarp();
    if ((threadIdx.x) == 0){
        printf("\nMCLT Tiles after IMCLT\n");
    	debug_print_mclt(mclt_tile, -1); // only 1 quadrant for R,B and 2 - for G
    }
    __syncthreads();// __syncwarp();
#endif
}
//#endif




// Uses 8 threads, gets 4*8*8 clt tiles, performs idtt-iv (swapping 1 and 2 quadrants) and then unfolds to the 16x16

// adding to the output 16x16 tile (to use Read-modify-write with 4 passes over the frame. Should be zeroed before the
// first pass
//__constant__ int imclt_indx9[16] = {0x28,0x31,0x3a,0x43,0x43,0x3a,0x31,0x28,0x1f,0x16,0x0d,0x04,0x04,0x0d,0x16,0x1f};

__device__ void imclt8threads(
		int     do_acc,     // 1 - add to previous value, 0 - overwrite
		float * clt_tile,   //        [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports [4][8][9]
		float * mclt_tile,  //           [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		int debug)
{
//	int thr3 =    threadIdx.x >> 3;
//	int column =  threadIdx.x; // modify to use 2*8 threads, if needed.
//	int thr012 =  threadIdx.x & 7;
//	int column4 = threadIdx.x >> 2;
//	int wcolumn = ((thr3 << 3) - thr3) ^ thr012; //0..7,7,..0
	float * clt_tile1 = clt_tile +  (DTT_SIZE1 * DTT_SIZE);
	float * clt_tile2 = clt_tile1 + (DTT_SIZE1 * DTT_SIZE);
	float * clt_tile3 = clt_tile2 + (DTT_SIZE1 * DTT_SIZE);
#ifdef DEBUG7
    if (debug && (threadIdx.x == 0) && (threadIdx.y == 0)){
        printf("\nDTT Tiles before IDTT\n");
        debug_print_clt_scaled(clt_tile, -1,  0xf, 0.25); // only 1 quadrant for R,B and 2 - for G
    }
     __syncthreads();// __syncwarp();
#endif

	// perform horizontal dct-iv on quadrants 0 and 1
    dctiv_nodiverg( // quadrant 0
    		clt_tile +  threadIdx.x,                              // pointer to start of row for quadrant 0
			DTT_SIZE1);
    dctiv_nodiverg( // quadrant 1
    		clt_tile +  threadIdx.x + (1 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 1
			DTT_SIZE1);
	// perform horizontal dst-iv on quadrants 2 and 3
    dstiv_nodiverg( // quadrant 2
    		clt_tile +  threadIdx.x + (2 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 2
			DTT_SIZE1);
    dstiv_nodiverg( // quadrant 3
    		clt_tile +  threadIdx.x + (3 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 3
			DTT_SIZE1);
    __syncthreads();// __syncwarp();
	// perform vertical   dct-iv on quadrants 0 and 2
    dctiv_nodiverg( // quadrant 0
    		clt_tile +  DTT_SIZE1 * threadIdx.x,                              // pointer to start of row for quadrant 0
			1);
    dctiv_nodiverg( // quadrant 2
    		clt_tile +  DTT_SIZE1 * threadIdx.x + (2 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 2
			1);
    // perform vertical   dst-iv on quadrants 1 and 3
    dstiv_nodiverg( // quadrant 1
    		clt_tile +  DTT_SIZE1 * threadIdx.x + (1 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 1
			1);
    dstiv_nodiverg( // quadrant 3
    		clt_tile +  DTT_SIZE1 * threadIdx.x + (3 * DTT_SIZE * DTT_SIZE1), // pointer to start of row for quadrant 3
			1);
    __syncthreads();// __syncwarp();

#ifdef DEBUG7
    if (debug && (threadIdx.x == 0) && (threadIdx.y == 0)){
    	printf("\nDTT Tiles after IDTT\n");
    	debug_print_clt_scaled(clt_tile, -1,  0xf, 0.25); // only 1 quadrant for R,B and 2 - for G
    }
    __syncthreads();// __syncwarp();
#endif
    // re-using 16-thread code (thr3 was bit 3 of threadIdx.x).
    for (int thr3 = 0; thr3 < 2; thr3++){
    	int thr3m = (thr3 << 3);
    	int column =  threadIdx.x + thr3m; // modify to use 2*8 threads, if needed.
    	int thr012 =  threadIdx.x & 7; // == threadIdx.x
    	int column4 = column >> 2; // (threadIdx.x >> 2) | (thr3 << 1) ; // different !
    	int wcolumn = (thr3m - thr3) ^ thr012; //0..7,7,..0

    	float hw = HWINDOW2[wcolumn];
    	int clt_offset = imclt_indx9[column]; // index in each of the 4 iclt quadrants, accounting for stride=9
    	float * rslt = mclt_tile + column;
#ifdef DEBUG7
        if (debug && (threadIdx.x == 0) && (threadIdx.y == 0)){
    	printf("\nUnrolling: thr3=%d, thr3m=%d, column=%d, thr012=%d, column4=%d, wcolumn=%d, hw=%f, clt_offset=%d\n",
    			thr3, thr3m, column, thr012, column4, wcolumn, hw, clt_offset);
    	debug_print_clt1(clt_tile, -1,  0xf); // only 1 quadrant for R,B and 2 - for G
    }
    __syncthreads();// __syncwarp();
#endif

#pragma unroll
    	for (int i = 0; i < 4; i++){
    		float val = *rslt;
    		// facc
    		float w = HWINDOW2[i] * hw;
    		float d0 = idct_signs[0][0][column4] * (*(clt_tile +  clt_offset));
    		float d1 = idct_signs[1][0][column4] * (*(clt_tile1 + clt_offset));
    		float d2 = idct_signs[2][0][column4] * (*(clt_tile2 + clt_offset));
    		float d3 = idct_signs[3][0][column4] * (*(clt_tile3 + clt_offset));
    		d0+=d1;
    		d2+=d3;
    		d0+= d2;
    		if (i < 3){
    			clt_offset +=  DTT_SIZE1;
    		}
    		//    	*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    		// val =__fmaf_rd(w,d0,val); // w*d0 + val
    		// *rslt = val;
    		*rslt = do_acc? __fmaf_rd(w,d0,val) : w * d0; // w*d0 + val do_acc - common for all thereads
    		rslt += DTT_SIZE21;
    	}
#pragma unroll
    	for (int i = 4; i < 8; i++){
    		float val = *rslt;
    		float w = HWINDOW2[i] * hw;
    		float d0 = idct_signs[0][1][column4] * (*(clt_tile +  clt_offset));
    		float d1 = idct_signs[1][1][column4] * (*(clt_tile1 + clt_offset));
    		float d2 = idct_signs[2][1][column4] * (*(clt_tile2 + clt_offset));
    		float d3 = idct_signs[3][1][column4] * (*(clt_tile3 + clt_offset));
    		d0+=d1;
    		d2+=d3;
    		d0+= d2;
    		//    	if (i < 7){
    		clt_offset -=  DTT_SIZE1;
    		//    	}
//    		*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    		*rslt = do_acc? __fmaf_rd(w,d0,val) : w * d0; // w*d0 + val do_acc - common for all thereads

    		rslt += DTT_SIZE21;
    	}
#pragma unroll
    	for (int i = 7; i >= 4; i--){
    		float val = *rslt;
    		float w = HWINDOW2[i] * hw;
    		float d0 = idct_signs[0][2][column4] * (*(clt_tile +  clt_offset));
    		float d1 = idct_signs[1][2][column4] * (*(clt_tile1 + clt_offset));
    		float d2 = idct_signs[2][2][column4] * (*(clt_tile2 + clt_offset));
    		float d3 = idct_signs[3][2][column4] * (*(clt_tile3 + clt_offset));
    		d0+=d1;
    		d2+=d3;
    		d0+= d2;
    		if (i > 4){
    			clt_offset -=  DTT_SIZE1;
    		}
    		//*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    		*rslt = do_acc? __fmaf_rd(w,d0,val) : w * d0; // w*d0 + val do_acc - common for all thereads
    		rslt += DTT_SIZE21;
    	}
#pragma unroll
    	for (int i = 3; i >= 0; i--){
    		float val = *rslt;
    		float w = HWINDOW2[i] * hw;
    		float d0 = idct_signs[0][3][column4] * (*(clt_tile +  clt_offset));
    		float d1 = idct_signs[1][3][column4] * (*(clt_tile1 + clt_offset));
    		float d2 = idct_signs[2][3][column4] * (*(clt_tile2 + clt_offset));
    		float d3 = idct_signs[3][3][column4] * (*(clt_tile3 + clt_offset));
    		d0+=d1;
    		d2+=d3;
    		d0+= d2;
    		if (i > 0){
    			clt_offset +=  DTT_SIZE1;
    		}
    		//*rslt = __fmaf_rd(w,d0,val); // w*d0 + val
    		*rslt = do_acc? __fmaf_rd(w,d0,val) : w * d0; // w*d0 + val do_acc - common for all thereads
    		rslt += DTT_SIZE21;
    	}
    }
#ifdef DEBUG7
    __syncthreads();// __syncwarp();
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if (debug  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			printf("\nMCLT Tiles after IMCLT, cam=%d\n", threadIdx.y);
			debug_print_mclt(
					mclt_tile, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					-1);
		}
		__syncthreads();// __syncwarp();
	}
    __syncthreads();// __syncwarp();
#endif
}

__device__ void debayer_shot(
		const int rb_mode,    // 0 - green, 1 - r/b
		float     min_shot,   // 10.0
		float     scale_shot, // 3.0 (0.0 for mono)
		float   * mclt_src,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float   * mclt_dst,   // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float   * mclt_tmp,
		int       debug)
{
	// unapply squared window
#pragma unroll
	for (int n = 0; n < 2; n++){
		int col = threadIdx.x;
		if (n) col ^= 0xf;
		float wx = HWINDOW_SQi[threadIdx.x];
		float * msp = mclt_src + col;
		float * mtp = mclt_tmp + col;

#pragma unroll
		for (int row = 0; row < DTT_SIZE2; row++){
			int row0 = row;
			if 	(row >= DTT_SIZE) row0 ^= 0xf;
			*mtp = *msp * wx * HWINDOW_SQi[row0];
			mtp += DTT_SIZE21;
			msp += DTT_SIZE21;
		}
	}
	__syncthreads();

#ifdef DEBUG7
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if (debug  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			printf("\ndebayer_shot HWINDOW_SQi applied, camera = %d\n",threadIdx.y);
			debug_print_mclt(
					mclt_tmp, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					-1);
		}
		__syncthreads();// __syncwarp();
	}
	__syncthreads();// __syncwarp();
#endif

	// debayer
	debayer(rb_mode,   // 0 - green, 1 - r/b
			mclt_tmp,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
			mclt_dst,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
			debug);
#ifdef DEBUG7
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if (debug  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			printf("\ndebayer_shot debayer() applied, camera = %d\n",threadIdx.y);
			debug_print_mclt(
					mclt_dst, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					-1);
		}
		__syncthreads();// __syncwarp();
	}
	__syncthreads();// __syncwarp();
#endif


	if (scale_shot > 0.0) {
		float k = rsqrtf(min_shot);

		// double k = 1.0/Math.sqrt(min_shot); //sqrtf
		//for (int i = 0; i < tile.length; i++) tile_db[i] = scale_shot* ((tile_db[i] > min_shot)? Math.sqrt(tile_db[i]) : (k*tile_db[i]));
		float *mcltp = mclt_dst + threadIdx.x;
#pragma unroll
		for (int row = 0; row < DTT_SIZE2; row++){
#pragma unroll
			for (int col = 0; col < DTT_SIZE2; col += DTT_SIZE){
				float d = *mcltp;
				*mcltp = scale_shot * (( d > min_shot)? sqrtf(d) : (k * d));
				mcltp += DTT_SIZE;
			}
			mcltp += (DTT_SIZE21-DTT_SIZE2);
		}
#ifdef DEBUG7
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			if (debug  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
				printf("\ndebayer_shot sqrt applied, camera = %d, scale_shot = %f, min_shot = %f, k= %f\n",threadIdx.y, scale_shot, min_shot, k);
				debug_print_mclt(
						mclt_dst, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
						-1);
			}
			__syncthreads();// __syncwarp();
		}
		__syncthreads();// __syncwarp();
#endif

	}
	// apply squared window back
#pragma unroll
	for (int n = 0; n < 2; n++){
		int col = threadIdx.x;
		if (n) col ^= 0xf;
		float wx = HWINDOW_SQ[threadIdx.x];
		float * mdp = mclt_dst + col;

#pragma unroll
		for (int row = 0; row < DTT_SIZE2; row++){
			int row0 = row;
			if 	(row >= DTT_SIZE) row0 ^= 0xf;
			*mdp *= wx * HWINDOW_SQ[row0];
			mdp += DTT_SIZE21;
		}
	}
	__syncthreads();

#ifdef DEBUG7
	for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
		if (debug  && (threadIdx.x == 0) && (threadIdx.y == ccam)){
			printf("\ndebayer_shot HWINDOW2 applied, camera = %d \n",threadIdx.y);
			debug_print_mclt(
					mclt_dst, //         [4][DTT_SIZE][DTT_SIZE1], // +1 to alternate column ports)
					-1);
		}
		__syncthreads();// __syncwarp();
	}
	__syncthreads();// __syncwarp();
#endif



}

// 8 threads
__device__ void debayer(
		const int rb_mode,   // 0 - green, 1 - r/b
		float * mclt_src,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		float * mclt_dst,  // [2* DTT_SIZE][DTT_SIZE1+ DTT_SIZE], // +1 to alternate column ports[16][17]
		int debug)
{

#pragma unroll
	for (int n = 0; n < 25; n++){
		int row, col;
		if (n < 14) {
			row = (n+1);
			col = 1 + threadIdx.x;
		} else if (n < 21){
			row = 2 * (n-14) + 1 + (threadIdx.x >> 2);
			col = (1 + DTT_SIZE) + (threadIdx.x & 3);
		} else {
			row = 4 * (n - 21) + 1 + (threadIdx.x >> 1);
			col = (1 + DTT_SIZE + DTT_SIZE/2) + (threadIdx.x & 1);
		}
		if (row >= DTT_SIZE2M1) { // 17*15 - last (unused row
			continue;
		}
		int indx = DTT_SIZE21 * row + col;
		float * msp = mclt_src + indx;
		float * mdp = mclt_dst + indx;

		if (rb_mode){ // red and blue, all threads simultaneously
			*mdp = 0.0625 * (*(msp - (DTT_SIZE21 + 1)) + *(msp - (DTT_SIZE21 - 1)) + *(msp + (DTT_SIZE21 - 1)) + *(msp + (DTT_SIZE21 + 1)))+
					 0.125 *(*(msp - DTT_SIZE21) + *(msp + DTT_SIZE21) + *(msp - 1) + *(msp + 1))+
					 0.25 * *msp;
		} else { // green, all threads simultaneously
			*mdp = 0.125 *(*(msp - DTT_SIZE21) + *(msp + DTT_SIZE21) + *(msp - 1) + *(msp + 1))+
					 0.5 * *msp;
		}
	}
	// fill the remaining with non-dbayered
	int offs = threadIdx.x;
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs     += DTT_SIZE;
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs     = (DTT_SIZE21 * DTT_SIZE2M1) + threadIdx.x;
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs     += DTT_SIZE;
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs = threadIdx.x * DTT_SIZE21; // 2 corners will repeat
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs     += DTT_SIZE * DTT_SIZE21;
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs = threadIdx.x * DTT_SIZE21 + DTT_SIZE2M1; // 2 corners will repeat
	*(mclt_dst + offs) = *(mclt_src + offs);
	offs     += DTT_SIZE * DTT_SIZE21;
	*(mclt_dst + offs) = *(mclt_src + offs);
}

//DTT_SIZE21
__device__ void tile_combine_rgba(
		int     colors,        // number of colors
		float * mclt_tile,     // debayer // has gaps to align with union !
		float * rbg_tile,      // if not null - original (not-debayered) rbg tile to use for the output
		float * rgba,          // result
		float * ports_rgb,     // average values of R,G,B for each camera (R0,R1,...,B2,B3) // null
		float * max_diff,      // maximal (weighted) deviation of each channel from the average /null
		float * port_offsets,  // [port]{x_off, y_off} - just to scale pixel value differences
		//		int           port_mask,      // which port to use, 0xf - all 4 (will modify as local variable)
		float   diff_sigma,     // pixel value/pixel change
		float   diff_threshold, // pixel value/pixel change
		// next not used
		//		boolean       diff_gauss,     // when averaging images, use gaussian around average as weight (false - sharp all/nothing)
		float   min_agree,      // minimal number of channels to agree on a point (real number to work with fuzzy averages)
		float * chn_weights,     // color channel weights, sum == 1.0
		int     dust_remove,     // Do not reduce average weight when only one image differes much from the average
		int     keep_weights,   // eturn channel weights and rms after A in RGBA (weight are always calculated, not so for the crms)
		int     debug
)
{
	float * alpha =        rgba + (colors * (DTT_SIZE2*DTT_SIZE21));
	float * port_weights = alpha + (DTT_SIZE2*DTT_SIZE21);
	float * crms =         port_weights + NUM_CAMS*(DTT_SIZE2*DTT_SIZE21); // calculated only if keep_weights
	float  threshold2 = diff_sigma * diff_threshold;
	threshold2 *= threshold2; // squared to compare with diff^2
	float  pair_dist2r [NUM_CAMS*(NUM_CAMS-1)/2]; // new double [ports*(ports-1)/2]; // reversed squared distance between images - to be used with gaussian. Can be calculated once !
	int    pair_ports[NUM_CAMS*(NUM_CAMS-1)/2][2];  // int [][]  pair_ports = new int [ports*(ports-1)/2][2];
	int    indx = 0;
	float  ksigma = 1.0/(2.0*diff_sigma*diff_sigma); // multiply by a weighted sum of squares of the differences
#ifdef DEBUG9
	__shared__ int dbg_bestPort1 [DTT_SIZE2*DTT_SIZE21];
	__shared__ int dbg_bestPort2 [DTT_SIZE2*DTT_SIZE21];
#endif // #ifdef DEBUG9

#pragma unroll
	for (int i = 0; i < NUM_CAMS; i++) { // if ((port_mask & ( 1 << i)) != 0){
#pragma unroll
		for (int j = i+1; j < NUM_CAMS; j++) { //   if ((port_mask & ( 1 << j)) != 0){
			//				double dx = port_offsets[j][0] - port_offsets[i][0];
			//				double dy = port_offsets[j][1] - port_offsets[i][1];
			float dx = *(port_offsets + 2 * j) -     *(port_offsets + 2 * i);
			float dy = *(port_offsets + 2 * j + 1) - *(port_offsets + 2 * i + 1);
			pair_ports[indx][0] = i;
			pair_ports[indx][1] = j;
			pair_dist2r[indx++] = ksigma / (dx*dx+dy*dy); // 2*sigma^2 * r^2
		}
	}
	int colors_offset = colors * MCLT_UNION_LEN; // padded in union !

#ifdef DEBUG8
	__syncthreads();// __syncwarp();
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		printf("\ntile_combine_rgba ksigma = %f\n",ksigma);
		for (int i = 0; i < indx; i++) {
			printf("%02d: %d :%d %f\n",i,pair_ports[i][0], pair_ports[i][1], pair_dist2r[i]);
		}
	}
	__syncthreads();// __syncwarp();
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) { // if ((port_mask & ( 1 << i)) != 0){
			for (int nncol = 0; nncol < colors; nncol++){
				printf("\ntile_combine_rgba cam = %d, color = %d\n",ccam, nncol);
				debug_print_mclt(
						mclt_tile + ((nncol + colors * ccam) * MCLT_UNION_LEN),
						-1);
			}
		}
		printf("\ntile_combine_rgba break 1\n");
	}
	__syncthreads();// __syncwarp();

#endif

	for (int pass = 0; pass < 8; pass ++) {
		// below non-parametrized !
		int row = pass * 2 + (threadIdx.y >> 1);
		int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
		int i = row * DTT_SIZE21 + col;
		float * crms_i = crms+i;
		float * port_weights_i = port_weights + i;
		float * mclt_tile_i = mclt_tile +  i; // has gaps to align in a union !
		float * alpha_i = alpha + i;
		if (keep_weights){
			float sw = 0.0;
			for (int ncol = 0; ncol < colors; ncol ++ ) { //  if (iclt_tile[0][ncol] != null){
				float s0 = 0, s1 = 0, s2 = 0;
				float * crms_col_i = crms_i + (DTT_SIZE2*DTT_SIZE21) * ncol;
				float * mclt_col_i = mclt_tile_i + MCLT_UNION_LEN * ncol;
				for (int cam = 0; cam < NUM_CAMS; cam++) { // if ((port_mask & ( 1 << ip)) != 0){
					s0 += 1.0;
					float d = * (mclt_col_i + colors_offset * cam);
					s1 += d;
					s2 += d * d;
				}
				float mse = (s0*s2 - s1*s1) / (s0 * s0);
				* crms_col_i = sqrtf(mse);
				sw += *(chn_weights +ncol) * mse;
			}
			*(crms_i + (DTT_SIZE2*DTT_SIZE21) * colors) = sqrtf(sw); // will fade as window
		}
#ifdef DEBUG9
	}

#ifdef DEBUG8
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ncol = 0; ncol < colors; ncol++) {
			printf("\n+++++ crms[%d] +++++\n",ncol);
			debug_print_mclt(
					crms + (ncol * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
		printf("\n+++++ cmrs_combo +++++\n");
		debug_print_mclt(
				crms + (colors * (DTT_SIZE2*DTT_SIZE21)), //
				-1);
	}
	__syncthreads();// __syncwarp();
#endif
	__syncthreads();// __syncwarp();
	for (int pass = 0; pass < 8; pass ++) {
		// below non-parametrized !
		int row = pass * 2 + (threadIdx.y >> 1);
		int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
		int i = row * DTT_SIZE21 + col;
		float * crms_i = crms+i;
		float * port_weights_i = port_weights + i;
		float * mclt_tile_i = mclt_tile +  i; // has gaps to align in a union !
		float * alpha_i = alpha + i;
#endif // #ifdef DEBUG9

		for (int cam = 0; cam < NUM_CAMS; cam++) {
			*(port_weights_i + cam*(DTT_SIZE2*DTT_SIZE21)) = 0.0;
		}
		int row_sym = row ^ ((row & 8)? 0xf : 0);
		int col_sym = col ^ ((col & 8)? 0xf : 0);
		float wnd2 = HWINDOW_SQ[row_sym] * HWINDOW_SQ[col_sym];
		float wnd2_inv = 1.0/wnd2;

#pragma unroll
		for (int ipair = 0; ipair < (NUM_CAMS*(NUM_CAMS-1)/2); ipair++){
			float d = 0;
#pragma unroll // non-constant
			for (int ncol = 0; ncol < colors; ncol++) { // if (iclt_tile[0][ncol] != null){
				//					double dc = iclt_tile[pair_ports[ip][0]][ncol][i] - iclt_tile[pair_ports[ip][1]][ncol][i];
				float * mclt_col_i = mclt_tile_i + MCLT_UNION_LEN * ncol;
				float dc =
						*(mclt_col_i + colors_offset * pair_ports[ipair][0]) -
						*(mclt_col_i + colors_offset * pair_ports[ipair][1]);
				dc *= wnd2_inv; // to compensate fading near the edges
				d+= *(chn_weights + ncol) * dc * dc;
			}
			d = expf(-pair_dist2r[ipair] * d) + (FAT_ZERO_WEIGHT); // 0.5 for exact match, lower for mismatch. Add this weight to both ports involved
			// Add weight to both channels in a pair
			*(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * pair_ports[ipair][0]) +=d;
			*(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * pair_ports[ipair][1]) +=d;
		}
		// find 2 best ports (resolving 2 pairs of close values)
		int bestPort1 = 0;
		float best_val= *port_weights_i;
#pragma unroll
		for (int cam = 1; cam < NUM_CAMS; cam++) {
			float val = *(port_weights_i + cam * (DTT_SIZE2*DTT_SIZE21));
			if (val > best_val){
				bestPort1 = cam;
				best_val =  val;
			}
		}
		int bestPort2 = (bestPort1 == 0) ? 1 : 0;
		best_val= *(port_weights_i + bestPort2 * (DTT_SIZE2*DTT_SIZE21));
#pragma unroll  // non-constant
		for (int cam = bestPort2 + 1; cam < NUM_CAMS; cam++){
			float val = *(port_weights_i + cam * (DTT_SIZE2*DTT_SIZE21));
			if ((cam != bestPort1) && (val > best_val)){
				bestPort2 = cam;
				best_val =  val;
			}
		}
#ifdef DEBUG9
		dbg_bestPort1[i] = bestPort1;
		dbg_bestPort2[i] = bestPort2;
#endif // #ifdef DEBUG9

		// find weighted average between these 2 ports
		float pw1 = *(port_weights_i + bestPort1 * (DTT_SIZE2*DTT_SIZE21));
		float w1 = pw1/(pw1 + *(port_weights_i + bestPort2 * (DTT_SIZE2*DTT_SIZE21)));
		float w2 = 1.0 - w1;
		float * rgba_i = rgba + i;
#pragma unroll  // non-constant
		for (int ncol = 0; ncol < colors; ncol++) { // if (iclt_tile[0][ncol] != null) {
			float * mclt_col_i = mclt_tile_i + MCLT_UNION_LEN * ncol;
			* (rgba_i + ncol * (DTT_SIZE2*DTT_SIZE21))=
					w1 *  *(mclt_col_i + colors_offset * bestPort1) +
					w2 *  *(mclt_col_i + colors_offset * bestPort2);
		}


#ifdef DEBUG9
	}

#ifdef DEBUG8
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			printf("\n===== port_weight[%d] ====\n",ccam);
			debug_print_mclt(
					port_weights + (ccam * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
		printf("\n+++++ best ports +++++\n");
		for (int dbg_row = 0; dbg_row < DTT_SIZE2; dbg_row++){
			for (int dbg_col = 0; dbg_col < DTT_SIZE2; dbg_col++){
				printf ("%1d[%1d] ",dbg_bestPort1[dbg_row *DTT_SIZE21 + dbg_col],dbg_bestPort2[dbg_row *DTT_SIZE21 + dbg_col]);
			}
			printf("\n");
		}
		printf("\n");
		for (int ncol = 0; ncol < colors; ncol++) {
			printf("\n+++++ rgba[%d] +++++\n",ncol);
			debug_print_mclt(
					rgba + (ncol * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
	}
	__syncthreads();// __syncwarp();
#endif

	__syncthreads();// __syncwarp();
	for (int pass = 0; pass < 8; pass ++) {
		// below non-parametrized !
		int row = pass * 2 + (threadIdx.y >> 1);
		int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
		int i = row * DTT_SIZE21 + col;
		float * crms_i = crms+i;
		float * port_weights_i = port_weights + i;
		float * mclt_tile_i = mclt_tile +  i; // has gaps to align in a union !
		float * alpha_i = alpha + i;
		float * rgba_i = rgba + i;
		int row_sym = row ^ ((row & 8)? 0xf : 0);
		int col_sym = col ^ ((col & 8)? 0xf : 0);
		float wnd2 = HWINDOW_SQ[row_sym] * HWINDOW_SQ[col_sym];
		float wnd2_inv = 1.0/wnd2;

#endif // #ifdef DEBUG9

		// recalculate all weights using difference from this average of the best pair
#pragma unroll
		for (int cam = 0; cam < NUM_CAMS; cam++) { // if ((port_mask & ( 1 << ip)) != 0){
			float * mclt_cam_i = mclt_tile_i + cam * colors_offset;
			float d2_ip = 0;
#pragma unroll  // non-constant
			for (int ncol = 0; ncol < colors; ncol++) { //  if (iclt_tile[0][ncol] != null){
				float * mclt_cam_col_i = mclt_cam_i + MCLT_UNION_LEN * ncol; // DTT_SIZE2*DTT_SIZE21 * ncol;
				float dc = *(mclt_cam_col_i) - * (rgba_i + ncol * (DTT_SIZE2*DTT_SIZE21));
				dc    *= wnd2_inv; // /= lt_window[i]; // to compensate fading near the edges
				d2_ip += *(chn_weights + ncol) * dc * dc;
			}
			// TODO: Should it use pair_dist2r ? no as it is relative?
			//				port_weights[ip][i] = Math.exp(-ksigma * d2[ip]);
			*(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * cam) = expf(-ksigma * d2_ip) + (FAT_ZERO_WEIGHT);
		}
		// and now make a new average with those weights
		// Inserting dust remove here
		if (dust_remove) {
			int worstPort = 0;
			float worst_val= *port_weights_i;
#pragma unroll
			for (int cam = 1; cam < NUM_CAMS; cam++) {
				float val = *(port_weights_i + cam * (DTT_SIZE2*DTT_SIZE21));
				if (val < worst_val){
					worstPort = cam;
					worst_val = val;
				}
			}
			float avg = -worst_val; // avoid conditional
#pragma unroll
			for (int cam = 0; cam < NUM_CAMS; cam++){
					avg += *(port_weights_i + cam * (DTT_SIZE2*DTT_SIZE21));
			}
			avg /= (NUM_CAMS -1);
			float scale = 1.0 + worst_val * (avg - worst_val)/(avg * avg * (NUM_CAMS-1));
			for (int cam = 0; cam < NUM_CAMS; cam++){
				if (cam != worstPort){
					*(port_weights_i + cam * (DTT_SIZE2*DTT_SIZE21)) *= scale;
				}
			}
			*(port_weights_i + worstPort * (DTT_SIZE2*DTT_SIZE21)) *= worst_val/avg;
		}


#ifdef DEBUG9
	}

#ifdef DEBUG8
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		for (int ccam = 0; ccam < NUM_CAMS; ccam++) {
			printf("\n===== UPDATED port_weight[%d] after dust_remove ====\n",ccam);
			debug_print_mclt(
					port_weights + (ccam * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
	}
	__syncthreads();// __syncwarp();
#endif

	__syncthreads();// __syncwarp();
	for (int pass = 0; pass < 8; pass ++) {
		// below non-parametrized !
		int row = pass * 2 + (threadIdx.y >> 1);
		int col = ((threadIdx.y & 1) << 3) + threadIdx.x;
		int i = row * DTT_SIZE21 + col;
		float * crms_i = crms+i;
		float * port_weights_i = port_weights + i;
		float * mclt_tile_i = mclt_tile +  i; // has gaps to align in a union !
		float * alpha_i = alpha + i;
		float * rgba_i = rgba + i;
		int row_sym = row ^ ((row & 8)? 0xf : 0);
		int col_sym = col ^ ((col & 8)? 0xf : 0);
		float wnd2 = HWINDOW_SQ[row_sym] * HWINDOW_SQ[col_sym];
		float wnd2_inv = 1.0/wnd2;

#endif // #ifdef DEBUG9





		///
		if (rbg_tile) {
			float k = 0.0;
			int rbga_offset = colors * (DTT_SIZE2*DTT_SIZE21); // padded in union !
#pragma unroll
			for (int cam = 0; cam < NUM_CAMS; cam++){
				k += *(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * cam); // port_weights[ip][i];
			}
			k = 1.0/k;
			float * rbg_tile_i = rbg_tile + i;
#pragma unroll  // non-constant
			for (int ncol = 0; ncol < colors; ncol++) { // if (iclt_tile[0][ncol] != null) {
				float * rgba_col_i = rgba_i + ncol * (DTT_SIZE2*DTT_SIZE21);
//				float * mclt_col_i = mclt_tile_i + MCLT_UNION_LEN * ncol;
				float * rbg_col_i = rbg_tile_i + ncol * (DTT_SIZE2*DTT_SIZE21); // different gap between tiles than MCLT_UNION_LEN
				*rgba_col_i = 0.0; // color_avg[ncol][i] = 0;
#pragma unroll
				for (int cam = 0; cam < NUM_CAMS; cam++) {
//					*rgba_col_i += k * *(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * cam) * *(mclt_col_i + cam * colors_offset);
					*rgba_col_i += k * *(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * cam) * *(rbg_col_i +  cam * rbga_offset);
				}
			}
		}
//	int colors_offset = colors * MCLT_UNION_LEN; // padded in union !

		// calculate alpha from channel weights. Start with just a sum of weights?
//		int used_ports = NUM_CAMS;
//		if (dust_remove){
//			used_ports--;
//		}
		float a = 0;

#pragma unroll
		for (int cam = 0; cam < NUM_CAMS; cam++) {
			a +=  *(port_weights_i + (DTT_SIZE2*DTT_SIZE21) * cam);
		}
		*alpha_i = wnd2 * a / NUM_CAMS; // used_ports;
	}// for (int pass = 0; pass < 8; pass ++)
	__syncthreads();

#ifdef DEBUG8
	if (debug  && (threadIdx.x == 0) && (threadIdx.y == 0)){
		printf("\ntile_combine_rgba() final\n");
		for (int ncol = 0; ncol < colors; ncol++) {
			printf("\ntile_combine_rgba() rgba[%d]\n",ncol);
			debug_print_mclt(
					rgba + (ncol * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
		printf("\ntile_combine_rgba() alpha\n");
		debug_print_mclt(
				alpha, //
				-1);
		for (int cam = 0; cam < NUM_CAMS; cam++) {
			printf("\ntile_combine_rgba() port_weights[%d]\n",cam);
			debug_print_mclt(
					port_weights + (cam * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
		for (int ncol = 0; ncol < (colors + 1); ncol++) {
			printf("\ntile_combine_rgba() crms[%d]\n",ncol);
			debug_print_mclt(
					crms + (ncol * (DTT_SIZE2*DTT_SIZE21)),
					-1);
		}
	}
		__syncthreads();// __syncwarp();
#endif



	if (max_diff){
		__shared__ float max_diff_tmp [NUM_CAMS][TEXTURE_THREADS_PER_TILE]; // [4][8]
		int cam = threadIdx.y;
		max_diff_tmp[cam][threadIdx.x] = 0.0;
#pragma unroll
		for (int pass = 0; pass < 32; pass++){
			int row = (pass >> 1);
			int col = ((pass & 1) << 3) + threadIdx.x;
			int i = row * DTT_SIZE21 + col;
			int row_sym = row ^ ((row & 8)? 0xf : 0);
			int col_sym = col ^ ((col & 8)? 0xf : 0);
			float wnd2 = HWINDOW_SQ[row_sym] * HWINDOW_SQi[col_sym];
			float * mclt_cam_i = mclt_tile +  colors_offset * cam + i;
			float d2 = 0.0;
#pragma unroll  // non-constant
			for (int ncol = 0; ncol < colors; ncol++){
				float dc = *(mclt_cam_i + (DTT_SIZE2*DTT_SIZE21) * ncol) - *(rgba + (DTT_SIZE2*DTT_SIZE21) * ncol + i);
				d2 += *(chn_weights + ncol) * dc * dc;
			}
			d2 *= wnd2;
			max_diff_tmp[cam][threadIdx.x] = fmaxf(max_diff_tmp[cam][threadIdx.x], d2);
		}
		__syncthreads();
		if (threadIdx.x == 0){ // combine results
			float mx = 0.0;
#pragma unroll
			for (int i = 0; i < TEXTURE_THREADS_PER_TILE; i++){
				mx = fmaxf(mx, max_diff_tmp[cam][i]);
			}
			max_diff[cam] = sqrtf(mx);
		}
	}

	if (ports_rgb) {
		__shared__ float ports_rgb_tmp [NUM_CAMS][NUM_COLORS][TEXTURE_THREADS_PER_TILE]; // [4*3][8]
		int cam = threadIdx.y;
#pragma unroll  // non-constant
		for (int ncol = 0; ncol < colors; ncol++){
			ports_rgb_tmp[cam][ncol][threadIdx.x] = 0.0;
		}

#pragma unroll
		for (int pass = 0; pass < 32; pass++){
			int row = (pass >> 1);
			int col = ((pass & 1) << 3) + threadIdx.x;
			int i = row * DTT_SIZE21 + col;
//			int row_sym = row ^ ((row & 8)? 0xf : 0);
			float * mclt_cam_i = mclt_tile +  colors_offset * cam + i;
#pragma unroll  // non-constant
			for (int ncol = 0; ncol < colors; ncol++){
				ports_rgb_tmp[cam][ncol][threadIdx.x] += *(mclt_cam_i + (DTT_SIZE2*DTT_SIZE21) * ncol);
			}
		}
		__syncthreads();
		if (threadIdx.x == 0){ // combine results
#pragma unroll  // non-constant
			for (int ncol = 0; ncol < colors; ncol++){
				ports_rgb[ncol * NUM_CAMS + cam] = 0;
#pragma unroll
				for (int i = 0; i < TEXTURE_THREADS_PER_TILE; i++){
					int indx = ncol * NUM_CAMS + cam;
					ports_rgb[indx] += ports_rgb_tmp[cam][ncol][i];
				}
				ports_rgb[indx] /= DTT_SIZE2*DTT_SIZE2; // correct for window?
			}
		}
	}
}



