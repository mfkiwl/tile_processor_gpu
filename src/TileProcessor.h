/**
 **
 ** TileProcessor.h
 **
 ** Copyright (C) 2020 Elphel, Inc.
 **
 ** -----------------------------------------------------------------------------**
 **
 **  TileProcessor.h is free software: you can redistribute it and/or modify
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
* \file TileProcessor.h
* \brief header file for  the Tile Processor for frequency domain

*/
#pragma once
#ifndef NUM_CAMS
#include "tp_defines.h"
#endif


extern "C"
__global__ void convert_correct_tiles(
		float           ** gpu_kernel_offsets, // [NUM_CAMS],
		float           ** gpu_kernels,        // [NUM_CAMS],
		float           ** gpu_images,         // [NUM_CAMS],
		struct tp_task   * gpu_tasks,
		float           ** gpu_clt,            // [NUM_CAMS][TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		size_t             dstride,            // in floats (pixels)
		int                num_tiles,          // number of tiles in task
		int                lpf_mask);          // apply lpf to colors : bit 0 - red, bit 1 - blue, bit2 - green. Now - always 0 !

extern "C" __global__ void clear_texture_list(
		int              * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		int                width,  // <= TILESX, use for faster processing of LWIR images
		int                height); // <= TILESY, use for faster processing of LWIR images

extern "C" __global__ void mark_texture_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,            // number of tiles in task list
		int              * gpu_texture_indices); // packed tile + bits (now only (1 << 7)
extern "C" __global__ void mark_texture_neighbor_tiles(
		struct tp_task   * gpu_tasks,
		int                num_tiles,           // number of tiles in task list
		int              * gpu_texture_indices, // packed tile + bits (now only (1 << 7)
		int              * woi);                // x,y,width,height of the woi
extern "C" __global__ void gen_texture_list(
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
		int             * woi,                // x, y, width,height
		float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		size_t            num_texture_tiles,  // number of texture tiles to process
		int             * gpu_texture_indices,// packed tile + bits (now only (1 << 7)
		// TODO: use geometry_correction rXY !
		float           * gpu_port_offsets,   // relative ports x,y offsets - just to scale differences, may be approximate
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

extern "C" __global__ void imclt_rbg(
		float           * gpu_clt,            // [TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		float           * gpu_rbg,            // WIDTH, 3 * HEIGHT
		int               apply_lpf,
		int               mono,               // defines lpf filter
		int               color,              // defines location of clt data
		int               v_offset,
		int               h_offset,
		const size_t      dstride);            // in floats (pixels)

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
			// TODO: use geometry_correction rXY !
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
			float           * gpu_texture_tiles);  // (number of colors +1 + ?)*16*16 rgba texture tiles


