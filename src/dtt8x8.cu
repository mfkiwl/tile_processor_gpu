/**
 **
 ** dtt8x8.cu - CPU test code to run GPU tile processor
 **
 ** Copyright (C) 2018 Elphel, Inc.
 **
 ** -----------------------------------------------------------------------------**
 **
 **  dtt8x8.cu is free software: you can redistribute it and/or modify
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

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>
#include <helper_cuda.h>
#include <helper_functions.h>



// for reading binary files
#include <fstream>
#include <iterator>
#include <vector>

#include "dtt8x8.cuh"
#include "TileProcessor.cuh"


float * copyalloc_kernel_gpu(float * kernel_host,
		                int size) // size in floats
{
	float *kernel_gpu;
    checkCudaErrors(cudaMalloc((void **)&kernel_gpu, size * sizeof(float)));
    checkCudaErrors(cudaMemcpy( // segfault
    		kernel_gpu,
    		kernel_host,
			size * sizeof(float),
            cudaMemcpyHostToDevice));
    return kernel_gpu;
}
float * alloccopy_from_gpu(
		float * gpu_data,
		float * cpu_data, // if null, will allocate
		int size)
{
	if (!cpu_data) {
		cpu_data = (float *)malloc(size*sizeof(float));
	}
	checkCudaErrors(cudaMemcpy( // segfault
			cpu_data,
			gpu_data,
			size * sizeof(float),
			cudaMemcpyDeviceToHost));

	return cpu_data;
}


float * alloc_kernel_gpu(int size) // size in floats
{
	float *kernel_gpu;
    checkCudaErrors(cudaMalloc((void **)&kernel_gpu, size * sizeof(float)));
    return kernel_gpu;
}


float ** copyalloc_pointers_gpu(float ** gpu_pointer,
		                int size) // number of entries (cameras)
{
	float ** gpu_pointer_to_gpu_pointers;
    checkCudaErrors(cudaMalloc((void **)&gpu_pointer_to_gpu_pointers, size * sizeof(float*)));
    checkCudaErrors(cudaMemcpy(
    		gpu_pointer_to_gpu_pointers,
			gpu_pointer,
			size * sizeof(float*),
            cudaMemcpyHostToDevice));
    return gpu_pointer_to_gpu_pointers;
}


float * copyalloc_image_gpu(float * image_host,
						size_t* dstride, // in bytes!!
		                int width,
						int height)
{
	float *image_gpu;
    checkCudaErrors(cudaMallocPitch((void **)&image_gpu, dstride, width * sizeof(float), height));
    checkCudaErrors(cudaMemcpy2D(
    		image_gpu,
            *dstride, //  * sizeof(float),
			image_host,
			width * sizeof(float), // make in 16*n?
            width * sizeof(float),
			height,
			cudaMemcpyHostToDevice));
    return image_gpu;
}

float * alloc_image_gpu(size_t* dstride, // in bytes!!
		                int width,
						int height)
{
	float *image_gpu;
    checkCudaErrors(cudaMallocPitch((void **)&image_gpu, dstride, width * sizeof(float), height));
    return image_gpu;
}

int readFloatsFromFile(float *       data, // allocated array
					   const char *  path) // file path
{

    std::ifstream input(path, std::ios::binary );
    // copies all data into buffer
    std::vector<char> buffer((
            std::istreambuf_iterator<char>(input)),
            (std::istreambuf_iterator<char>()));
    std::copy( buffer.begin(), buffer.end(), (char *) data);
	return 0;
}
int writeFloatsToFile(float *       data, // allocated array
		               int           size, // length in elements
					   const char *  path) // file path
{

//  std::ifstream input(path, std::ios::binary );
	std::ofstream ofile(path, std::ios::binary);
	ofile.write((char *) data, size * sizeof(float));
	return 0;
}

// Prepare low pass filter (64 long) to be applied to each quadrant of the CLT data
void set_clt_lpf(
		float * lpf,    // size*size array to be filled out
		float   sigma,
		const int     dct_size)
{
	int dct_len = dct_size * dct_size;
	if (sigma == 0.0f) {
		lpf[0] = 1.0f;
		for (int i = 1; i < dct_len; i++){
			lpf[i] = 0.0;
		}
	} else {
		for (int i = 0; i < dct_size; i++){
			for (int j = 0; j < dct_size; j++){
				lpf[i*dct_size+j] = exp(-(i*i+j*j)/(2*sigma));
			}
		}
		// normalize
		double sum = 0;
		for (int i = 0; i < dct_size; i++){
			for (int j = 0; j < dct_size; j++){
				double d = 	lpf[i*dct_size+j];
				d*=cos(M_PI*i/(2*dct_size))*cos(M_PI*j/(2*dct_size));
				if (i > 0) d*= 2.0;
				if (j > 0) d*= 2.0;
				sum +=d;
			}
		}
		for (int i = 0; i< dct_len; i++){
			lpf[i] /= sum;
		}
	}
}



/**
**************************************************************************
*  Program entry point
*
* \param argc       [IN] - Number of command-line arguments
* \param argv       [IN] - Array of command-line arguments
*
* \return Status code
*/


int main(int argc, char **argv)
{
    //
    // Sample initialization
    //
    printf("%s Starting...\n\n", argv[0]);
    printf("sizeof(float*)=%d\n",(int)sizeof(float*));

    //initialize CUDA
    findCudaDevice(argc, (const char **)argv);

    // CLT testing

    const char* kernel_file[] = {
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0_transposed.kernel",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1_transposed.kernel",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2_transposed.kernel",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3_transposed.kernel"};

    const char* kernel_offs_file[] = {
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0_transposed.kernel_offsets",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1_transposed.kernel_offsets",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2_transposed.kernel_offsets",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3_transposed.kernel_offsets"};

    const char* image_files[] = {
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0.bayer",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1.bayer",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2.bayer",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3.bayer"};

    const char* ports_offs_xy_file[] = {
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0.portsxy",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1.portsxy",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2.portsxy",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3.portsxy"};

    const char* ports_clt_file[] = { // never referenced
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0.clt",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1.clt",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2.clt",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3.clt"};
    const char* result_rbg_file[] = {
    		"/data_ssd/git/tile_processor_gpu/clt/main_chn0.rbg",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn1.rbg",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn2.rbg",
			"/data_ssd/git/tile_processor_gpu/clt/main_chn3.rbg"};
    const char* result_corr_file = "/data_ssd/git/tile_processor_gpu/clt/main_corr.corr";
    // not yet used
    float lpf_sigmas[3] = {0.9f, 0.9f, 0.9f}; // G, B, G


/*
#define IMG_WIDTH    2592
#define IMG_HEIGHT   1936
#define NUM_CAMS        4
#define NUM_COLORS      3
#define KERNELS_STEP   16
#define KERNELS_HOR   164
#define KERNELS_VERT  123
#define KERNEL_OFFSETS  8
#define TILESX        324
#define TILESY        242
*/
/*
    struct tp_task {
    	long task;
		short ty;
		short tx;
		float xy[NUM_CAMS][2];
    } ;
*/
    int KERN_TILES = KERNELS_HOR *  KERNELS_VERT * NUM_COLORS;
    int KERN_SIZE =  KERN_TILES * 4 * 64;

    int CORR_SIZE = (2 * DTT_SIZE -1) * (2 * DTT_SIZE -1);

    float            * host_kern_buf =  (float *)malloc(KERN_SIZE * sizeof(float));

    struct tp_task     task_data [TILESX*TILESY]; // maximal length - each tile
    int                corr_indices         [NUM_PAIRS*TILESX*TILESY];

    // host array of pointers to GPU memory
    float            * gpu_kernels_h        [NUM_CAMS];
    struct CltExtra  * gpu_kernel_offsets_h [NUM_CAMS];
    float            * gpu_images_h         [NUM_CAMS];
    float              tile_coords_h        [NUM_CAMS][TILESX * TILESY][2];
    float            * gpu_clt_h            [NUM_CAMS];
    float            * gpu_lpf_h            [NUM_COLORS]; // never used
#ifndef NOICLT
    float            * gpu_corr_images_h    [NUM_CAMS];
#endif

    float            * gpu_corrs;
//    float            * gpu_corr_indices;
    int              * gpu_corr_indices;
    int                num_corrs;
    // GPU pointers to GPU pointers to memory
    float           ** gpu_kernels; //           [NUM_CAMS];
    struct CltExtra ** gpu_kernel_offsets; //    [NUM_CAMS];
    float           ** gpu_images; //            [NUM_CAMS];
    float           ** gpu_clt;    //           [NUM_CAMS];
    float           ** gpu_lpf;    //           [NUM_CAMS]; // never referenced

    // GPU pointers to GPU memory
//    float * gpu_tasks;
    struct tp_task  * gpu_tasks;
    size_t  dstride; // in bytes !
    size_t  dstride_rslt; // in bytes !
    size_t  dstride_corr; // in bytes ! for one 2d phase correlation (padded 15x15x4 bytes)


    float lpf_rbg[3][64];
    for (int ncol = 0; ncol < 3; ncol++) {
    	if (lpf_sigmas[ncol] > 0.0) {
    		set_clt_lpf (
    				lpf_rbg[ncol], // float * lpf,    // size*size array to be filled out
					lpf_sigmas[ncol], // float   sigma,
					8); // int     dct_size)
    		gpu_lpf_h[ncol] = copyalloc_kernel_gpu(lpf_rbg[ncol], 64);
    	} else {
    		gpu_lpf_h[ncol] = NULL;
    	}
    }

    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
        readFloatsFromFile(
        		host_kern_buf, // float * data, // allocated array
				kernel_file[ncam]); // 			   char *  path) // file path
        gpu_kernels_h[ncam] = copyalloc_kernel_gpu(host_kern_buf, KERN_SIZE);

        readFloatsFromFile(
        		host_kern_buf, // float * data, // allocated array
				kernel_offs_file[ncam]); // 			   char *  path) // file path
        gpu_kernel_offsets_h[ncam] = (struct CltExtra *) copyalloc_kernel_gpu(
        		host_kern_buf,
				KERN_TILES * (sizeof( struct CltExtra)/sizeof(float)));
        // will get results back
        gpu_clt_h[ncam] = alloc_kernel_gpu(TILESY * TILESX * NUM_COLORS * 4 * DTT_SIZE * DTT_SIZE);
        printf("Allocating GPU memory, 0x%x floats\n", (TILESY * TILESX * NUM_COLORS * 4 * DTT_SIZE * DTT_SIZE)) ;
        // allocate result images (3x height to accommodate 3 colors

        // Image is extended by 4 pixels each side to avoid checking (mclt tiles extend by 4)
        //host array of pointers to GPU arrays
#ifndef NOICLT
        gpu_corr_images_h[ncam] = alloc_image_gpu(
        		&dstride_rslt,                // size_t* dstride, // in bytes!!
				IMG_WIDTH + DTT_SIZE,         // int width,
				3*(IMG_HEIGHT + DTT_SIZE));   // int height);
#endif
    }
    // allocates one correlation kernel per line (15x15 floats), number of rows - number of tiles * number of pairs
    gpu_corrs = alloc_image_gpu(
    		&dstride_corr,                  // in bytes ! for one 2d phase correlation (padded 15x15x4 bytes)
			CORR_SIZE,                      // int width,
			NUM_PAIRS * TILESX * TILESY);   // int height);
    // read channel images (assuming host_kern_buf size > image size, reusing it)
    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
        readFloatsFromFile(
        		host_kern_buf, // float * data, // allocated array
				image_files[ncam]); // 			   char *  path) // file path
        gpu_images_h[ncam] =  copyalloc_image_gpu(
        		host_kern_buf, // float * image_host,
				&dstride,      // size_t* dstride,
				IMG_WIDTH,     // int width,
				IMG_HEIGHT);   // int height);
    }
//#define DBG_TILE  (174*324 +118)

    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
        readFloatsFromFile(
			    (float *) &tile_coords_h[ncam],
				ports_offs_xy_file[ncam]); // 			   char *  path) // file path
    }

    // build TP task that processes all tiles in linescan order
    for (int ty = 0; ty < TILESY; ty++){
        for (int tx = 0; tx < TILESX; tx++){
            int nt = ty * TILESX + tx;
            task_data[nt].task = 0xf | (((1 << NUM_PAIRS)-1) << TASK_CORR_BITS);
            task_data[nt].txy = tx + (ty << 16);
            for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
                task_data[nt].xy[ncam][0] = tile_coords_h[ncam][nt][0];
                task_data[nt].xy[ncam][1] = tile_coords_h[ncam][nt][1];
            }
        }
    }

    int tp_task_size =  sizeof(task_data)/sizeof(struct tp_task);


#ifdef DBG_TILE
#ifdef DBG0
//#define NUM_TEST_TILES 128
#define NUM_TEST_TILES 1
    for (int t = 0; t < NUM_TEST_TILES; t++) {
    	task_data[t].task = 1;
    	task_data[t].txy = ((DBG_TILE + t) - 324* ((DBG_TILE + t) / 324)) + (((DBG_TILE + t) / 324)) << 16;
    	int nt = task_data[t].ty * TILESX + task_data[t].tx;

    	for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    		task_data[t].xy[ncam][0] = tile_coords_h[ncam][nt][0];
    		task_data[t].xy[ncam][1] = tile_coords_h[ncam][nt][1];
    	}
    }
    tp_task_size =  NUM_TEST_TILES; // sizeof(task_data)/sizeof(float);

#endif
#endif

    // segfault in the next
    gpu_tasks = (struct tp_task  *) copyalloc_kernel_gpu((float * ) &task_data, tp_task_size * (sizeof(struct tp_task)/sizeof(float)));

    // build corr_indices
    num_corrs = 0;
    for (int ty = 0; ty < TILESY; ty++){
    	for (int tx = 0; tx < TILESX; tx++){
    		int nt = ty * TILESX + tx;
    		int cm = (task_data[nt].task >> TASK_CORR_BITS) & ((1 << NUM_PAIRS)-1);
    		if (cm){
    			for (int b = 0; b < NUM_PAIRS; b++) if ((cm & (1 << b)) != 0) {
    				corr_indices[num_corrs++] = (nt << CORR_PAIR_SHIFT) | b;
    			}
    		}
    	}
    }
    // num_corrs now has the total number of correlations
    // copy corr_indices to gpu
//    gpu_corr_indices = (float  *) copyalloc_kernel_gpu((float * ) corr_indices, num_corrs);
    gpu_corr_indices = (int  *) copyalloc_kernel_gpu((float * ) corr_indices, num_corrs);
    // will need to pass num_corrs too


    // Now copy arrays of per-camera pointers to GPU memory to GPU itself

    gpu_kernels =        copyalloc_pointers_gpu (gpu_kernels_h,     NUM_CAMS);
    gpu_kernel_offsets = (struct CltExtra **) copyalloc_pointers_gpu ((float **) gpu_kernel_offsets_h, NUM_CAMS);
    gpu_images =         copyalloc_pointers_gpu (gpu_images_h,      NUM_CAMS);
    gpu_clt =            copyalloc_pointers_gpu (gpu_clt_h,         NUM_CAMS);
//    gpu_corr_images =    copyalloc_pointers_gpu (gpu_corr_images_h, NUM_CAMS);

    //create and start CUDA timer
    StopWatchInterface *timerTP = 0;
    sdkCreateTimer(&timerTP);


    dim3 threads_tp(THREADSX, TILES_PER_BLOCK, 1);
    dim3 grid_tp((tp_task_size + TILES_PER_BLOCK -1 )/TILES_PER_BLOCK, 1);
    printf("threads_tp=(%d, %d, %d)\n",threads_tp.x,threads_tp.y,threads_tp.z);
    printf("grid_tp=   (%d, %d, %d)\n",grid_tp.x,   grid_tp.y,   grid_tp.z);

#ifdef DBG_TILE
    const int numIterations = 1; //0;
    const int i0 =  0; // -1;
#else
    const int numIterations = 10; // 0; //0;
    const int i0 = -1; // 0; // -1;
#endif
    cudaFuncSetCacheConfig(convert_correct_tiles, cudaFuncCachePreferShared);
    float ** fgpu_kernel_offsets = (float **) gpu_kernel_offsets; //    [NUM_CAMS];

    for (int i = i0; i < numIterations; i++)
    {
        if (i == 0)
        {
            checkCudaErrors(cudaDeviceSynchronize());
            sdkResetTimer(&timerTP);
            sdkStartTimer(&timerTP);
        }

        convert_correct_tiles<<<grid_tp,threads_tp>>>(
        		fgpu_kernel_offsets,    // struct CltExtra      ** gpu_kernel_offsets,
				gpu_kernels,           // 		float           ** gpu_kernels,
				gpu_images,            // 		float           ** gpu_images,
				gpu_tasks,             // 		struct tp_task  * gpu_tasks,
				gpu_clt,               //       float           ** gpu_clt,            // [NUM_CAMS][TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
//				gpu_corrs,             // 		float            * gpu_corrs,          // [][15x15] - padded
				dstride/sizeof(float), // 		size_t            dstride, // for gpu_images
//				dstride_corr/sizeof(float), //size_t             dstride_corr,       // in floats: padded correlation size
				tp_task_size,          // 		int               num_tiles) // number of tiles in task
				0); // 7); // 0); // 7);                    //       int               lpf_mask)            // apply lpf to colors : bit 0 - red, bit 1 - blue, bit2 - green


        getLastCudaError("Kernel execution failed");
        checkCudaErrors(cudaDeviceSynchronize());
        printf("%d\n",i);
    }
//    checkCudaErrors(cudaDeviceSynchronize());
    sdkStopTimer(&timerTP);
    float avgTime = (float)sdkGetTimerValue(&timerTP) / (float)numIterations;
    sdkDeleteTimer(&timerTP);
    printf("Run time =%f ms\n",  avgTime);


#ifdef SAVE_CLT
    int rslt_size = (TILESY * TILESX * NUM_COLORS * 4 * DTT_SIZE * DTT_SIZE);
    float * cpu_clt = (float *)malloc(rslt_size*sizeof(float));
    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    	checkCudaErrors(cudaMemcpy( // segfault
    			cpu_clt,
				gpu_clt_h[ncam],
				rslt_size * sizeof(float),
    			cudaMemcpyDeviceToHost));
#ifndef DBG_TILE
        printf("Writing CLT data to %s\n",  ports_clt_file[ncam]);
    	writeFloatsToFile(cpu_clt, // float *       data, // allocated array
    			rslt_size, // int           size, // length in elements
				ports_clt_file[ncam]); // 			   const char *  path) // file path
#endif
    }
#endif

#ifdef TEST_IMCLT
     {
    	// testing imclt
    	dim3 threads_imclt(IMCLT_THREADS_PER_TILE, IMCLT_TILES_PER_BLOCK, 1);
    	dim3 grid_imclt(1,1,1);
    	printf("threads_imclt=(%d, %d, %d)\n",threads_imclt.x,threads_imclt.y,threads_imclt.z);
    	printf("grid_imclt=   (%d, %d, %d)\n",grid_imclt.x,   grid_imclt.y,   grid_imclt.z);
    	for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    		test_imclt<<<grid_imclt,threads_imclt>>>(
    				gpu_clt_h[ncam], // ncam]); //                //       float           ** gpu_clt,            // [NUM_CAMS][TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
					ncam);                                        // int             ncam); // just for debug print
    	}
    	getLastCudaError("Kernel execution failed");
    	checkCudaErrors(cudaDeviceSynchronize());
    	printf("test_imclt() DONE\n");
    }
#endif


#ifndef NOICLT
    // testing imclt
    dim3 threads_imclt(IMCLT_THREADS_PER_TILE, IMCLT_TILES_PER_BLOCK, 1);
    printf("threads_imclt=(%d, %d, %d)\n",threads_imclt.x,threads_imclt.y,threads_imclt.z);
    StopWatchInterface *timerIMCLT = 0;
    sdkCreateTimer(&timerIMCLT);

    for (int i = i0; i < numIterations; i++)
    {
    	if (i == 0)
    	{
    		checkCudaErrors(cudaDeviceSynchronize());
    		sdkResetTimer(&timerIMCLT);
    		sdkStartTimer(&timerIMCLT);
    	}

    	for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    		for (int color = 0; color < NUM_COLORS; color++) {
#ifdef IMCLT14
    			for (int v_offs = 0; v_offs < 1; v_offs++){     // temporarily for debugging
    				for (int h_offs = 0; h_offs < 1; h_offs++){ // temporarily for debugging
#else
    	    			for (int v_offs = 0; v_offs < 2; v_offs++){
    	    				for (int h_offs = 0; h_offs < 2; h_offs++){
#endif
    					int tilesy_half = (TILESY + (v_offs ^ 1)) >> 1;
    					int tilesx_half = (TILESX + (h_offs ^ 1)) >> 1;
    					int tiles_in_pass = tilesy_half * tilesx_half;
    					dim3 grid_imclt((tiles_in_pass + IMCLT_TILES_PER_BLOCK-1) / IMCLT_TILES_PER_BLOCK,1,1);
    					//    				printf("grid_imclt=   (%d, %d, %d)\n",grid_imclt.x,   grid_imclt.y,   grid_imclt.z);
    					imclt_rbg<<<grid_imclt,threads_imclt>>>(
    							gpu_clt_h[ncam], // float           * gpu_clt,            // [TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
								gpu_corr_images_h[ncam], // float           * gpu_rbg,            // WIDTH, 3 * HEIGHT
								color, // int               color,
								v_offs, // int               v_offset,
								h_offs, // int               h_offset,
								dstride_rslt/sizeof(float));            //const size_t      dstride);            // in floats (pixels)
    				}
    			}
    		}
#ifdef DEBUG4
    		break;
#endif
#ifdef DEBUG5
    		break;
#endif

    	}
    	getLastCudaError("Kernel failure");
    	checkCudaErrors(cudaDeviceSynchronize());
    	printf("test pass: %d\n",i);
#ifdef DEBUG4
    	break;
#endif
#ifdef DEBUG5
    		break;
#endif

    }

    sdkStopTimer(&timerIMCLT);
    float avgTimeIMCLT = (float)sdkGetTimerValue(&timerIMCLT) / (float)numIterations;
    sdkDeleteTimer(&timerIMCLT);
    printf("Average IMCLT run time =%f ms\n",  avgTimeIMCLT);

    int rslt_img_size =       NUM_COLORS * (IMG_HEIGHT + DTT_SIZE) * (IMG_WIDTH + DTT_SIZE);
    float * cpu_corr_image = (float *)malloc(rslt_img_size * sizeof(float));



    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    	checkCudaErrors(cudaMemcpy2D( // segfault
    			cpu_corr_image,
				(IMG_WIDTH + DTT_SIZE) * sizeof(float),
				gpu_corr_images_h[ncam],
				dstride_rslt,
				(IMG_WIDTH + DTT_SIZE) * sizeof(float),
				3* (IMG_HEIGHT + DTT_SIZE),
    			cudaMemcpyDeviceToHost));

#ifndef DBG_TILE
        printf("Writing RBG data to %s\n",  result_rbg_file[ncam]);
    	writeFloatsToFile( // will have margins
    			cpu_corr_image, // float *       data, // allocated array
				rslt_img_size, // int           size, // length in elements
				result_rbg_file[ncam]); // 			   const char *  path) // file path
#endif
    }

    free(cpu_corr_image);
#endif




#ifndef NOCORR
    // testing corr
    dim3 threads_corr(CORR_THREADS_PER_TILE, CORR_TILES_PER_BLOCK, 1);
    printf("threads_corr=(%d, %d, %d)\n",threads_corr.x,threads_corr.y,threads_corr.z);
    StopWatchInterface *timerCORR = 0;
    sdkCreateTimer(&timerCORR);

    for (int i = i0; i < numIterations; i++)
    {
    	if (i == 0)
    	{
    		checkCudaErrors(cudaDeviceSynchronize());
    		sdkResetTimer(&timerCORR);
    		sdkStartTimer(&timerCORR);
    	}

        dim3 grid_corr((num_corrs + CORR_TILES_PER_BLOCK-1) / CORR_TILES_PER_BLOCK,1,1);
        correlate2D<<<grid_corr,threads_corr>>>(
		gpu_clt,   // float          ** gpu_clt,            // [NUM_CAMS] ->[TILESY][TILESX][NUM_COLORS][DTT_SIZE*DTT_SIZE]
		3,         // int               colors,             // number of colors (3/1)
		0.25,      // float             scale0,             // scale for R
		0.25,      // float             scale1,             // scale for B
		0.5,       // float             scale2,             // scale for G
		30.0,      // float             fat_zero,           // here - absolute
		num_corrs, // size_t            num_corr_tiles,     // number of correlation tiles to process
		gpu_corr_indices, //  int             * gpu_corr_indices,   // packed tile+pair
		dstride_corr/sizeof(float), // const size_t      corr_stride,        // in floats
		gpu_corrs); // float           * gpu_corrs);          // correlation output data
    	getLastCudaError("Kernel failure");
    	checkCudaErrors(cudaDeviceSynchronize());
    	printf("test pass: %d\n",i);
#ifdef DEBUG4
    	break;
#endif
#ifdef DEBUG5
    		break;
#endif
    }

    sdkStopTimer(&timerCORR);
    float avgTimeCORR = (float)sdkGetTimerValue(&timerCORR) / (float)numIterations;
    sdkDeleteTimer(&timerCORR);
    printf("Average CORR run time =%f ms\n",  avgTimeCORR);

    int corr_size =        2 * CORR_OUT_RAD + 1;
    int rslt_corr_size =   num_corrs * corr_size * corr_size;
    float * cpu_corr = (float *)malloc(rslt_corr_size * sizeof(float));



    checkCudaErrors(cudaMemcpy2D(
    		cpu_corr,
			(corr_size * corr_size) * sizeof(float),
			gpu_corrs,
			dstride_corr,
			(corr_size * corr_size) * sizeof(float),
			num_corrs,
    		cudaMemcpyDeviceToHost));

#ifndef NSAVE_CORR
    		printf("Writing phase correlation data to %s\n",  result_corr_file);
    		writeFloatsToFile(
    				cpu_corr,    // float *       data, // allocated array
					rslt_corr_size,    // int           size, // length in elements
					result_corr_file); // 			   const char *  path) // file path
#endif
    		free(cpu_corr);
#endif // ifndef NOCORR




#ifdef SAVE_CLT
    free(cpu_clt);
#endif

    free (host_kern_buf);
    // TODO: move somewhere when all is done
    for (int ncam = 0; ncam < NUM_CAMS; ncam++) {
    	checkCudaErrors(cudaFree(gpu_kernels_h[ncam]));
    	checkCudaErrors(cudaFree(gpu_kernel_offsets_h[ncam]));
    	checkCudaErrors(cudaFree(gpu_images_h[ncam]));
    	checkCudaErrors(cudaFree(gpu_clt_h[ncam]));
#ifndef NOICLT
    	checkCudaErrors(cudaFree(gpu_corr_images_h[ncam]));
#endif
    }
	checkCudaErrors(cudaFree(gpu_tasks));
	checkCudaErrors(cudaFree(gpu_kernels));
	checkCudaErrors(cudaFree(gpu_kernel_offsets));
	checkCudaErrors(cudaFree(gpu_images));
	checkCudaErrors(cudaFree(gpu_clt));
//	checkCudaErrors(cudaFree(gpu_corr_images));
	checkCudaErrors(cudaFree(gpu_corrs));
	checkCudaErrors(cudaFree(gpu_corr_indices));
	exit(0);
}
